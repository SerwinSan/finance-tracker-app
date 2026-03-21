/// Validasi input form.
/// Menggunakan Guard Clause pattern untuk validasi yang jelas.
library;

class Validators {
  Validators._();

  /// Validasi email — memastikan format valid.
  static String? validate_email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final email_regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!email_regex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }

    return null; // Valid
  }

  /// Validasi password — minimal 8 karakter, huruf besar, kecil, dan angka.
  static String? validate_password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password harus mengandung huruf besar';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password harus mengandung huruf kecil';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password harus mengandung angka';
    }

    return null; // Valid
  }

  /// Validasi konfirmasi password.
  static String? validate_confirm_password(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }

    return null; // Valid
  }

  /// Validasi nama (tidak boleh kosong, min 2 karakter).
  static String? validate_name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }

    return null;
  }

  /// Validasi jumlah uang — harus angka positif.
  static String? validate_amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }

    final amount = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      return 'Masukkan jumlah yang valid';
    }

    return null;
  }

  /// Validasi field umum — hanya cek tidak kosong.
  static String? validate_required(String? value, String field_name) {
    if (value == null || value.trim().isEmpty) {
      return '$field_name tidak boleh kosong';
    }
    return null;
  }
}
