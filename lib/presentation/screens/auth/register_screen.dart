/// Halaman Register — form pendaftaran akun baru.
/// Desain konsisten dengan LoginScreen (GoPay-inspired).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../utils/validators.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form_key = GlobalKey<FormState>();
  final _name_controller = TextEditingController();
  final _email_controller = TextEditingController();
  final _password_controller = TextEditingController();
  final _confirm_password_controller = TextEditingController();
  bool _obscure_password = true;
  bool _obscure_confirm = true;

  @override
  void dispose() {
    _name_controller.dispose();
    _email_controller.dispose();
    _password_controller.dispose();
    _confirm_password_controller.dispose();
    super.dispose();
  }

  /// Proses registrasi
  Future<void> _handle_register() async {
    // Validasi form (Guard Clause)
    if (!_form_key.currentState!.validate()) return;

    final auth_provider = context.read<AuthProvider>();
    final success = await auth_provider.register(
      email: _email_controller.text,
      password: _password_controller.text,
      full_name: _name_controller.text,
    );

    if (mounted) {
      if (success) {
        // Registrasi berhasil — kembali ke login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Akun berhasil dibuat! 🎉'),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // AuthGate akan otomatis menghandle redirect
        Navigator.of(context).pop();
      } else {
        // Tampilkan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth_provider.error_message ?? 'Registrasi gagal'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth_provider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      // AppBar sederhana dengan tombol back
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                  // === Judul ===
                  Text(
                    'Buat Akun Baru 🚀',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Isi data di bawah untuk mulai kelola keuanganmu',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // === Input Nama ===
                  TextFormField(
                    controller: _name_controller,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.validate_name,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama kamu',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                    textInputAction: TextInputAction.next,
                    validator: Validators.validate_password,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimal 8 karakter',
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
                  const SizedBox(height: 16),

                  // === Konfirmasi Password ===
                  TextFormField(
                    controller: _confirm_password_controller,
                    obscureText: _obscure_confirm,
                    textInputAction: TextInputAction.done,
                    validator: (value) => Validators.validate_confirm_password(
                      value,
                      _password_controller.text,
                    ),
                    onFieldSubmitted: (_) => _handle_register(),
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      hintText: 'Ulangi password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure_confirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure_confirm = !_obscure_confirm;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // === Tombol Register ===
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          auth_provider.is_loading ? null : _handle_register,
                      child: auth_provider.is_loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Daftar'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // === Link kembali ke Login ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Masuk di sini',
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
