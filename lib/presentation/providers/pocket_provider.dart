/// Provider Pocket — mengelola state daftar pocket/dompet virtual.
/// Menggunakan PocketRepository untuk operasi data.
library;

import 'package:flutter/material.dart';
import '../../data/models/pocket_model.dart';
import '../../data/repositories/pocket_repository.dart';

class PocketProvider extends ChangeNotifier {
  final PocketRepository _repository = PocketRepository();

  List<Pocket> _pockets = [];
  bool _is_loading = false;
  String? _error_message;

  // === Getters ===
  List<Pocket> get pockets => _pockets;
  bool get is_loading => _is_loading;
  String? get error_message => _error_message;

  /// Hitung total saldo semua pocket (dikelompokkan per currency).
  Map<String, int> get total_balance_by_currency {
    final totals = <String, int>{};
    for (final pocket in _pockets) {
      totals[pocket.currency] = (totals[pocket.currency] ?? 0) + pocket.balance;
    }
    return totals;
  }

  /// Filter pocket: hanya tipe personal.
  List<Pocket> get personal_pockets =>
      _pockets.where((p) => p.is_personal).toList();

  /// Filter pocket: hanya tipe titipan.
  List<Pocket> get entrusted_pockets =>
      _pockets.where((p) => p.is_entrusted).toList();

  // =========================================================
  // OPERASI DATA
  // =========================================================

  /// Load semua pocket dari repository.
  Future<void> load_pockets() async {
    try {
      _set_loading(true);
      _clear_error();
      _pockets = await _repository.get_all_pockets();
      notifyListeners();
    } catch (e) {
      _set_error('Gagal memuat dompet. Coba lagi.');
    } finally {
      _set_loading(false);
    }
  }

  /// Buat pocket baru.
  Future<bool> create_pocket({
    required String name,
    required String type,
    String currency = 'IDR',
    String color = '#00897B',
    String icon = 'wallet',
  }) async {
    try {
      _set_loading(true);
      _clear_error();

      final pocket = await _repository.create_pocket(
        name: name,
        type: type,
        currency: currency,
        color: color,
        icon: icon,
      );

      _pockets.add(pocket);
      notifyListeners();
      return true;
    } catch (e) {
      _set_error('Gagal membuat dompet. Coba lagi.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  /// Update pocket yang sudah ada.
  Future<bool> update_pocket(Pocket pocket) async {
    try {
      _set_loading(true);
      _clear_error();

      final updated = await _repository.update_pocket(pocket);

      // Ganti di list lokal
      final index = _pockets.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        _pockets[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _set_error('Gagal mengupdate dompet. Coba lagi.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  /// Hapus pocket.
  Future<bool> delete_pocket(String id) async {
    try {
      _set_loading(true);
      _clear_error();

      await _repository.delete_pocket(id);
      _pockets.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _set_error('Gagal menghapus dompet. Coba lagi.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  /// Update saldo pocket secara lokal (setelah transaksi).
  void update_pocket_balance(String pocket_id, int new_balance) {
    final index = _pockets.indexWhere((p) => p.id == pocket_id);
    if (index != -1) {
      _pockets[index] = _pockets[index].copy_with(balance: new_balance);
      notifyListeners();
    }
  }

  /// Sync data pending (dipanggil saat koneksi kembali online).
  Future<void> sync_pending() async {
    try {
      await _repository.sync_pending_data();
      await load_pockets(); // Refresh data setelah sync
    } catch (_) {
      // Gagal sync, abaikan — akan dicoba lagi nanti
    }
  }

  // === Private Helpers ===
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
