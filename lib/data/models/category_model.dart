/// Model Category — kategori transaksi (income / expense).
/// Kategori default sudah ada di Supabase (13 kategori).
/// User bisa juga buat kategori custom sendiri.
library;

class Category {
  final String id;
  final String? user_id; // null = default category
  final String name;
  final String icon;
  final String color;
  final String type; // 'income' | 'expense'
  final bool is_default;
  final DateTime created_at;

  Category({
    required this.id,
    this.user_id,
    required this.name,
    this.icon = 'category',
    this.color = '#26A69A',
    required this.type,
    this.is_default = false,
    DateTime? created_at,
  }) : created_at = created_at ?? DateTime.now();

  /// Dari JSON Supabase → Category object.
  factory Category.from_supabase(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      user_id: json['user_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '#26A69A',
      type: json['type'] as String,
      is_default: json['is_default'] as bool? ?? false,
      created_at: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Dari row SQLite → Category object.
  factory Category.from_local(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      user_id: json['user_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '#26A69A',
      type: json['type'] as String,
      is_default: (json['is_default'] as int?) == 1,
      created_at: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Category → Map untuk SQLite.
  Map<String, dynamic> to_local() {
    return {
      'id': id,
      'user_id': user_id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'is_default': is_default ? 1 : 0,
      'created_at': created_at.toIso8601String(),
      'sync_status': 'synced',
    };
  }
}
