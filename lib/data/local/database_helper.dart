/// SQLite Database Helper
/// Mengelola koneksi dan operasi database lokal untuk offline support.
/// Setiap tabel memiliki kolom sync_status dan last_synced_at
/// untuk tracking sinkronisasi dengan Supabase.
library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern — satu instance untuk seluruh aplikasi
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Mendapatkan instance database (lazy initialization).
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _init_database();
    return _database!;
  }

  /// Inisialisasi database SQLite.
  Future<Database> _init_database() async {
    final db_path = await getDatabasesPath();
    final path = join(db_path, 'finance_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _on_create,
      onUpgrade: _on_upgrade,
    );
  }

  /// Membuat tabel saat pertama kali database dibuka.
  Future<void> _on_create(Database db, int version) async {
    // Tabel Pockets
    await db.execute('''
      CREATE TABLE pockets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'personal',
        balance INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'IDR',
        color TEXT NOT NULL DEFAULT '#00897B',
        icon TEXT NOT NULL DEFAULT 'wallet',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        last_synced_at TEXT
      )
    ''');

    // Tabel Categories
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'category',
        color TEXT NOT NULL DEFAULT '#26A69A',
        type TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        last_synced_at TEXT
      )
    ''');

    // Tabel Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        pocket_id TEXT NOT NULL,
        category_id TEXT,
        amount INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'IDR',
        type TEXT NOT NULL,
        description TEXT,
        label TEXT,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        last_synced_at TEXT,
        FOREIGN KEY (pocket_id) REFERENCES pockets(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    // Tabel Saving Goals
    await db.execute('''
      CREATE TABLE saving_goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        target_amount INTEGER NOT NULL,
        current_amount INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'IDR',
        deadline TEXT,
        icon TEXT NOT NULL DEFAULT 'savings',
        color TEXT NOT NULL DEFAULT '#FF7043',
        image_url TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        last_synced_at TEXT
      )
    ''');

    // Tabel Saving Contributions
    await db.execute('''
      CREATE TABLE saving_contributions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        goal_id TEXT NOT NULL,
        pocket_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        last_synced_at TEXT,
        FOREIGN KEY (goal_id) REFERENCES saving_goals(id) ON DELETE CASCADE,
        FOREIGN KEY (pocket_id) REFERENCES pockets(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Handler untuk upgrade versi database.
  Future<void> _on_upgrade(Database db, int old_version, int new_version) async {
    // Akan diisi ketika ada perubahan schema di masa depan
  }

  // =========================================================
  // GENERIC CRUD OPERATIONS
  // =========================================================

  /// Insert data ke tabel tertentu.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Query data dari tabel dengan filter opsional.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? where_args,
    String? order_by,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: where_args,
      orderBy: order_by,
      limit: limit,
    );
  }

  /// Update data di tabel tertentu.
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> where_args,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: where_args);
  }

  /// Hapus data dari tabel tertentu.
  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> where_args,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: where_args);
  }

  /// Eksekusi raw SQL query (untuk aggregate, JOIN, dll).
  Future<List<Map<String, dynamic>>> raw_query(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Membersihkan semua data lokal (digunakan saat logout).
  Future<void> clear_all_data() async {
    final db = await database;
    await db.delete('saving_contributions');
    await db.delete('saving_goals');
    await db.delete('transactions');
    await db.delete('categories');
    await db.delete('pockets');
  }

  /// Menutup koneksi database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
