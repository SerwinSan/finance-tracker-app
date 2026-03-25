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

  /// Validasi panjang maksimum teks.
  static String? validate_max_length(String? value, int max, String field_name) {
    if (value != null && value.trim().length > max) {
      return '$field_name maksimal $max karakter';
    }
    return null;
  }

  /// Validasi nama pocket/goal — tidak boleh kosong, max 50 karakter.
  static String? validate_pocket_name(String? value) {
    final required_error = validate_required(value, 'Nama');
    if (required_error != null) return required_error;
    return validate_max_length(value, 50, 'Nama');
  }

  // =========================================================
  // SANITIZATION — mencegah XSS dan input berbahaya
  // =========================================================

  /// Hapus HTML tags dari input teks.
  /// Mencegah XSS jika data ditampilkan di web atau laporan.
  static String sanitize_text(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Hapus HTML tags
        .replaceAll(RegExp(r'[<>]'), '')     // Hapus sisa < >
        .trim();
  }

  /// Sanitize deskripsi transaksi — strip HTML, limit panjang.
  static String sanitize_description(String input, {int max_length = 200}) {
    final cleaned = sanitize_text(input);
    if (cleaned.length > max_length) {
      return cleaned.substring(0, max_length);
    }
    return cleaned;
  }
}
