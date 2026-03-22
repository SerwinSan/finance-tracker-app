/// Repository Transaction — mengelola operasi data transaksi.
/// Strategi sync: Online-first, fallback ke lokal jika offline.
/// Transaksi juga otomatis update saldo pocket terkait.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../local/database_helper.dart';
import '../services/supabase_service.dart';
import '../../config/constants/app_constants.dart';

class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  // =========================================================
  // BACA DATA
  // =========================================================

  /// Ambil transaksi milik user, terbaru di atas.
  /// Bisa filter berdasarkan pocket_id.
  Future<List<Transaction>> get_transactions({
    String? pocket_id,
    int limit = 50,
  }) async {
    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        return await _fetch_from_remote(pocket_id: pocket_id, limit: limit);
      }
      return await _fetch_from_local(pocket_id: pocket_id, limit: limit);
    } catch (e) {
      debugPrint('[TransactionRepo] get_transactions error: $e');
      return await _fetch_from_local(pocket_id: pocket_id, limit: limit);
    }
  }

  // =========================================================
  // TAMBAH DATA
  // =========================================================

  /// Buat transaksi baru + update saldo pocket.
  Future<Transaction> create_transaction({
    required String pocket_id,
    required String? category_id,
    required int amount,
    required String type,
    String currency = 'IDR',
    String? description,
    String? label,
    DateTime? transaction_date,
  }) async {
    final user_id = SupabaseService.current_user_id;
    final now = DateTime.now();

    final transaction = Transaction(
      id: _uuid.v4(),
      user_id: user_id,
      pocket_id: pocket_id,
      category_id: category_id,
      amount: amount,
      currency: currency,
      type: type,
      description: description,
      label: label,
      transaction_date: transaction_date ?? now,
      created_at: now,
      updated_at: now,
    );

    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        // Insert transaksi ke Supabase
        await SupabaseService.from(AppConstants.tableTransactions)
            .insert(transaction.to_supabase());

        // Update saldo pocket di Supabase
        await _update_pocket_balance_remote(pocket_id, amount, type);

        // Simpan ke lokal
        await _db.insert(AppConstants.tableTransactions, transaction.to_local());
        await _update_pocket_balance_local(pocket_id, amount, type);

        debugPrint('[TransactionRepo] Transaction created: ${transaction.type} $amount');
        return transaction;
      }

      // Offline: simpan sebagai pending
      final pending = transaction.copy_with(sync_status: 'pending');
      await _db.insert(AppConstants.tableTransactions, pending.to_local());
      await _update_pocket_balance_local(pocket_id, amount, type);
      return pending;
    } catch (e) {
      debugPrint('[TransactionRepo] create_transaction error: $e');
      // Fallback: simpan lokal
      try {
        final pending = transaction.copy_with(sync_status: 'pending');
        await _db.insert(AppConstants.tableTransactions, pending.to_local());
        await _update_pocket_balance_local(pocket_id, amount, type);
        return pending;
      } catch (local_error) {
        debugPrint('[TransactionRepo] local fallback failed: $local_error');
        rethrow;
      }
    }
  }

  // =========================================================
  // HAPUS DATA
  // =========================================================

  /// Hapus transaksi + rollback saldo pocket.
  Future<void> delete_transaction(Transaction transaction) async {
    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        await SupabaseService.from(AppConstants.tableTransactions)
            .delete()
            .eq('id', transaction.id);

        // Rollback saldo: kebalikan dari create
        final reverse_type = transaction.is_income ? 'expense' : 'income';
        await _update_pocket_balance_remote(
          transaction.pocket_id,
          transaction.amount,
          reverse_type,
        );
      }

      // Hapus lokal + rollback saldo lokal
      await _db.delete(
        AppConstants.tableTransactions,
        where: 'id = ?',
        where_args: [transaction.id],
      );
      final reverse_type = transaction.is_income ? 'expense' : 'income';
      await _update_pocket_balance_local(
        transaction.pocket_id,
        transaction.amount,
        reverse_type,
      );
    } catch (e) {
      debugPrint('[TransactionRepo] delete_transaction error: $e');
      rethrow;
    }
  }

  // =========================================================
  // SALDO HELPERS
  // =========================================================

  /// Update saldo pocket di Supabase via RPC atau manual.
  Future<void> _update_pocket_balance_remote(
    String pocket_id,
    int amount,
    String type,
  ) async {
    // Ambil saldo saat ini
    final response = await SupabaseService.from(AppConstants.tablePockets)
        .select('balance')
        .eq('id', pocket_id)
        .single();

    final current_balance = (response['balance'] as num).toInt();
    final new_balance = type == 'income'
        ? current_balance + amount
        : current_balance - amount;

    await SupabaseService.from(AppConstants.tablePockets)
        .update({'balance': new_balance})
        .eq('id', pocket_id);
  }

  /// Update saldo pocket di SQLite lokal.
  Future<void> _update_pocket_balance_local(
    String pocket_id,
    int amount,
    String type,
  ) async {
    final rows = await _db.query(
      AppConstants.tablePockets,
      where: 'id = ?',
      where_args: [pocket_id],
    );

    if (rows.isNotEmpty) {
      final current_balance = rows.first['balance'] as int;
      final new_balance = type == 'income'
          ? current_balance + amount
          : current_balance - amount;

      await _db.update(
        AppConstants.tablePockets,
        {'balance': new_balance, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        where_args: [pocket_id],
      );
    }
  }

  // =========================================================
  // SYNC HELPERS
  // =========================================================

  /// Ambil data dari Supabase (dengan join ke categories).
  Future<List<Transaction>> _fetch_from_remote({
    String? pocket_id,
    int limit = 50,
  }) async {
    final user_id = SupabaseService.current_user_id;

    var query = SupabaseService.from(AppConstants.tableTransactions)
        .select('*, categories(name, icon, color)')
        .eq('user_id', user_id)
        .order('transaction_date', ascending: false)
        .limit(limit);

    if (pocket_id != null) {
      query = SupabaseService.from(AppConstants.tableTransactions)
          .select('*, categories(name, icon, color)')
          .eq('user_id', user_id)
          .eq('pocket_id', pocket_id)
          .order('transaction_date', ascending: false)
          .limit(limit);
    }

    final response = await query;

    final transactions = (response as List)
        .map((json) => Transaction.from_supabase(json as Map<String, dynamic>))
        .toList();

    // Cache ke lokal
    for (final tx in transactions) {
      await _db.insert(AppConstants.tableTransactions, tx.to_local());
    }

    return transactions;
  }

  /// Ambil data dari SQLite lokal.
  Future<List<Transaction>> _fetch_from_local({
    String? pocket_id,
    int limit = 50,
  }) async {
    try {
      final user_id = SupabaseService.current_user_id;

      String where_clause = 'user_id = ?';
      List<dynamic> args = [user_id];

      if (pocket_id != null) {
        where_clause += ' AND pocket_id = ?';
        args.add(pocket_id);
      }

      final rows = await _db.query(
        AppConstants.tableTransactions,
        where: where_clause,
        where_args: args,
        order_by: 'transaction_date DESC',
        limit: limit,
      );
      return rows.map((row) => Transaction.from_local(row)).toList();
    } catch (e) {
      debugPrint('[TransactionRepo] _fetch_from_local error: $e');
      return [];
    }
  }

  /// Cek koneksi internet
  Future<bool> _check_connectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      return !connectivity.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }
}
