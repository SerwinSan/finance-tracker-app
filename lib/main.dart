/// Entry point aplikasi Finance Tracker.
/// Inisialisasi Supabase dan dotenv sebelum app dijalankan.
library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/services/supabase_service.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/pocket_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'presentation/providers/analytics_provider.dart';

void main() async {
  // Pastikan Flutter binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables dari .env
  await dotenv.load(fileName: '.env');

  // Inisialisasi Supabase
  await SupabaseService.initialize();

  // Inisialisasi locale data untuk format tanggal & angka Indonesia
  await initializeDateFormatting('id_ID', null);

  runApp(
    // MultiProvider untuk menyediakan semua provider ke widget tree
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PocketProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: const FinanceTrackerApp(),
    ),
  );
}
