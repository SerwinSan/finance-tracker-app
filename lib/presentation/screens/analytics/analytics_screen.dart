/// Halaman Analytics — visualisasi pengeluaran & pemasukan.
/// Pie chart per kategori + Bar chart income vs expense.
/// Filter: Mingguan / Bulanan / Tahunan.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().load_analytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: provider.is_loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.load_analytics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Period Filter Chips ===
                    _build_period_filter(provider, theme),
                    const SizedBox(height: 20),

                    // === Summary Cards ===
                    _build_summary_cards(provider, theme),
                    const SizedBox(height: 24),

                    // === Pie Chart Pengeluaran ===
                    if (provider.expense_stats.isNotEmpty) ...[
                      Text('Pengeluaran per Kategori',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _build_pie_chart(provider.expense_stats, theme),
                      const SizedBox(height: 12),
                      _build_category_legend(provider.expense_stats, theme),
                      const SizedBox(height: 24),
                    ],

                    // === Bar Chart Pemasukan vs Pengeluaran ===
                    if (provider.period_stats.isNotEmpty) ...[
                      Text('Pemasukan vs Pengeluaran',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _build_bar_chart(provider, theme),
                      const SizedBox(height: 12),
                      _build_bar_legend(theme),
                      const SizedBox(height: 24),
                    ],

                    // === Pie Chart Pemasukan (jika ada) ===
                    if (provider.income_stats.isNotEmpty) ...[
                      Text('Pemasukan per Kategori',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _build_pie_chart(provider.income_stats, theme),
                      const SizedBox(height: 12),
                      _build_category_legend(provider.income_stats, theme),
                      const SizedBox(height: 24),
                    ],

                    // === Empty State ===
                    if (provider.expense_stats.isEmpty &&
                        provider.income_stats.isEmpty)
                      _build_empty_state(theme),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  /// Chip filter periode.
  Widget _build_period_filter(AnalyticsProvider provider, ThemeData theme) {
    return Row(
      children: AnalyticsPeriod.values.map((period) {
        final is_selected = provider.selected_period == period;
        final label = switch (period) {
          AnalyticsPeriod.weekly => 'Mingguan',
          AnalyticsPeriod.monthly => 'Bulanan',
          AnalyticsPeriod.yearly => 'Tahunan',
        };

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: is_selected,
            onSelected: (_) => provider.set_period(period),
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: is_selected
                  ? AppColors.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: is_selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Card ringkasan pemasukan, pengeluaran, dan selisih.
  Widget _build_summary_cards(AnalyticsProvider provider, ThemeData theme) {
    return Row(
      children: [
        // Pemasukan
        Expanded(
          child: _summary_card(
            title: 'Pemasukan',
            amount: provider.total_income,
            color: AppColors.income,
            icon: Icons.arrow_upward_rounded,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        // Pengeluaran
        Expanded(
          child: _summary_card(
            title: 'Pengeluaran',
            amount: provider.total_expense,
            color: AppColors.expense,
            icon: Icons.arrow_downward_rounded,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _summary_card({
    required String title,
    required int amount,
    required Color color,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(title, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.format_currency_idr(amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Pie chart pengeluaran atau pemasukan per kategori.
  Widget _build_pie_chart(List<CategoryStat> stats, ThemeData theme) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: stats.map((stat) {
            final color = _parse_color(stat.category_color);
            return PieChartSectionData(
              value: stat.percentage,
              color: color,
              radius: 50,
              title: '${stat.percentage.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Legend untuk pie chart.
  Widget _build_category_legend(List<CategoryStat> stats, ThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: stats.map((stat) {
        final color = _parse_color(stat.category_color);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${stat.category_name} (${Formatters.format_currency_idr(stat.total_amount)})',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Bar chart pemasukan vs pengeluaran per periode.
  Widget _build_bar_chart(AnalyticsProvider provider, ThemeData theme) {
    final stats = provider.period_stats;
    // Cari nilai max untuk scaling
    final max_value = stats.fold<int>(0, (max, s) {
      final bigger = s.income > s.expense ? s.income : s.expense;
      return bigger > max ? bigger : max;
    });

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: max_value > 0 ? max_value.toDouble() * 1.2 : 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                return BarTooltipItem(
                  '$label\n${Formatters.format_currency_idr(rod.toY.toInt())}',
                  TextStyle(
                    color: rodIndex == 0 ? AppColors.income : AppColors.expense,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _compact_number(value.toInt()),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= stats.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      stats[index].label,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: max_value > 0 ? max_value / 4 : 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          barGroups: stats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: stat.income.toDouble(),
                  color: AppColors.income,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: stat.expense.toDouble(),
                  color: AppColors.expense,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Legend bar chart.
  Widget _build_bar_legend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legend_item('Pemasukan', AppColors.income, theme),
        const SizedBox(width: 24),
        _legend_item('Pengeluaran', AppColors.expense, theme),
      ],
    );
  }

  Widget _legend_item(String label, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  /// Empty state ketika belum ada data.
  Widget _build_empty_state(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text('Belum ada data', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Catat beberapa transaksi dulu ya,\nbiar chart-nya muncul!',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Helper: Format angka kompak (1000 → 1rb, 1000000 → 1jt).
  String _compact_number(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toString();
  }

  Color _parse_color(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
