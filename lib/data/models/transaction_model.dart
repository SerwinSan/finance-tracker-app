/// Model Transaction — catatan pemasukan/pengeluaran.
/// Setiap transaksi terhubung ke satu Pocket dan satu Category.
library;

class Transaction {
  final String id;
  final String user_id;
  final String pocket_id;
  final String? category_id;
  final int amount; // dalam satuan terkecil (rupiah)
  final String currency;
  final String type; // 'income' | 'expense'
  final String? description;
  final String? label; // label "milik siapa" (opsional)
  final DateTime transaction_date;
  final DateTime created_at;
  final DateTime updated_at;
  final String sync_status;

  // Relasi (opsional, untuk display)
  final String? category_name;
  final String? category_icon;
  final String? category_color;
  final String? pocket_name;

  Transaction({
    required this.id,
    required this.user_id,
    required this.pocket_id,
    this.category_id,
    required this.amount,
    this.currency = 'IDR',
    required this.type,
    this.description,
    this.label,
    DateTime? transaction_date,
    DateTime? created_at,
    DateTime? updated_at,
    this.sync_status = 'synced',
    this.category_name,
    this.category_icon,
    this.category_color,
    this.pocket_name,
  })  : transaction_date = transaction_date ?? DateTime.now(),
        created_at = created_at ?? DateTime.now(),
        updated_at = updated_at ?? DateTime.now();

  /// Dari JSON Supabase (dengan join categories) → Transaction object.
  factory Transaction.from_supabase(Map<String, dynamic> json) {
    // Handle joined category data
    final category_data = json['categories'] as Map<String, dynamic>?;

    return Transaction(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      pocket_id: json['pocket_id'] as String,
      category_id: json['category_id'] as String?,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String? ?? 'IDR',
      type: json['type'] as String,
      description: json['description'] as String?,
      label: json['label'] as String?,
      transaction_date: DateTime.parse(json['transaction_date'] as String),
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
      category_name: category_data?['name'] as String?,
      category_icon: category_data?['icon'] as String?,
      category_color: category_data?['color'] as String?,
    );
  }

  /// Dari row SQLite → Transaction object.
  factory Transaction.from_local(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      pocket_id: json['pocket_id'] as String,
      category_id: json['category_id'] as String?,
      amount: json['amount'] as int,
      currency: json['currency'] as String? ?? 'IDR',
      type: json['type'] as String,
      description: json['description'] as String?,
      label: json['label'] as String?,
      transaction_date: DateTime.parse(json['transaction_date'] as String),
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
      sync_status: json['sync_status'] as String? ?? 'synced',
    );
  }

  /// Transaction → Map untuk insert ke Supabase.
  Map<String, dynamic> to_supabase() {
    return {
      'id': id,
      'user_id': user_id,
      'pocket_id': pocket_id,
      'category_id': category_id,
      'amount': amount,
      'currency': currency,
      'type': type,
      'description': description,
      'label': label,
      'transaction_date': transaction_date.toIso8601String(),
    };
  }

  /// Transaction → Map untuk insert ke SQLite.
  Map<String, dynamic> to_local() {
    return {
      'id': id,
      'user_id': user_id,
      'pocket_id': pocket_id,
      'category_id': category_id,
      'amount': amount,
      'currency': currency,
      'type': type,
      'description': description,
      'label': label,
      'transaction_date': transaction_date.toIso8601String(),
      'created_at': created_at.toIso8601String(),
      'updated_at': updated_at.toIso8601String(),
      'sync_status': sync_status,
    };
  }

  /// Salinan dengan perubahan tertentu.
  Transaction copy_with({
    String? pocket_id,
    String? category_id,
    int? amount,
    String? currency,
    String? type,
    String? description,
    String? label,
    DateTime? transaction_date,
    String? sync_status,
  }) {
    return Transaction(
      id: this.id,
      user_id: this.user_id,
      pocket_id: pocket_id ?? this.pocket_id,
      category_id: category_id ?? this.category_id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      description: description ?? this.description,
      label: label ?? this.label,
      transaction_date: transaction_date ?? this.transaction_date,
      created_at: this.created_at,
      updated_at: DateTime.now(),
      sync_status: sync_status ?? this.sync_status,
    );
  }

  /// Cek apakah ini pengeluaran
  bool get is_expense => type == 'expense';

  /// Cek apakah ini pemasukan
  bool get is_income => type == 'income';
}
