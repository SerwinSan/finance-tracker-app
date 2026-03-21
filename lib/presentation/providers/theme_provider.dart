/// Provider untuk mengelola tema (Dark/Light mode).
/// Menyimpan preferensi tema di SharedPreferences secara lokal.
library;

import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Default: Light mode
  ThemeMode _theme_mode = ThemeMode.light;

  ThemeMode get theme_mode => _theme_mode;

  bool get is_dark_mode => _theme_mode == ThemeMode.dark;

  /// Toggle antara dark dan light mode.
  void toggle_theme() {
    _theme_mode =
        _theme_mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Set tema secara spesifik.
  void set_theme(ThemeMode mode) {
    _theme_mode = mode;
    notifyListeners();
  }
}
