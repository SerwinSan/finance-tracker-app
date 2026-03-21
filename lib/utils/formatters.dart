/// Utility untuk format mata uang dan tanggal.
/// Menggunakan package intl untuk internasionalisasi.
library;

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// Format angka ke format mata uang Rupiah.
  /// Contoh: 150000 → "Rp 150.000"
  static String format_currency_idr(int amount) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return 'Rp ${formatter.format(amount)}';
  }

  /// Format angka ke format mata uang Dollar.
  /// Contoh: 15000 → "\$150.00"
  /// Amount disimpan dalam sen, jadi dibagi 100.
  static String format_currency_usd(int amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '\$${formatter.format(amount / 100)}';
  }

  /// Format otomatis berdasarkan kode mata uang.
  static String format_currency(int amount, String currency) {
    switch (currency) {
      case 'USD':
        return format_currency_usd(amount);
      case 'IDR':
      default:
        return format_currency_idr(amount);
    }
  }

  /// Format tanggal ke format Indonesia.
  /// Contoh: "21 Mar 2026"
  static String format_date(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  /// Format tanggal singkat.
  /// Contoh: "21 Mar"
  static String format_date_short(DateTime date) {
    return DateFormat('dd MMM', 'id_ID').format(date);
  }

  /// Format tanggal dan waktu.
  /// Contoh: "21 Mar 2026, 14:30"
  static String format_date_time(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
  }

  /// Format angka dengan separator ribuan.
  /// Contoh: 1500000 → "1.500.000"
  static String format_number(int number) {
    return NumberFormat('#,##0', 'id_ID').format(number);
  }

  /// Hitung persentase (untuk progress saving goals).
  /// Return string persentase, contoh: "75%"
  static String format_percentage(int current, int target) {
    if (target <= 0) return '0%';
    final percentage = (current / target * 100).clamp(0, 100);
    return '${percentage.toStringAsFixed(0)}%';
  }

  /// Mengembalikan greeting berdasarkan waktu.
  /// "Pagi" (05-11), "Siang" (11-15), "Sore" (15-18), "Malam" (18-05)
  static String get_greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Pagi';
    if (hour >= 11 && hour < 15) return 'Siang';
    if (hour >= 15 && hour < 18) return 'Sore';
    return 'Malam';
  }
}
