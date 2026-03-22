/// Repository Pocket — mengelola operasi data pocket.
/// Strategi sync: Online-first, fallback ke lokal jika offline.
/// Data selalu disimpan di lokal (SQLite) sebagai cache.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/pocket_model.dart';
import '../local/database_helper.dart';
import '../services/supabase_service.dart';
import '../../config/constants/app_constants.dart';

class PocketRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  // =========================================================
  // BACA DATA
  // =========================================================

  /// Ambil semua pocket milik user.
  /// Online: ambil dari Supabase → simpan ke lokal.
  /// Offline: ambil dari SQLite.
  Future<List<Pocket>> get_all_pockets() async {
    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        return await _fetch_from_remote();
      }
      return await _fetch_from_local();
    } catch (e) {
      debugPrint('[PocketRepo] get_all_pockets error: $e');
      // Jika gagal ambil dari remote, fallback ke lokal
      return await _fetch_from_local();
    }
  }

  /// Ambil satu pocket berdasarkan ID.
  Future<Pocket?> get_pocket_by_id(String id) async {
    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        final response = await SupabaseService.from(AppConstants.tablePockets)
            .select()
            .eq('id', id)
            .single();
        return Pocket.from_supabase(response);
      }

      return await _get_local_pocket(id);
    } catch (e) {
      debugPrint('[PocketRepo] get_pocket_by_id error: $e');
      return await _get_local_pocket(id);
    }
  }

  // =========================================================
  // TAMBAH DATA
  // =========================================================

  /// Buat pocket baru.
  /// Online: simpan ke Supabase + lokal.
  /// Offline: simpan ke lokal dengan status 'pending'.
  Future<Pocket> create_pocket({
    required String name,
    required String type,
    String currency = 'IDR',
    String color = '#00897B',
    String icon = 'wallet',
  }) async {
    final user_id = SupabaseService.current_user_id;
    final now = DateTime.now();

    final pocket = Pocket(
      id: _uuid.v4(),
      user_id: user_id,
      name: name,
      type: type,
      balance: 0,
      currency: currency,
      color: color,
      icon: icon,
      created_at: now,
      updated_at: now,
    );

    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        // Simpan ke Supabase — tanpa id agar Supabase generate uuid sendiri
        // Kita kirim dengan id karena kita generate sendiri via uuid
        final supabase_data = pocket.to_supabase();
        debugPrint('[PocketRepo] Inserting to Supabase: $supabase_data');

        await SupabaseService.from(AppConstants.tablePockets)
            .insert(supabase_data);

        // Simpan ke lokal dengan status 'synced'
        await _db.insert(AppConstants.tablePockets, pocket.to_local());
        debugPrint('[PocketRepo] Pocket created successfully: ${pocket.name}');
        return pocket;
      }

      // Offline: simpan ke lokal dengan status 'pending'
      final pending_pocket = pocket.copy_with(sync_status: 'pending');
      await _db.insert(AppConstants.tablePockets, pending_pocket.to_local());
      return pending_pocket;
    } catch (e) {
      debugPrint('[PocketRepo] create_pocket error: $e');
      // Jika gagal sync, simpan sebagai pending
      try {
        final pending_pocket = pocket.copy_with(sync_status: 'pending');
        await _db.insert(AppConstants.tablePockets, pending_pocket.to_local());
        return pending_pocket;
      } catch (local_error) {
        debugPrint('[PocketRepo] local insert also failed: $local_error');
        // Re-throw agar provider bisa menampilkan error
        rethrow;
      }
    }
  }

  // =========================================================
  // UPDATE DATA
  // =========================================================

  /// Update pocket yang sudah ada.
  Future<Pocket> update_pocket(Pocket pocket) async {
    final updated = pocket.copy_with();

    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        await SupabaseService.from(AppConstants.tablePockets)
            .update(updated.to_supabase())
            .eq('id', updated.id);

        await _db.update(
          AppConstants.tablePockets,
          updated.copy_with(sync_status: 'synced').to_local(),
          where: 'id = ?',
          where_args: [updated.id],
        );
        return updated.copy_with(sync_status: 'synced');
      }

      // Offline: tandai sebagai pending
      final pending = updated.copy_with(sync_status: 'pending');
      await _db.update(
        AppConstants.tablePockets,
        pending.to_local(),
        where: 'id = ?',
        where_args: [pending.id],
      );
      return pending;
    } catch (e) {
      debugPrint('[PocketRepo] update_pocket error: $e');
      final pending = updated.copy_with(sync_status: 'pending');
      await _db.update(
        AppConstants.tablePockets,
        pending.to_local(),
        where: 'id = ?',
        where_args: [pending.id],
      );
      return pending;
    }
  }

  // =========================================================
  // HAPUS DATA
  // =========================================================

  /// Hapus pocket berdasarkan ID.
  Future<void> delete_pocket(String id) async {
    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        await SupabaseService.from(AppConstants.tablePockets)
            .delete()
            .eq('id', id);
      }

      await _db.delete(
        AppConstants.tablePockets,
        where: 'id = ?',
        where_args: [id],
      );
    } catch (e) {
      debugPrint('[PocketRepo] delete_pocket error: $e');
      // Jika gagal hapus di remote, tetap hapus di lokal
      await _db.delete(
        AppConstants.tablePockets,
        where: 'id = ?',
        where_args: [id],
      );
    }
  }

  // =========================================================
  // SYNC HELPERS
  // =========================================================

  /// Cek koneksi internet.
  Future<bool> _check_connectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      return !connectivity.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Ambil pocket dari SQLite lokal by ID.
  Future<Pocket?> _get_local_pocket(String id) async {
    final rows = await _db.query(
      AppConstants.tablePockets,
      where: 'id = ?',
      where_args: [id],
    );
    if (rows.isNotEmpty) return Pocket.from_local(rows.first);
    return null;
  }

  /// Ambil data dari Supabase dan simpan ke lokal.
  Future<List<Pocket>> _fetch_from_remote() async {
    final user_id = SupabaseService.current_user_id;

    final response = await SupabaseService.from(AppConstants.tablePockets)
        .select()
        .eq('user_id', user_id)
        .order('created_at', ascending: true);

    final pockets = (response as List)
        .map((json) => Pocket.from_supabase(json as Map<String, dynamic>))
        .toList();

    // Simpan semua ke lokal (INSERT OR REPLACE karena mungkin data sudah ada)
    for (final pocket in pockets) {
      await _db.insert(AppConstants.tablePockets, {
        ...pocket.to_local(),
        'sync_status': 'synced',
        'last_synced_at': DateTime.now().toIso8601String(),
      });
    }

    return pockets;
  }

  /// Ambil data dari SQLite lokal.
  Future<List<Pocket>> _fetch_from_local() async {
    try {
      final user_id = SupabaseService.current_user_id;
      final rows = await _db.query(
        AppConstants.tablePockets,
        where: 'user_id = ?',
        where_args: [user_id],
        order_by: 'created_at ASC',
      );
      return rows.map((row) => Pocket.from_local(row)).toList();
    } catch (e) {
      debugPrint('[PocketRepo] _fetch_from_local error: $e');
      return [];
    }
  }

  /// Sinkronisasi data pending ke Supabase.
  /// Dipanggil ketika koneksi kembali online.
  Future<void> sync_pending_data() async {
    final user_id = SupabaseService.current_user_id;
    final pending_rows = await _db.query(
      AppConstants.tablePockets,
      where: 'user_id = ? AND sync_status = ?',
      where_args: [user_id, 'pending'],
    );

    for (final row in pending_rows) {
      final pocket = Pocket.from_local(row);
      try {
        await SupabaseService.from(AppConstants.tablePockets)
            .upsert(pocket.to_supabase());

        await _db.update(
          AppConstants.tablePockets,
          {
            'sync_status': 'synced',
            'last_synced_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          where_args: [pocket.id],
        );
      } catch (_) {
        // Tetap pending, akan dicoba lagi nanti
      }
    }
  }
}
