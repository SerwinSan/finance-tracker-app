/// Repository Category — mengelola data kategori transaksi.
/// Default categories diambil dari Supabase, juga di-cache lokal.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category_model.dart';
import '../local/database_helper.dart';
import '../services/supabase_service.dart';
import '../../config/constants/app_constants.dart';

class CategoryRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// Ambil semua kategori (default + custom user).
  Future<List<Category>> get_all_categories() async {
    try {
      final is_online = await _check_connectivity();

      if (is_online) {
        return await _fetch_from_remote();
      }
      return await _fetch_from_local();
    } catch (e) {
      debugPrint('[CategoryRepo] get_all_categories error: $e');
      return await _fetch_from_local();
    }
  }

  /// Ambil kategori berdasarkan tipe (income / expense).
  Future<List<Category>> get_categories_by_type(String type) async {
    final all = await get_all_categories();
    return all.where((c) => c.type == type).toList();
  }

  /// Ambil dari Supabase dan cache ke lokal.
  Future<List<Category>> _fetch_from_remote() async {
    final user_id = SupabaseService.current_user_id;

    // Ambil default categories (user_id IS NULL) dan custom user categories
    final response = await SupabaseService.from(AppConstants.tableCategories)
        .select()
        .or('user_id.is.null,user_id.eq.$user_id')
        .order('name', ascending: true);

    final categories = (response as List)
        .map((json) => Category.from_supabase(json as Map<String, dynamic>))
        .toList();

    // Cache ke lokal
    for (final category in categories) {
      await _db.insert(AppConstants.tableCategories, category.to_local());
    }

    return categories;
  }

  /// Ambil dari SQLite lokal.
  Future<List<Category>> _fetch_from_local() async {
    try {
      final user_id = SupabaseService.current_user_id;
      final rows = await _db.query(
        AppConstants.tableCategories,
        where: 'user_id IS NULL OR user_id = ?',
        where_args: [user_id],
        order_by: 'name ASC',
      );
      return rows.map((row) => Category.from_local(row)).toList();
    } catch (e) {
      debugPrint('[CategoryRepo] _fetch_from_local error: $e');
      return [];
    }
  }

  /// Cek koneksi internet.
  Future<bool> _check_connectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      return !connectivity.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }
}
