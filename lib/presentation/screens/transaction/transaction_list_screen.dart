/// Halaman Riwayat Transaksi — menampilkan semua transaksi user.
/// Grouped by tanggal. Bisa tambah transaksi baru via FAB.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../utils/formatters.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().load_transactions();
    });
  }

  /// Navigasi ke form transaksi baru.
  Future<void> _go_to_add_transaction() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
    );

    // Refresh data jika transaksi berhasil dibuat
    if (result == true && mounted) {
      context.read<TransactionProvider>().load_transactions();
      context.read<PocketProvider>().load_pockets();
    }
  }

  /// Konfirmasi hapus transaksi.
  void _confirm_delete(Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Transaksi "${tx.description ?? tx.category_name ?? 'ini'}" sebesar ${Formatters.format_currency(tx.amount, tx.currency)} akan dihapus. Saldo dompet akan dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success =
                  await context.read<TransactionProvider>().delete_transaction(tx);
              if (success && mounted) {
                context.read<PocketProvider>().load_pockets();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tx_provider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: RefreshIndicator(
        onRefresh: () => tx_provider.load_transactions(),
        child: tx_provider.is_loading && tx_provider.transactions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : tx_provider.transactions.isEmpty
                ? _build_empty_state(theme)
                : _build_transaction_list(tx_provider.transactions, theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _go_to_add_transaction,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat'),
      ),
    );
  }

  /// List transaksi grouped by tanggal.
  Widget _build_transaction_list(
    List<Transaction> transactions,
    ThemeData theme,
  ) {
    // Group by tanggal
    final grouped = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final date_key = Formatters.format_date(tx.transaction_date);
      grouped.putIfAbsent(date_key, () => []).add(tx);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date_key = grouped.keys.elementAt(index);
        final txs = grouped[date_key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header tanggal
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                date_key,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Daftar transaksi hari itu
            ...txs.map((tx) => _build_transaction_tile(tx, theme)),
          ],
        );
      },
    );
  }

  /// Satu tile transaksi.
  Widget _build_transaction_tile(Transaction tx, ThemeData theme) {
    final is_expense = tx.is_expense;
    final category_color = _parse_color(tx.category_color ?? '#78909C');

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.expense),
      ),
      confirmDismiss: (_) async {
        _confirm_delete(tx);
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Ikon kategori
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category_color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _get_icon(tx.category_icon ?? 'more_horiz'),
                  color: category_color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info transaksi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description ?? tx.category_name ?? 'Transaksi',
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          tx.category_name ?? '-',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (tx.label != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tx.label!,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Jumlah
              Text(
                '${is_expense ? '-' : '+'}${Formatters.format_currency(tx.amount, tx.currency)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: is_expense ? AppColors.expense : AppColors.income,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state.
  Widget _build_empty_state(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text('Belum ada transaksi', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Yuk catat pemasukan atau pengeluaranmu!',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _go_to_add_transaction,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Catat Transaksi'),
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

  IconData _get_icon(String icon_name) {
    const icon_map = {
      'restaurant': Icons.restaurant_rounded,
      'directions_car': Icons.directions_car_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'movie': Icons.movie_rounded,
      'local_hospital': Icons.local_hospital_rounded,
      'school': Icons.school_rounded,
      'receipt_long': Icons.receipt_long_rounded,
      'more_horiz': Icons.more_horiz_rounded,
      'account_balance_wallet': Icons.account_balance_wallet_rounded,
      'laptop': Icons.laptop_rounded,
      'card_giftcard': Icons.card_giftcard_rounded,
      'trending_up': Icons.trending_up_rounded,
      'category': Icons.category_rounded,
    };
    return icon_map[icon_name] ?? Icons.category_rounded;
  }
}
