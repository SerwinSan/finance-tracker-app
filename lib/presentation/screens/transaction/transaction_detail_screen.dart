/// Halaman Detail Transaksi — menampilkan informasi lengkap satu transaksi.
/// Termasuk nominal, kategori, label, dompet asal, tanggal, dan deskripsi.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../utils/formatters.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tx = transaction;
    final is_income = tx.is_income;
    final color = is_income ? AppColors.income : AppColors.expense;

    // Ambil nama pocket dari provider
    final pocket_provider = context.read<PocketProvider>();
    final pocket = pocket_provider.pockets
        .where((p) => p.id == tx.pocket_id)
        .toList();
    final pocket_name = pocket.isNotEmpty ? pocket.first.name : 'Dompet';
    final pocket_currency = pocket.isNotEmpty ? pocket.first.currency : tx.currency;

    // Parse warna kategori
    Color cat_color;
    try {
      cat_color = tx.category_color != null
          ? Color(int.parse(tx.category_color!.replaceFirst('#', '0xFF')))
          : color;
    } catch (_) {
      cat_color = color;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          // Tombol hapus
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Hapus Transaksi',
            onPressed: () => _confirm_delete(context, tx),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // === Header: Nominal besar ===
            _build_amount_header(theme, tx, is_income, color, cat_color),

            const SizedBox(height: 24),

            // === Detail Info Card ===
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // Tipe
                    _build_info_row(
                      context,
                      icon: is_income
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      icon_color: color,
                      label: 'Tipe',
                      value: is_income ? 'Pemasukan' : 'Pengeluaran',
                    ),

                    _build_divider(theme),

                    // Kategori
                    _build_info_row(
                      context,
                      icon: _get_icon(tx.category_icon ?? 'category'),
                      icon_color: cat_color,
                      label: 'Kategori',
                      value: tx.category_name ?? '-',
                    ),

                    _build_divider(theme),

                    // Dompet
                    _build_info_row(
                      context,
                      icon: Icons.account_balance_wallet_rounded,
                      icon_color: AppColors.primary,
                      label: 'Dompet',
                      value: pocket_name,
                    ),

                    _build_divider(theme),

                    // Mata Uang
                    _build_info_row(
                      context,
                      icon: Icons.currency_exchange_rounded,
                      icon_color: AppColors.secondary,
                      label: 'Mata Uang',
                      value: pocket_currency,
                    ),

                    _build_divider(theme),

                    // Tanggal
                    _build_info_row(
                      context,
                      icon: Icons.calendar_today_rounded,
                      icon_color: AppColors.secondary,
                      label: 'Tanggal',
                      value: Formatters.format_date(tx.transaction_date),
                    ),

                    _build_divider(theme),

                    // Waktu
                    _build_info_row(
                      context,
                      icon: Icons.access_time_rounded,
                      icon_color: AppColors.secondary,
                      label: 'Waktu',
                      value: _format_time(tx.transaction_date),
                    ),

                    // Label (jika ada)
                    if (tx.label != null && tx.label!.isNotEmpty) ...[
                      _build_divider(theme),
                      _build_info_row(
                        context,
                        icon: Icons.person_rounded,
                        icon_color: AppColors.warning,
                        label: 'Label (Milik)',
                        value: tx.label!,
                        is_highlighted: true,
                      ),
                    ],

                    // Deskripsi (jika ada)
                    if (tx.description != null &&
                        tx.description!.isNotEmpty) ...[
                      _build_divider(theme),
                      _build_info_row(
                        context,
                        icon: Icons.notes_rounded,
                        icon_color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                        label: 'Deskripsi',
                        value: tx.description!,
                        is_multiline: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // === Metadata Card ===
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Info Tambahan',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        )),
                    const SizedBox(height: 8),
                    _build_meta_row(
                        theme, 'Dibuat', _format_datetime(tx.created_at)),
                    const SizedBox(height: 4),
                    _build_meta_row(theme, 'ID Transaksi',
                        tx.id.substring(0, 8).toUpperCase()),
                    if (tx.sync_status == 'pending') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Text('Belum tersinkronisasi',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                              )),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // === Tombol Hapus ===
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirm_delete(context, tx),
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Hapus Transaksi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expense,
                  side: const BorderSide(color: AppColors.expense),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Header dengan nominal besar, ikon kategori, dan badge tipe.
  Widget _build_amount_header(
    ThemeData theme,
    Transaction tx,
    bool is_income,
    Color color,
    Color cat_color,
  ) {
    return Column(
      children: [
        // Ikon kategori besar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cat_color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _get_icon(tx.category_icon ?? 'category'),
            color: cat_color,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),

        // Nominal besar
        Text(
          '${is_income ? '+' : '-'} ${Formatters.format_currency(tx.amount, tx.currency)}',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Badge tipe
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            is_income ? '↓ Pemasukan' : '↑ Pengeluaran',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  /// Baris info di detail card.
  Widget _build_info_row(
    BuildContext context, {
    required IconData icon,
    required Color icon_color,
    required String label,
    required String value,
    bool is_highlighted = false,
    bool is_multiline = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment:
            is_multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: icon_color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: icon_color, size: 18),
          ),
          const SizedBox(width: 14),

          // Label + Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    )),
                const SizedBox(height: 2),
                if (is_highlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: is_multiline ? 5 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build_divider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 66,
      color: theme.dividerColor.withValues(alpha: 0.3),
    );
  }

  Widget _build_meta_row(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  String _format_time(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _format_datetime(DateTime date) {
    return '${Formatters.format_date(date)} ${_format_time(date)}';
  }

  /// Dialog konfirmasi hapus transaksi.
  void _confirm_delete(BuildContext context, Transaction tx) {
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
              final success = await context
                  .read<TransactionProvider>()
                  .delete_transaction(tx);
              if (success && context.mounted) {
                context.read<PocketProvider>().load_pockets();
                Navigator.of(context).pop(true); // Kembali dgn result true
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
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
