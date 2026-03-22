/// Repository SavingGoal — mengelola operasi data target tabungan.
/// Strategi: Online-first, fallback ke lokal.
/// Kontribusi mengurangi saldo pocket dan menambah current_amount goal.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/saving_goal_model.dart';
import '../local/database_helper.dart';
import '../services/supabase_service.dart';
import '../../config/constants/app_constants.dart';

class SavingGoalRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  // =========================================================
  // BACA DATA
  // =========================================================

  /// Ambil semua saving goals milik user.
  Future<List<SavingGoal>> get_goals() async {
    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        return await _fetch_from_remote();
      }
      return await _fetch_from_local();
    } catch (e) {
      debugPrint('[SavingGoalRepo] get_goals error: $e');
      return await _fetch_from_local();
    }
  }

  // =========================================================
  // TAMBAH DATA
  // =========================================================

  /// Buat saving goal baru.
  Future<SavingGoal> create_goal({
    required String name,
    required int target_amount,
    String currency = 'IDR',
    DateTime? deadline,
    String icon = 'savings',
    String color = '#FF7043',
    String? image_url,
  }) async {
    final user_id = SupabaseService.current_user_id;
    final now = DateTime.now();

    final goal = SavingGoal(
      id: _uuid.v4(),
      user_id: user_id,
      name: name,
      target_amount: target_amount,
      currency: currency,
      deadline: deadline,
      icon: icon,
      color: color,
      image_url: image_url,
      created_at: now,
      updated_at: now,
    );

    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        await SupabaseService.from(AppConstants.tableSavingGoals)
            .insert(goal.to_supabase());
        await _db.insert(AppConstants.tableSavingGoals, goal.to_local());
        debugPrint('[SavingGoalRepo] Goal created: ${goal.name}');
        return goal;
      }

      // Offline
      final pending = goal.copy_with(sync_status: 'pending');
      await _db.insert(AppConstants.tableSavingGoals, pending.to_local());
      return pending;
    } catch (e) {
      debugPrint('[SavingGoalRepo] create_goal error: $e');
      try {
        final pending = goal.copy_with(sync_status: 'pending');
        await _db.insert(AppConstants.tableSavingGoals, pending.to_local());
        return pending;
      } catch (local_error) {
        debugPrint('[SavingGoalRepo] local fallback failed: $local_error');
        rethrow;
      }
    }
  }

  // =========================================================
  // UPDATE DATA
  // =========================================================

  /// Update saving goal (nama, target, deadline, dll).
  Future<SavingGoal> update_goal(SavingGoal goal) async {
    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        await SupabaseService.from(AppConstants.tableSavingGoals)
            .update(goal.to_supabase())
            .eq('id', goal.id);
      }

      await _db.insert(AppConstants.tableSavingGoals, goal.to_local());
      debugPrint('[SavingGoalRepo] Goal updated: ${goal.name}');
      return goal;
    } catch (e) {
      debugPrint('[SavingGoalRepo] update_goal error: $e');
      rethrow;
    }
  }

  // =========================================================
  // HAPUS DATA
  // =========================================================

  /// Hapus saving goal beserta kontribusinya.
  Future<void> delete_goal(String goal_id) async {
    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        await SupabaseService.from(AppConstants.tableSavingGoals)
            .delete()
            .eq('id', goal_id);
      }

      // Hapus kontribusi lokal terkait
      await _db.delete(
        AppConstants.tableSavingContributions,
        where: 'goal_id = ?',
        where_args: [goal_id],
      );
      // Hapus goal lokal
      await _db.delete(
        AppConstants.tableSavingGoals,
        where: 'id = ?',
        where_args: [goal_id],
      );
    } catch (e) {
      debugPrint('[SavingGoalRepo] delete_goal error: $e');
      rethrow;
    }
  }

  // =========================================================
  // KONTRIBUSI
  // =========================================================

  /// Tambahkan kontribusi ke saving goal.
  /// Mengurangi saldo pocket dan menambah current_amount goal.
  Future<void> add_contribution({
    required String goal_id,
    required String pocket_id,
    required int amount,
    String? note,
  }) async {
    final user_id = SupabaseService.current_user_id;
    final contribution_id = _uuid.v4();
    final now = DateTime.now();

    final contribution_data = {
      'id': contribution_id,
      'user_id': user_id,
      'goal_id': goal_id,
      'pocket_id': pocket_id,
      'amount': amount,
      'note': note,
      'created_at': now.toIso8601String(),
    };

    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        // Insert kontribusi ke Supabase
        await SupabaseService.from(AppConstants.tableSavingContributions)
            .insert(contribution_data);

        // Update goal current_amount di Supabase
        final goal_response = await SupabaseService.from(AppConstants.tableSavingGoals)
            .select('current_amount, target_amount')
            .eq('id', goal_id)
            .single();

        final new_amount = (goal_response['current_amount'] as num).toInt() + amount;
        final target = (goal_response['target_amount'] as num).toInt();
        final is_done = new_amount >= target;

        await SupabaseService.from(AppConstants.tableSavingGoals)
            .update({
              'current_amount': new_amount,
              'is_completed': is_done,
              'updated_at': now.toIso8601String(),
            })
            .eq('id', goal_id);

        // Kurangi saldo pocket di Supabase
        final pocket_response = await SupabaseService.from(AppConstants.tablePockets)
            .select('balance')
            .eq('id', pocket_id)
            .single();

        final new_balance = (pocket_response['balance'] as num).toInt() - amount;
        await SupabaseService.from(AppConstants.tablePockets)
            .update({'balance': new_balance})
            .eq('id', pocket_id);
      }

      // Simpan kontribusi ke lokal
      contribution_data['sync_status'] = is_online ? 'synced' : 'pending';
      await _db.insert(AppConstants.tableSavingContributions, contribution_data);

      // Update goal lokal
      final local_goals = await _db.query(
        AppConstants.tableSavingGoals,
        where: 'id = ?',
        where_args: [goal_id],
      );
      if (local_goals.isNotEmpty) {
        final current = local_goals.first['current_amount'] as int;
        final target = local_goals.first['target_amount'] as int;
        final new_amount = current + amount;

        await _db.update(
          AppConstants.tableSavingGoals,
          {
            'current_amount': new_amount,
            'is_completed': new_amount >= target ? 1 : 0,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          where_args: [goal_id],
        );
      }

      // Update pocket balance lokal
      final local_pockets = await _db.query(
        AppConstants.tablePockets,
        where: 'id = ?',
        where_args: [pocket_id],
      );
      if (local_pockets.isNotEmpty) {
        final current_balance = local_pockets.first['balance'] as int;
        await _db.update(
          AppConstants.tablePockets,
          {
            'balance': current_balance - amount,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          where_args: [pocket_id],
        );
      }

      debugPrint('[SavingGoalRepo] Contribution added: $amount to goal $goal_id');
    } catch (e) {
      debugPrint('[SavingGoalRepo] add_contribution error: $e');
      rethrow;
    }
  }

  // =========================================================
  // SYNC HELPERS
  // =========================================================

  /// Ambil goals dari Supabase.
  Future<List<SavingGoal>> _fetch_from_remote() async {
    final user_id = SupabaseService.current_user_id;

    final response = await SupabaseService.from(AppConstants.tableSavingGoals)
        .select()
        .eq('user_id', user_id)
        .order('created_at', ascending: false);

    final goals = (response as List)
        .map((json) => SavingGoal.from_supabase(json as Map<String, dynamic>))
        .toList();

    // Cache ke lokal
    for (final goal in goals) {
      await _db.insert(AppConstants.tableSavingGoals, goal.to_local());
    }

    return goals;
  }

  /// Ambil goals dari SQLite lokal.
  Future<List<SavingGoal>> _fetch_from_local() async {
    try {
      final user_id = SupabaseService.current_user_id;
      final rows = await _db.query(
        AppConstants.tableSavingGoals,
        where: 'user_id = ?',
        where_args: [user_id],
        order_by: 'created_at DESC',
      );
      return rows.map((row) => SavingGoal.from_local(row)).toList();
    } catch (e) {
      debugPrint('[SavingGoalRepo] _fetch_from_local error: $e');
      return [];
    }
  }

  /// Cek koneksi internet.
  Future<bool> _check_connectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      return !connectivity.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }
}
