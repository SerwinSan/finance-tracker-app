/// Service untuk inisialisasi dan akses Supabase.
/// Menyediakan akses ke auth, database, dan storage.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  /// Inisialisasi Supabase — dipanggil sekali di main.dart.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  /// Shortcut untuk mendapatkan Supabase client.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut untuk auth.
  static GoTrueClient get auth => client.auth;

  /// Shortcut untuk database query.
  static SupabaseQueryBuilder from(String table) => client.from(table);

  /// Shortcut untuk storage.
  static SupabaseStorageClient get storage => client.storage;

  /// Mendapatkan user ID yang sedang login.
  /// Melempar exception jika tidak ada user yang login.
  static String get current_user_id {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('Tidak ada user yang sedang login');
    }
    return user.id;
  }

  /// Cek apakah ada user yang sedang login.
  static bool get is_logged_in => auth.currentUser != null;
}
