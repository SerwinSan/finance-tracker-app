/// Halaman Login — desain terinspirasi dari GoPay.
/// Menggunakan bahasa semi-formal yang friendly.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form_key = GlobalKey<FormState>();
  final _email_controller = TextEditingController();
  final _password_controller = TextEditingController();
  bool _obscure_password = true;

  @override
  void dispose() {
    _email_controller.dispose();
    _password_controller.dispose();
    super.dispose();
  }

  /// Proses login
  Future<void> _handle_login() async {
    // Validasi form terlebih dahulu (Guard Clause)
    if (!_form_key.currentState!.validate()) return;

    final auth_provider = context.read<AuthProvider>();
    final success = await auth_provider.login(
      email: _email_controller.text,
      password: _password_controller.text,
    );

    // Jika gagal, tampilkan error snackbar
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth_provider.error_message ?? 'Login gagal'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    // Jika berhasil, AuthGate akan otomatis redirect ke MainScreen
  }

  /// Navigasi ke halaman register
  void _go_to_register() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth_provider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _form_key,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // === Logo / Ikon ===
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  // === Judul ===
                  Text(
                    'Selamat Datang! 👋',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk ke akunmu untuk mulai kelola keuangan',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // === Input Email ===
                  TextFormField(
                    controller: _email_controller,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validate_email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'contoh@email.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === Input Password ===
                  TextFormField(
                    controller: _password_controller,
                    obscureText: _obscure_password,
                    textInputAction: TextInputAction.done,
                    validator: Validators.validate_password,
                    onFieldSubmitted: (_) => _handle_login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure_password
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure_password = !_obscure_password;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // === Tombol Login ===
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth_provider.is_loading ? null : _handle_login,
                      child: auth_provider.is_loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Masuk'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // === Link ke Register ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: _go_to_register,
                        child: Text(
                          'Daftar di sini',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
