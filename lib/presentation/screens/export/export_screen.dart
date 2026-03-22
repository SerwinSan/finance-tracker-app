/// Halaman Export Data — pilih periode + format (CSV/PDF).
/// User bisa memilih range tanggal, format output, lalu export & share.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/services/export_service.dart';
import '../../../utils/formatters.dart';
import '../../providers/transaction_provider.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  // Filter periode
  DateTime _start_date = DateTime.now().subtract(const Duration(days: 30));
  DateTime _end_date = DateTime.now();

  // Format export
  String _format = 'csv'; // 'csv' | 'pdf'

  // Loading state
  bool _is_exporting = false;

  Future<void> _pick_date({required bool is_start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: is_start ? _start_date : _end_date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (is_start) {
          _start_date = picked;
          // Pastikan end_date tidak sebelum start_date
          if (_end_date.isBefore(_start_date)) {
            _end_date = _start_date;
          }
        } else {
          _end_date = picked;
        }
      });
    }
  }

  Future<void> _handle_export() async {
    setState(() => _is_exporting = true);

    try {
      // Ambil transaksi berdasarkan filter periode
      final all_transactions =
          context.read<TransactionProvider>().transactions;

      // Filter berdasarkan range tanggal
      final start = DateTime(_start_date.year, _start_date.month, _start_date.day);
      final end = DateTime(_end_date.year, _end_date.month, _end_date.day, 23, 59, 59);

      final filtered = all_transactions.where((tx) {
        return !tx.transaction_date.isBefore(start) &&
            !tx.transaction_date.isAfter(end);
      }).toList();

      if (filtered.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tidak ada transaksi di periode ini 🤔'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Export sesuai format
      File? result;
      final period_label =
          '${Formatters.format_date(_start_date)} - ${Formatters.format_date(_end_date)}';

      if (_format == 'csv') {
        result = await ExportService.export_csv(filtered);
      } else {
        result = await ExportService.export_pdf(
          filtered,
          title: 'Laporan Keuangan',
          period_label: 'Periode: $period_label',
        );
      }

      if (result != null && mounted) {
        _show_success_dialog(result);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal mengexport data 😓'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _is_exporting = false);
    }
  }

  /// Dialog sukses — bisa buka file atau share.
  void _show_success_dialog(File file) {
    final file_name = file.path.split(Platform.pathSeparator).last;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded,
            size: 48, color: AppColors.income),
        title: const Text('Export Berhasil! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('File berhasil disimpan:',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _format == 'csv'
                        ? Icons.table_chart_rounded
                        : Icons.picture_as_pdf_rounded,
                    color: _format == 'csv'
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(file_name,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Buka file
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              OpenFilex.open(file.path);
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Buka'),
          ),
          // Share
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ExportService.share_file(
                file,
                subject: 'Laporan Keuangan - Finance Tracker',
              );
            },
            icon: const Icon(Icons.share_rounded),
            label: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Ilustrasi ===
            Center(
              child: Column(
                children: [
                  Icon(Icons.file_download_rounded,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text('Unduh Riwayat Transaksi',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Pilih periode dan format yang kamu mau',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // === Section: Periode ===
            Text('📅 Periode', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                // Tanggal mulai
                Expanded(
                  child: InkWell(
                    onTap: () => _pick_date(is_start: true),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Dari',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: Text(Formatters.format_date(_start_date),
                          style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tanggal akhir
                Expanded(
                  child: InkWell(
                    onTap: () => _pick_date(is_start: false),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Sampai',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: Text(Formatters.format_date(_end_date),
                          style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ),
              ],
            ),

            // Quick period chips
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _period_chip('7 Hari', 7),
                _period_chip('30 Hari', 30),
                _period_chip('3 Bulan', 90),
                _period_chip('6 Bulan', 180),
                _period_chip('1 Tahun', 365),
              ],
            ),
            const SizedBox(height: 28),

            // === Section: Format ===
            Text('📄 Format File', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                // CSV option
                Expanded(
                  child: _format_option(
                    icon: Icons.table_chart_rounded,
                    label: 'CSV',
                    subtitle: 'Bisa dibuka di Excel',
                    value: 'csv',
                    color: AppColors.income,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                // PDF option
                Expanded(
                  child: _format_option(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF',
                    subtitle: 'Laporan siap cetak',
                    value: 'pdf',
                    color: AppColors.expense,
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // === Tombol Export ===
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _is_exporting ? null : _handle_export,
                icon: _is_exporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(_is_exporting ? 'Mengexport...' : 'Export Sekarang'),
              ),
            ),
            const SizedBox(height: 16),

            // Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'File akan disimpan di penyimpanan lokal. Kamu bisa langsung buka atau kirim via WhatsApp, Email, dll.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chip pilihan periode cepat.
  Widget _period_chip(String label, int days) {
    final is_active = DateTime.now()
            .difference(_start_date)
            .inDays
            .abs() ==
        days;

    return ActionChip(
      label: Text(label),
      backgroundColor: is_active
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      onPressed: () {
        setState(() {
          _end_date = DateTime.now();
          _start_date = _end_date.subtract(Duration(days: days));
        });
      },
    );
  }

  /// Card opsi format (CSV / PDF).
  Widget _format_option({
    required IconData icon,
    required String label,
    required String subtitle,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    final is_selected = _format == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _format = value),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: is_selected ? color : theme.colorScheme.outline,
                width: is_selected ? 2 : 1,
              ),
              color: is_selected
                  ? color.withValues(alpha: 0.08)
                  : null,
            ),
            child: Column(
              children: [
                Icon(icon, size: 36, color: is_selected ? color : null),
                const SizedBox(height: 8),
                Text(label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: is_selected ? color : null,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
