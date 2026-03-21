/// Root MaterialApp dengan konfigurasi tema dan routing.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/main_screen.dart';

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme_provider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme_provider.theme_mode,
      // Auth Gate: Otomatis redirect berdasarkan status login
      home: const AuthGate(),
    );
  }
}

/// Auth Gate — menentukan halaman awal berdasarkan status login.
/// Jika sudah login → MainScreen
/// Jika belum login → LoginScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth_provider, _) {
        // Tampilkan splash/loading saat cek session
        if (auth_provider.is_loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika sudah login, tampilkan halaman utama
        if (auth_provider.is_logged_in) {
          return const MainScreen();
        }

        // Jika belum login, tampilkan halaman login
        return const LoginScreen();
      },
    );
  }
}
