/// Konstanta aplikasi.
/// Berisi string, default values, dan konfigurasi umum.
library;

class AppConstants {
  AppConstants._();

  // Nama Aplikasi
  static const String appName = 'Finance Tracker';
  static const String appTagline = 'Kelola keuanganmu dengan cerdas';

  // Default mata uang
  static const String defaultCurrency = 'IDR';
  static const List<String> supportedCurrencies = ['IDR', 'USD'];

  // Simbol mata uang
  static const Map<String, String> currencySymbols = {
    'IDR': 'Rp',
    'USD': '\$',
  };

  // Tipe pocket
  static const String pocketPersonal = 'personal';
  static const String pocketEntrusted = 'entrusted';

  // Tipe transaksi
  static const String transactionIncome = 'income';
  static const String transactionExpense = 'expense';

  // Supabase table names
  static const String tablePockets = 'pockets';
  static const String tableCategories = 'categories';
  static const String tableTransactions = 'transactions';
  static const String tableSavingGoals = 'saving_goals';
  static const String tableSavingContributions = 'saving_contributions';

  // Storage bucket
  static const String bucketSavingGoals = 'saving-goals';
}
