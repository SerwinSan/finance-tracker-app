/// Auth Provider — mengelola state autentikasi.
/// Menggunakan Supabase Auth untuk login, register, dan session management.
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _is_loading = false;
  String? _error_message;
  User? _user;

  // === Getters ===
  bool get is_loading => _is_loading;
  String? get error_message => _error_message;
  User? get user => _user;
  bool get is_logged_in => _user != null;

  AuthProvider() {
    // Cek session saat provider pertama kali dibuat
    _check_current_session();

    // Dengarkan perubahan auth state (login/logout/token refresh)
    SupabaseService.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  /// Cek apakah ada session aktif (auto-login).
  void _check_current_session() {
    _user = SupabaseService.auth.currentUser;
    notifyListeners();
  }

  /// Login dengan email dan password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _set_loading(true);
      _clear_error();

      final response = await SupabaseService.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      _user = response.user;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _set_error(_translate_auth_error(e.message));
      return false;
    } catch (e) {
      _set_error('Terjadi kesalahan. Coba lagi nanti.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  /// Register akun baru dengan email, password, dan nama.
  Future<bool> register({
    required String email,
    required String password,
    required String full_name,
  }) async {
    try {
      _set_loading(true);
      _clear_error();

      final response = await SupabaseService.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': full_name.trim()},
      );

      _user = response.user;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _set_error(_translate_auth_error(e.message));
      return false;
    } catch (e) {
      _set_error('Terjadi kesalahan saat registrasi. Coba lagi nanti.');
      return false;
    } finally {
      _set_loading(false);
    }
  }

  /// Logout — membersihkan session.
  Future<void> logout() async {
    try {
      _set_loading(true);
      await SupabaseService.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _set_error('Gagal logout. Coba lagi.');
    } finally {
      _set_loading(false);
    }
  }

  /// Mendapatkan nama user dari metadata.
  String get display_name {
    final meta = _user?.userMetadata;
    if (meta != null && meta['full_name'] != null) {
      return meta['full_name'] as String;
    }
    return _user?.email?.split('@').first ?? 'User';
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

  /// Terjemahkan error Supabase Auth ke Bahasa Indonesia.
  String _translate_auth_error(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Email atau password salah';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox kamu.';
    }
    if (lower.contains('user already registered')) {
      return 'Email sudah terdaftar. Silakan login.';
    }
    if (lower.contains('password should be at least')) {
      return 'Password terlalu pendek. Minimal 8 karakter.';
    }
    if (lower.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }
    if (lower.contains('network')) {
      return 'Tidak ada koneksi internet.';
    }
    return 'Terjadi kesalahan: $message';
  }
}
