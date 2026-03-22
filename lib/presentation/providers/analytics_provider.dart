/// Provider Analytics — mengelola data untuk chart dan statistik.
/// Mengambil transaksi berdasarkan periode, lalu aggregate per kategori.
library;

import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

/// Data untuk satu bagian pie chart.
class CategoryStat {
  final String category_name;
  final String category_icon;
  final String category_color;
  final int total_amount;
  final double percentage;

  CategoryStat({
    required this.category_name,
    required this.category_icon,
    required this.category_color,
    required this.total_amount,
    required this.percentage,
  });
}

/// Data untuk satu bar (satu hari/minggu/bulan) di bar chart.
class PeriodStat {
  final String label; // Nama periode (mis: "Sen", "Mar")
  final int income;
  final int expense;

  PeriodStat({
    required this.label,
    required this.income,
    required this.expense,
  });
}

/// Tipe periode filter.
enum AnalyticsPeriod { weekly, monthly, yearly }

class AnalyticsProvider extends ChangeNotifier {
  final TransactionRepository _tx_repo = TransactionRepository();

  List<Transaction> _transactions = [];
  List<CategoryStat> _expense_stats = [];
  List<CategoryStat> _income_stats = [];
  List<PeriodStat> _period_stats = [];
  AnalyticsPeriod _selected_period = AnalyticsPeriod.monthly;
  bool _is_loading = false;

  int _total_income = 0;
  int _total_expense = 0;

  // === Getters ===
  List<CategoryStat> get expense_stats => _expense_stats;
  List<CategoryStat> get income_stats => _income_stats;
  List<PeriodStat> get period_stats => _period_stats;
  AnalyticsPeriod get selected_period => _selected_period;
  bool get is_loading => _is_loading;
  int get total_income => _total_income;
  int get total_expense => _total_expense;
  int get net_balance => _total_income - _total_expense;

  /// Ganti periode filter dan reload data.
  void set_period(AnalyticsPeriod period) {
    _selected_period = period;
    load_analytics();
  }

  /// Load semua data analytics.
  Future<void> load_analytics() async {
    try {
      _is_loading = true;
      notifyListeners();

      // Ambil semua transaksi (limit 200 untuk analytics)
      _transactions = await _tx_repo.get_transactions(limit: 200);

      // Filter berdasarkan periode
      final now = DateTime.now();
      final filtered = _filter_by_period(_transactions, now);

      // Hitung total
      _total_income = filtered
          .where((t) => t.is_income)
          .fold(0, (sum, t) => sum + t.amount);
      _total_expense = filtered
          .where((t) => t.is_expense)
          .fold(0, (sum, t) => sum + t.amount);

      // Aggregate per kategori
      _expense_stats = _aggregate_by_category(
        filtered.where((t) => t.is_expense).toList(),
      );
      _income_stats = _aggregate_by_category(
        filtered.where((t) => t.is_income).toList(),
      );

      // Generate period stats untuk bar chart
      _period_stats = _generate_period_stats(filtered, now);

      notifyListeners();
    } catch (e) {
      debugPrint('[AnalyticsProvider] load_analytics error: $e');
    } finally {
      _is_loading = false;
      notifyListeners();
    }
  }

  /// Filter transaksi berdasarkan periode terpilih.
  List<Transaction> _filter_by_period(List<Transaction> txs, DateTime now) {
    switch (_selected_period) {
      case AnalyticsPeriod.weekly:
        // 7 hari terakhir
        final start = now.subtract(const Duration(days: 7));
        return txs.where((t) => t.transaction_date.isAfter(start)).toList();

      case AnalyticsPeriod.monthly:
        // Bulan ini
        final start = DateTime(now.year, now.month, 1);
        return txs.where((t) => t.transaction_date.isAfter(start)).toList();

      case AnalyticsPeriod.yearly:
        // Tahun ini
        final start = DateTime(now.year, 1, 1);
        return txs.where((t) => t.transaction_date.isAfter(start)).toList();
    }
  }

  /// Aggregate transaksi per kategori → CategoryStat.
  List<CategoryStat> _aggregate_by_category(List<Transaction> txs) {
    if (txs.isEmpty) return [];

    final map = <String, Map<String, dynamic>>{};
    int grand_total = 0;

    for (final tx in txs) {
      final key = tx.category_name ?? 'Lainnya';
      map.putIfAbsent(key, () => {
            'name': key,
            'icon': tx.category_icon ?? 'more_horiz',
            'color': tx.category_color ?? '#78909C',
            'total': 0,
          });
      map[key]!['total'] = (map[key]!['total'] as int) + tx.amount;
      grand_total += tx.amount;
    }

    // Urutkan dari terbesar
    final sorted = map.values.toList()
      ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

    return sorted.map((item) {
      final total = item['total'] as int;
      return CategoryStat(
        category_name: item['name'] as String,
        category_icon: item['icon'] as String,
        category_color: item['color'] as String,
        total_amount: total,
        percentage: grand_total > 0 ? total / grand_total * 100 : 0,
      );
    }).toList();
  }

  /// Generate data bar chart berdasarkan periode.
  List<PeriodStat> _generate_period_stats(
    List<Transaction> txs,
    DateTime now,
  ) {
    switch (_selected_period) {
      case AnalyticsPeriod.weekly:
        return _weekly_stats(txs, now);
      case AnalyticsPeriod.monthly:
        return _monthly_stats(txs, now);
      case AnalyticsPeriod.yearly:
        return _yearly_stats(txs, now);
    }
  }

  /// Statistik per hari (7 hari terakhir).
  List<PeriodStat> _weekly_stats(List<Transaction> txs, DateTime now) {
    const day_labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final stats = <PeriodStat>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final day_txs = txs.where((t) =>
          t.transaction_date.year == day.year &&
          t.transaction_date.month == day.month &&
          t.transaction_date.day == day.day);

      final income = day_txs
          .where((t) => t.is_income)
          .fold(0, (sum, t) => sum + t.amount);
      final expense = day_txs
          .where((t) => t.is_expense)
          .fold(0, (sum, t) => sum + t.amount);

      stats.add(PeriodStat(
        label: day_labels[day.weekday - 1],
        income: income,
        expense: expense,
      ));
    }
    return stats;
  }

  /// Statistik per minggu (bulan ini, 4-5 minggu).
  List<PeriodStat> _monthly_stats(List<Transaction> txs, DateTime now) {
    final stats = <PeriodStat>[];
    final first_day = DateTime(now.year, now.month, 1);
    int week = 1;

    // Bagi bulan menjadi 4-5 minggu
    var week_start = first_day;
    while (week_start.month == now.month && week <= 5) {
      var week_end = week_start.add(const Duration(days: 7));
      if (week_end.month != now.month) {
        week_end = DateTime(now.year, now.month + 1, 0);
      }

      final week_txs = txs.where((t) =>
          !t.transaction_date.isBefore(week_start) &&
          t.transaction_date.isBefore(week_end));

      final income = week_txs
          .where((t) => t.is_income)
          .fold(0, (sum, t) => sum + t.amount);
      final expense = week_txs
          .where((t) => t.is_expense)
          .fold(0, (sum, t) => sum + t.amount);

      stats.add(PeriodStat(
        label: 'Mg $week',
        income: income,
        expense: expense,
      ));

      week_start = week_end;
      week++;
    }
    return stats;
  }

  /// Statistik per bulan (tahun ini).
  List<PeriodStat> _yearly_stats(List<Transaction> txs, DateTime now) {
    const month_labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final stats = <PeriodStat>[];

    for (int m = 1; m <= now.month; m++) {
      final month_txs = txs.where((t) =>
          t.transaction_date.year == now.year &&
          t.transaction_date.month == m);

      final income = month_txs
          .where((t) => t.is_income)
          .fold(0, (sum, t) => sum + t.amount);
      final expense = month_txs
          .where((t) => t.is_expense)
          .fold(0, (sum, t) => sum + t.amount);

      stats.add(PeriodStat(
        label: month_labels[m - 1],
        income: income,
        expense: expense,
      ));
    }
    return stats;
  }
}
