/// Halaman Detail Dompet — menampilkan info dompet dan history transaksi
/// khusus dompet tersebut (masuk & keluar).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/models/pocket_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../utils/formatters.dart';
import '../../providers/pocket_provider.dart';
import '../pocket/pocket_form_screen.dart';
import '../transaction/transaction_form_screen.dart';

class PocketDetailScreen extends StatefulWidget {
  final Pocket pocket;

  const PocketDetailScreen({super.key, required this.pocket});

  @override
  State<PocketDetailScreen> createState() => _PocketDetailScreenState();
}

class _PocketDetailScreenState extends State<PocketDetailScreen> {
  final TransactionRepository _tx_repo = TransactionRepository();

  List<Transaction> _transactions = [];
  bool _is_loading = true;
  String? _error;

  // Pocket terbaru (bisa berubah setelah edit)
  late Pocket _pocket;

  @override
  void initState() {
    super.initState();
    _pocket = widget.pocket;
    _load_transactions();
  }

  Future<void> _load_transactions() async {
    setState(() {
      _is_loading = true;
      _error = null;
    });

    try {
      final result = await _tx_repo.get_transactions(
        pocket_id: _pocket.id,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _transactions = result;
          _is_loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat riwayat. Coba lagi.';
          _is_loading = false;
        });
      }
    }
  }

  /// Refresh pocket data terbaru dari provider
  void _refresh_pocket() {
    final provider = context.read<PocketProvider>();
    final updated = provider.pockets.where((p) => p.id == _pocket.id);
    if (updated.isNotEmpty) {
      setState(() => _pocket = updated.first);
    }
  }

  /// Hitung total pemasukan & pengeluaran dompet ini
  int get _total_income =>
      _transactions.where((t) => t.is_income).fold(0, (s, t) => s + t.amount);

  int get _total_expense =>
      _transactions.where((t) => t.is_expense).fold(0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pocket_color = _parse_color(_pocket.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(_pocket.name),
        actions: [
          // Tombol edit
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Dompet',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PocketFormScreen(pocket: _pocket),
                ),
              );
              // Refresh data setelah edit
              _refresh_pocket();
              _load_transactions();
            },
          ),
          // Menu hapus
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirm_delete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded,
                        size: 18, color: AppColors.expense),
                    SizedBox(width: 8),
                    Text('Hapus Dompet',
                        style: TextStyle(color: AppColors.expense)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh_pocket();
          await _load_transactions();
        },
        child: CustomScrollView(
          slivers: [
            // === Header Info Dompet ===
            SliverToBoxAdapter(
              child: _build_pocket_header(theme, pocket_color),
            ),

            // === Ringkasan Masuk/Keluar ===
            SliverToBoxAdapter(
              child: _build_summary_cards(theme),
            ),

            // === Section Header ===
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Riwayat Transaksi',
                        style: theme.textTheme.titleMedium),
                    Text('${_transactions.length} transaksi',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),

            // === List Transaksi ===
            if (_is_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48, color: AppColors.expense),
                      const SizedBox(height: 12),
                      Text(_error!, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load_transactions,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_transactions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 56,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('Belum ada transaksi',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text('Yuk catat pemasukan atau pengeluaranmu!',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = _transactions[index];
                      return _build_transaction_tile(theme, tx);
                    },
                    childCount: _transactions.length,
                  ),
                ),
              ),

            // Spacer bawah
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      // FAB untuk tambah transaksi langsung ke dompet ini
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'pocket_detail_fab',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TransactionFormScreen(preselected_pocket_id: _pocket.id),
            ),
          );
          // Refresh setelah tambah transaksi
          _refresh_pocket();
          _load_transactions();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Transaksi'),
      ),
    );
  }

  /// Header card info dompet (nama, saldo, tipe, mata uang).
  Widget _build_pocket_header(ThemeData theme, Color pocket_color) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pocket_color,
            pocket_color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: pocket_color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipe badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _pocket.is_entrusted ? '🤝 Titipan' : '👤 Pribadi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Currency badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _pocket.currency,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Label saldo
          Text(
            'Saldo Saat Ini',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),

          // Nominal saldo
          Text(
            Formatters.format_currency(_pocket.balance, _pocket.currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Card ringkasan pemasukan & pengeluaran dompet ini.
  Widget _build_summary_cards(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Pemasukan
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.income.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_downward_rounded,
                              color: AppColors.income, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('Masuk',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      Formatters.format_currency(
                          _total_income, _pocket.currency),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.income,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Pengeluaran
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_upward_rounded,
                              color: AppColors.expense, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('Keluar',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      Formatters.format_currency(
                          _total_expense, _pocket.currency),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.expense,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tile satu transaksi dalam list.
  Widget _build_transaction_tile(ThemeData theme, Transaction tx) {
    final is_income = tx.is_income;
    final color = is_income ? AppColors.income : AppColors.expense;
    final icon = is_income
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    // Parse category color
    Color cat_color;
    try {
      cat_color = tx.category_color != null
          ? Color(int.parse(tx.category_color!.replaceFirst('#', '0xFF')))
          : color;
    } catch (_) {
      cat_color = color;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cat_color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cat_color, size: 20),
        ),
        title: Text(
          tx.category_name ?? (is_income ? 'Pemasukan' : 'Pengeluaran'),
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx.description != null && tx.description!.isNotEmpty)
              Text(tx.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            Text(
              Formatters.format_date(tx.transaction_date),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          '${is_income ? '+' : '-'} ${Formatters.format_currency(tx.amount, tx.currency)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Dialog konfirmasi hapus dompet.
  void _confirm_delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dompet?'),
        content: Text(
          'Dompet "${_pocket.name}" dan semua transaksi di dalamnya akan dihapus permanen. Yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context
                  .read<PocketProvider>()
                  .delete_pocket(_pocket.id);
              if (success && mounted) {
                Navigator.of(context).pop(); // Kembali ke beranda
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Gagal menghapus dompet'),
                    backgroundColor: AppColors.expense,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Color _parse_color(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
