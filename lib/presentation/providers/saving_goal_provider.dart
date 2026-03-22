/// Provider SavingGoal — mengelola state target tabungan.
/// CRUD goals + kontribusi dari pocket.
library;

import 'package:flutter/material.dart';
import '../../data/models/saving_goal_model.dart';
import '../../data/repositories/saving_goal_repository.dart';

class SavingGoalProvider extends ChangeNotifier {
  final SavingGoalRepository _repo = SavingGoalRepository();

  List<SavingGoal> _goals = [];
  bool _is_loading = false;
  String? _error_message;

  // === Getters ===
  List<SavingGoal> get goals => _goals;
  List<SavingGoal> get active_goals => _goals.where((g) => !g.is_completed).toList();
  List<SavingGoal> get completed_goals => _goals.where((g) => g.is_completed).toList();
  bool get is_loading => _is_loading;
  String? get error_message => _error_message;

  /// Load semua saving goals.
  Future<void> load_goals() async {
    try {
      _set_loading(true);
      _clear_error();
      _goals = await _repo.get_goals();
      notifyListeners();
    } catch (e) {
      _set_error('Gagal memuat target tabungan.');
    } finally {
      _set_loading(false);
    }
  }

  /// Buat saving goal baru.
  Future<bool> create_goal({
    required String name,
    required int target_amount,
    String currency = 'IDR',
    DateTime? deadline,
    String icon = 'savings',
    String color = '#FF7043',
  }) async {
    try {
      _set_loading(true);
      _clear_error();

      final goal = await _repo.create_goal(
        name: name,
        target_amount: target_amount,
        currency: currency,
        deadline: deadline,
        icon: icon,
        color: color,
      );

      _goals.insert(0, goal);
      notifyListeners();
      return true;
    } catch (e) {
      _set_error('Gagal membuat target tabungan.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  /// Update saving goal.
  Future<bool> update_goal(SavingGoal goal) async {
    try {
      _set_loading(true);
      _clear_error();

      final updated = await _repo.update_goal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) _goals[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _set_error('Gagal mengupdate target tabungan.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  /// Hapus saving goal.
  Future<bool> delete_goal(String goal_id) async {
    try {
      _set_loading(true);
      _clear_error();

      await _repo.delete_goal(goal_id);
      _goals.removeWhere((g) => g.id == goal_id);
      notifyListeners();
      return true;
    } catch (e) {
      _set_error('Gagal menghapus target tabungan.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  /// Kontribusi ke goal dari pocket tertentu.
  Future<bool> contribute({
    required String goal_id,
    required String pocket_id,
    required int amount,
    String? note,
  }) async {
    try {
      _set_loading(true);
      _clear_error();

      await _repo.add_contribution(
        goal_id: goal_id,
        pocket_id: pocket_id,
        amount: amount,
        note: note,
      );

      // Reload goals untuk update current_amount
      await load_goals();
      return true;
    } catch (e) {
      _set_error('Gagal menambah kontribusi.');
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
