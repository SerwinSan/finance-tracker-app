/// Model SavingGoal — merepresentasikan target tabungan.
/// Contoh: "Beli Part Sepeda" dengan target Rp 500.000.
/// User bisa set deadline opsional dan attach foto target.
library;

class SavingGoal {
  final String id;
  final String user_id;
  final String name;
  final int target_amount;
  final int current_amount;
  final String currency;
  final DateTime? deadline;
  final String icon;
  final String color;
  final String? image_url;
  final bool is_completed;
  final DateTime created_at;
  final DateTime updated_at;
  final String sync_status;

  SavingGoal({
    required this.id,
    required this.user_id,
    required this.name,
    required this.target_amount,
    this.current_amount = 0,
    this.currency = 'IDR',
    this.deadline,
    this.icon = 'savings',
    this.color = '#FF7043',
    this.image_url,
    this.is_completed = false,
    required this.created_at,
    required this.updated_at,
    this.sync_status = 'synced',
  });

  /// Persentase progress (0.0 - 1.0).
  double get progress {
    if (target_amount <= 0) return 0;
    return (current_amount / target_amount).clamp(0.0, 1.0);
  }

  /// Persentase dalam bentuk integer (0 - 100).
  int get progress_percentage => (progress * 100).round();

  /// Sisa yang harus ditabung.
  int get remaining => (target_amount - current_amount).clamp(0, target_amount);

  /// Apakah target sudah tercapai.
  bool get is_target_reached => current_amount >= target_amount;

  /// Apakah sudah melewati deadline.
  bool get is_overdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && !is_completed;
  }

  // =========================================================
  // FACTORY CONSTRUCTORS
  // =========================================================

  /// Dari Supabase JSON response.
  factory SavingGoal.from_supabase(Map<String, dynamic> json) {
    return SavingGoal(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      name: json['name'] as String,
      target_amount: (json['target_amount'] as num).toInt(),
      current_amount: (json['current_amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'IDR',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      icon: json['icon'] as String? ?? 'savings',
      color: json['color'] as String? ?? '#FF7043',
      image_url: json['image_url'] as String?,
      is_completed: json['is_completed'] as bool? ?? false,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Dari SQLite row.
  factory SavingGoal.from_local(Map<String, dynamic> row) {
    return SavingGoal(
      id: row['id'] as String,
      user_id: row['user_id'] as String,
      name: row['name'] as String,
      target_amount: row['target_amount'] as int,
      current_amount: row['current_amount'] as int? ?? 0,
      currency: row['currency'] as String? ?? 'IDR',
      deadline: row['deadline'] != null
          ? DateTime.parse(row['deadline'] as String)
          : null,
      icon: row['icon'] as String? ?? 'savings',
      color: row['color'] as String? ?? '#FF7043',
      image_url: row['image_url'] as String?,
      is_completed: (row['is_completed'] as int?) == 1,
      created_at: DateTime.parse(row['created_at'] as String),
      updated_at: DateTime.parse(row['updated_at'] as String),
      sync_status: row['sync_status'] as String? ?? 'synced',
    );
  }

  // =========================================================
  // SERIALIZATION
  // =========================================================

  /// Ke format Supabase (insert/update).
  Map<String, dynamic> to_supabase() => {
        'id': id,
        'user_id': user_id,
        'name': name,
        'target_amount': target_amount,
        'current_amount': current_amount,
        'currency': currency,
        'deadline': deadline?.toIso8601String().split('T').first,
        'icon': icon,
        'color': color,
        'image_url': image_url,
        'is_completed': is_completed,
      };

  /// Ke format SQLite (insert/update).
  Map<String, dynamic> to_local() => {
        'id': id,
        'user_id': user_id,
        'name': name,
        'target_amount': target_amount,
        'current_amount': current_amount,
        'currency': currency,
        'deadline': deadline?.toIso8601String(),
        'icon': icon,
        'color': color,
        'image_url': image_url,
        'is_completed': is_completed ? 1 : 0,
        'created_at': created_at.toIso8601String(),
        'updated_at': updated_at.toIso8601String(),
        'sync_status': sync_status,
      };

  /// Copy with — buat salinan dengan field yang di-override.
  SavingGoal copy_with({
    String? name,
    int? target_amount,
    int? current_amount,
    DateTime? deadline,
    bool? clear_deadline,
    String? icon,
    String? color,
    String? image_url,
    bool? clear_image,
    bool? is_completed,
    String? sync_status,
  }) {
    return SavingGoal(
      id: id,
      user_id: user_id,
      name: name ?? this.name,
      target_amount: target_amount ?? this.target_amount,
      current_amount: current_amount ?? this.current_amount,
      currency: currency,
      deadline: clear_deadline == true ? null : (deadline ?? this.deadline),
      icon: icon ?? this.icon,
      color: color ?? this.color,
      image_url: clear_image == true ? null : (image_url ?? this.image_url),
      is_completed: is_completed ?? this.is_completed,
      created_at: created_at,
      updated_at: DateTime.now(),
      sync_status: sync_status ?? this.sync_status,
    );
  }
}
