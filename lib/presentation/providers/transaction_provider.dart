/// Provider Transaction — mengelola state transaksi dan kategori.
/// Memuat data dari repository dan menyimpan state lokal.
library;

import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _tx_repo = TransactionRepository();
  final CategoryRepository _cat_repo = CategoryRepository();

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _is_loading = false;
  String? _error_message;

  // === Getters ===
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  bool get is_loading => _is_loading;
  String? get error_message => _error_message;

  /// Kategori filtered by type.
  List<Category> get income_categories =>
      _categories.where((c) => c.type == 'income').toList();
  List<Category> get expense_categories =>
      _categories.where((c) => c.type == 'expense').toList();

  // =========================================================
  // LOAD DATA
  // =========================================================

  /// Load transaksi. Bisa filter per pocket.
  Future<void> load_transactions({String? pocket_id}) async {
    try {
      _set_loading(true);
      _clear_error();
      _transactions = await _tx_repo.get_transactions(pocket_id: pocket_id);
      notifyListeners();
    } catch (e) {
      _set_error('Gagal memuat transaksi. Coba lagi.');
    } finally {
      _set_loading(false);
    }
  }

  /// Load semua kategori.
  Future<void> load_categories() async {
    try {
      _categories = await _cat_repo.get_all_categories();
      notifyListeners();
    } catch (e) {
      debugPrint('[TransactionProvider] load_categories error: $e');
    }
  }

  // =========================================================
  // OPERASI DATA
  // =========================================================

  /// Buat transaksi baru.
  Future<bool> create_transaction({
    required String pocket_id,
    required String? category_id,
    required int amount,
    required String type,
    String currency = 'IDR',
    String? description,
    String? label,
    DateTime? transaction_date,
  }) async {
    try {
      _set_loading(true);
      _clear_error();

      final tx = await _tx_repo.create_transaction(
        pocket_id: pocket_id,
        category_id: category_id,
        amount: amount,
        type: type,
        currency: currency,
        description: description,
        label: label,
        transaction_date: transaction_date,
      );

      // Tambahkan ke list lokal di awal (terbaru di atas)
      _transactions.insert(0, tx);
      notifyListeners();
      return true;
    } catch (e) {
      _set_error('Gagal menyimpan transaksi. Coba lagi.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  /// Hapus transaksi.
  Future<bool> delete_transaction(Transaction tx) async {
    try {
      _set_loading(true);
      _clear_error();

      await _tx_repo.delete_transaction(tx);
      _transactions.removeWhere((t) => t.id == tx.id);
      notifyListeners();
      return true;
    } catch (e) {
      _set_error('Gagal menghapus transaksi. Coba lagi.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  // === Helpers ===
  void _set_loading(bool value) {
    _is_loading = value;
    notifyListeners();
  }

  void _set_error(String message) {
    _error_message = message;
    notifyListeners();
  }

  void _clear_error() {
    _error_message = null;
  }
}
