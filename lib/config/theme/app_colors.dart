/// Palet warna aplikasi Finance Tracker.
/// Terinspirasi dari GoPay — menggunakan Teal sebagai primary.
/// Tidak menggunakan warna ungu atau indigo.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Primary (Teal) ===
  static const Color primary = Color(0xFF00897B);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark = Color(0xFF00695C);

  // === Secondary (Blue) ===
  static const Color secondary = Color(0xFF1E88E5);
  static const Color secondaryLight = Color(0xFF64B5F6);

  // === Feedback Colors ===
  static const Color income = Color(0xFF43A047);
  static const Color incomeDark = Color(0xFF66BB6A);
  static const Color expense = Color(0xFFE53935);
  static const Color expenseDark = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);

  // === Light Mode ===
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color dividerLight = Color(0xFFE0E0E0);

  // === Dark Mode ===
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);
  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color dividerDark = Color(0xFF373737);
}
