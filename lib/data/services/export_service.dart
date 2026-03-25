/// Service Export — menghasilkan file CSV dan PDF dari data transaksi.
/// CSV: format spreadsheet, bisa dibuka di Excel/Google Sheets.
/// PDF: laporan bulanan yang rapi dengan summary dan tabel.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/transaction_model.dart';

class ExportService {
  ExportService._();

  // =========================================================
  // CSV EXPORT
  // =========================================================

  /// Escape satu cell CSV sesuai standar RFC 4180.
  /// Selalu wrap dalam kutip ganda untuk menghindari masalah encoding.
  static String _escape_csv_cell(String value) {
    // Ganti kutip ganda jadi dua kutip ganda (standar CSV)
    final escaped = value.replaceAll('"', '""');
    // Selalu wrap dalam kutip ganda supaya aman
    return '"$escaped"';
  }

  /// Export daftar transaksi ke file CSV.
  /// Menggunakan UTF-8 BOM supaya Excel bisa baca encoding dengan benar.
  static Future<File?> export_csv(List<Transaction> transactions) async {
    try {
      if (transactions.isEmpty) return null;

      // Header kolom
      final headers = [
        'Tanggal',
        'Tipe',
        'Kategori',
        'Jumlah',
        'Mata Uang',
        'Deskripsi',
        'Label',
        'Dompet ID',
      ];

      // Build CSV string dengan CRLF line endings (standar RFC 4180)
      final buffer = StringBuffer();

      // Tulis header
      buffer.write(headers.map(_escape_csv_cell).join(','));
      buffer.write('\r\n');

      // Tulis data
      final date_format = DateFormat('dd/MM/yyyy HH:mm');
      for (final tx in transactions) {
        final row = [
          date_format.format(tx.transaction_date),
          tx.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
          tx.category_name ?? '-',
          tx.amount.toString(),
          tx.currency,
          tx.description ?? '-',
          tx.label ?? '-',
          tx.pocket_id,
        ];
        buffer.write(row.map(_escape_csv_cell).join(','));
        buffer.write('\r\n');
      }

      // Simpan ke file dengan UTF-8 BOM
      // BOM (Byte Order Mark) diperlukan supaya Excel Android/Windows
      // mengenali encoding UTF-8 dan tidak mengacaukan karakter Indonesia.
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/transaksi_$timestamp.csv');

      // UTF-8 BOM = 0xEF, 0xBB, 0xBF
      final bom = [0xEF, 0xBB, 0xBF];
      final csv_bytes = utf8.encode(buffer.toString());
      await file.writeAsBytes([...bom, ...csv_bytes]);

      debugPrint('[ExportService] CSV exported: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('[ExportService] export_csv error: $e');
      return null;
    }
  }

  // =========================================================
  // PDF EXPORT
  // =========================================================

  /// Export laporan transaksi ke PDF yang rapi.
  static Future<File?> export_pdf(
    List<Transaction> transactions, {
    String title = 'Laporan Transaksi',
    String? period_label,
  }) async {
    try {
      if (transactions.isEmpty) return null;

      final pdf = pw.Document();
      final date_format = DateFormat('dd/MM/yyyy');
      final currency_format = NumberFormat('#,##0', 'id_ID');

      // Hitung summary
      final total_income = transactions
          .where((t) => t.is_income)
          .fold(0, (sum, t) => sum + t.amount);
      final total_expense = transactions
          .where((t) => t.is_expense)
          .fold(0, (sum, t) => sum + t.amount);
      final net = total_income - total_expense;

      // Bagi transaksi jadi chunks untuk pagination (max 25 per halaman)
      const rows_per_page = 25;
      final chunks = <List<Transaction>>[];
      for (int i = 0; i < transactions.length; i += rows_per_page) {
        final end = (i + rows_per_page > transactions.length)
            ? transactions.length
            : i + rows_per_page;
        chunks.add(transactions.sublist(i, end));
      }

      // Halaman pertama: summary + tabel awal
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _pdf_header(title, period_label),
          footer: (context) => _pdf_footer(context),
          build: (context) => [
            // Summary card
            _pdf_summary_card(total_income, total_expense, net, currency_format),
            pw.SizedBox(height: 20),

            // Tabel transaksi
            pw.Text('Detail Transaksi',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.SizedBox(height: 10),

            _pdf_transaction_table(transactions, date_format, currency_format),
          ],
        ),
      );

      // Simpan ke file
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/laporan_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      debugPrint('[ExportService] PDF exported: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('[ExportService] export_pdf error: $e');
      return null;
    }
  }

  /// Header PDF.
  static pw.Widget _pdf_header(String title, String? period_label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.Text('Finance Tracker App',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                )),
          ],
        ),
        if (period_label != null)
          pw.Text(period_label,
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              )),
        pw.Divider(),
        pw.SizedBox(height: 10),
      ],
    );
  }

  /// Footer PDF dengan page number.
  static pw.Widget _pdf_footer(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    );
  }

  /// Card summary: pemasukan, pengeluaran, selisih.
  static pw.Widget _pdf_summary_card(
    int income,
    int expense,
    int net,
    NumberFormat formatter,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _pdf_stat_column(
              'Pemasukan', 'Rp ${formatter.format(income)}', PdfColors.green700),
          _pdf_stat_column(
              'Pengeluaran', 'Rp ${formatter.format(expense)}', PdfColors.red700),
          _pdf_stat_column(
              'Selisih', 'Rp ${formatter.format(net)}',
              net >= 0 ? PdfColors.green700 : PdfColors.red700),
        ],
      ),
    );
  }

  /// Kolom stat individual.
  static pw.Widget _pdf_stat_column(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: color,
            )),
      ],
    );
  }

  /// Tabel transaksi PDF.
  static pw.Widget _pdf_transaction_table(
    List<Transaction> transactions,
    DateFormat date_format,
    NumberFormat currency_format,
  ) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerLeft,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(70),  // Tanggal
        1: const pw.FixedColumnWidth(70),  // Tipe
        2: const pw.FixedColumnWidth(90),  // Kategori
        3: const pw.FixedColumnWidth(90),  // Jumlah
        4: const pw.FlexColumnWidth(),     // Deskripsi
      },
      headers: ['Tanggal', 'Tipe', 'Kategori', 'Jumlah (Rp)', 'Keterangan'],
      data: transactions.map((tx) => [
        date_format.format(tx.transaction_date),
        tx.is_income ? 'Masuk' : 'Keluar',
        tx.category_name ?? '-',
        currency_format.format(tx.amount),
        tx.description ?? '-',
      ]).toList(),
    );
  }

  // =========================================================
  // SHARE HELPER
  // =========================================================

  /// Share file via share sheet sistem (WhatsApp, email, dll).
  static Future<void> share_file(File file, {String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: subject ?? 'Export Finance Tracker',
        ),
      );
    } catch (e) {
      debugPrint('[ExportService] share_file error: $e');
    }
  }
}
