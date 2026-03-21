/// Model Pocket (Dompet Virtual).
/// Merepresentasikan satu pocket/dompet, bisa berupa
/// uang pribadi ('personal') atau titipan ('entrusted').
library;

class Pocket {
  final String id;
  final String user_id;
  final String name;
  final String type; // 'personal' | 'entrusted'
  final int balance; // dalam satuan terkecil (rupiah/sen)
  final String currency; // 'IDR' | 'USD'
  final String color; // hex color
  final String icon; // Material icon name
  final DateTime created_at;
  final DateTime updated_at;
  final String sync_status; // 'synced' | 'pending' | 'conflict'

  Pocket({
    required this.id,
    required this.user_id,
    required this.name,
    this.type = 'personal',
    this.balance = 0,
    this.currency = 'IDR',
    this.color = '#00897B',
    this.icon = 'wallet',
    DateTime? created_at,
    DateTime? updated_at,
    this.sync_status = 'synced',
  })  : created_at = created_at ?? DateTime.now(),
        updated_at = updated_at ?? DateTime.now();

  /// Dari JSON Supabase → Pocket object.
  factory Pocket.from_supabase(Map<String, dynamic> json) {
    return Pocket(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'personal',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'IDR',
      color: json['color'] as String? ?? '#00897B',
      icon: json['icon'] as String? ?? 'wallet',
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Dari row SQLite → Pocket object.
  factory Pocket.from_local(Map<String, dynamic> json) {
    return Pocket(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'personal',
      balance: json['balance'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'IDR',
      color: json['color'] as String? ?? '#00897B',
      icon: json['icon'] as String? ?? 'wallet',
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
      sync_status: json['sync_status'] as String? ?? 'synced',
    );
  }

  /// Pocket → Map untuk insert ke Supabase.
  Map<String, dynamic> to_supabase() {
    return {
      'id': id,
      'user_id': user_id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'color': color,
      'icon': icon,
    };
  }

  /// Pocket → Map untuk insert ke SQLite.
  Map<String, dynamic> to_local() {
    return {
      'id': id,
      'user_id': user_id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'color': color,
      'icon': icon,
      'created_at': created_at.toIso8601String(),
      'updated_at': updated_at.toIso8601String(),
      'sync_status': sync_status,
    };
  }

  /// Membuat salinan Pocket dengan perubahan tertentu.
  Pocket copy_with({
    String? name,
    String? type,
    int? balance,
    String? currency,
    String? color,
    String? icon,
    String? sync_status,
  }) {
    return Pocket(
      id: this.id,
      user_id: this.user_id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      created_at: this.created_at,
      updated_at: DateTime.now(),
      sync_status: sync_status ?? this.sync_status,
    );
  }

  /// Cek apakah pocket ini tipe titipan.
  bool get is_entrusted => type == 'entrusted';

  /// Cek apakah pocket ini tipe pribadi.
  bool get is_personal => type == 'personal';
}
