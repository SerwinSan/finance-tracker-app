/// Form Transaksi — halaman untuk menambahkan pemasukan/pengeluaran.
/// User memilih pocket, kategori, jumlah, deskripsi, dan label.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../../utils/formatters.dart';
import '../../../utils/validators.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/transaction_provider.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen>
    with SingleTickerProviderStateMixin {
  final _form_key = GlobalKey<FormState>();
  final _amount_controller = TextEditingController();
  final _description_controller = TextEditingController();
  final _label_controller = TextEditingController();

  late TabController _tab_controller;
  String _selected_type = 'expense';
  String? _selected_pocket_id;
  String? _selected_category_id;
  DateTime _selected_date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab_controller = TabController(length: 2, vsync: this);
    _tab_controller.addListener(() {
      setState(() {
        _selected_type = _tab_controller.index == 0 ? 'expense' : 'income';
        _selected_category_id = null; // Reset kategori saat ganti tab
      });
    });

    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().load_categories();
      // Auto-select pocket pertama jika ada
      final pockets = context.read<PocketProvider>().pockets;
      if (pockets.isNotEmpty && _selected_pocket_id == null) {
        setState(() => _selected_pocket_id = pockets.first.id);
      }
    });
  }

  @override
  void dispose() {
    _tab_controller.dispose();
    _amount_controller.dispose();
    _description_controller.dispose();
    _label_controller.dispose();
    super.dispose();
  }

  /// Simpan transaksi.
  Future<void> _handle_save() async {
    if (!_form_key.currentState!.validate()) return;

    if (_selected_pocket_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu')),
      );
      return;
    }

    // Parse amount (hapus titik/koma dari formatter)
    final amount_text = _amount_controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(amount_text) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    final tx_provider = context.read<TransactionProvider>();
    final pocket_provider = context.read<PocketProvider>();

    final success = await tx_provider.create_transaction(
      pocket_id: _selected_pocket_id!,
      category_id: _selected_category_id,
      amount: amount,
      type: _selected_type,
      description: _description_controller.text.trim().isEmpty
          ? null
          : _description_controller.text.trim(),
      label: _label_controller.text.trim().isEmpty
          ? null
          : _label_controller.text.trim(),
      transaction_date: _selected_date,
    );

    if (mounted) {
      if (success) {
      if (!mounted) return;
        // Refresh pocket data agar saldo terupdate
        await pocket_provider.load_pockets();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selected_type == 'income'
                  ? 'Pemasukan berhasil dicatat! 💰'
                  : 'Pengeluaran berhasil dicatat! ✅',
            ),
            backgroundColor: _selected_type == 'income'
                ? AppColors.income
                : AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true); // Return true agar caller bisa refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tx_provider.error_message ?? 'Gagal menyimpan transaksi'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Pilih tanggal transaksi.
  Future<void> _pick_date() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected_date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selected_date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tx_provider = context.watch<TransactionProvider>();
    final pocket_provider = context.watch<PocketProvider>();
    final pockets = pocket_provider.pockets;

    // Kategori berdasarkan tab aktif
    final categories = _selected_type == 'expense'
        ? tx_provider.expense_categories
        : tx_provider.income_categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Transaksi'),
        bottom: TabBar(
          controller: _tab_controller,
          tabs: const [
            Tab(
              icon: Icon(Icons.arrow_downward_rounded),
              text: 'Pengeluaran',
            ),
            Tab(
              icon: Icon(Icons.arrow_upward_rounded),
              text: 'Pemasukan',
            ),
          ],
          indicatorColor: _selected_type == 'expense'
              ? AppColors.expense
              : AppColors.income,
          labelColor: _selected_type == 'expense'
              ? AppColors.expense
              : AppColors.income,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form_key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Jumlah ===
              Text('Jumlah', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount_controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _selected_type == 'expense'
                      ? AppColors.expense
                      : AppColors.income,
                ),
                validator: Validators.validate_amount,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _selected_type == 'expense'
                        ? AppColors.expense
                        : AppColors.income,
                  ),
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 24),

              // === Pilih Dompet ===
              Text('Dompet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (pockets.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Belum ada dompet. Buat dompet dulu ya!',
                        style: theme.textTheme.bodyMedium),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selected_pocket_id,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.wallet_rounded),
                  ),
                  items: pockets.map((pocket) {
                    return DropdownMenuItem(
                      value: pocket.id,
                      child: Text(
                        '${pocket.name} (${Formatters.format_currency(pocket.balance, pocket.currency)})',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selected_pocket_id = value),
                  validator: (value) => value == null ? 'Pilih dompet' : null,
                ),
              const SizedBox(height: 24),

              // === Pilih Kategori ===
              Text('Kategori', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (categories.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                _build_category_grid(categories),
              const SizedBox(height: 24),

              // === Tanggal ===
              Text('Tanggal', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pick_date,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(
                    Formatters.format_date(_selected_date),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // === Deskripsi (opsional) ===
              TextFormField(
                controller: _description_controller,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Contoh: Makan siang di warteg',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // === Label milik siapa (opsional) ===
              TextFormField(
                controller: _label_controller,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Label milik siapa (opsional)',
                  hintText: 'Contoh: Budi, Andi',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 32),

              // === Tombol Simpan ===
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: tx_provider.is_loading ? null : _handle_save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected_type == 'expense'
                        ? AppColors.expense
                        : AppColors.income,
                  ),
                  icon: tx_provider.is_loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_selected_type == 'expense'
                      ? 'Catat Pengeluaran'
                      : 'Catat Pemasukan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Grid pilihan kategori.
  Widget _build_category_grid(List<Category> categories) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final is_selected = _selected_category_id == cat.id;
        final color = _parse_color(cat.color);
        return GestureDetector(
          onTap: () => setState(() => _selected_category_id = cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: is_selected
                  ? color.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: is_selected ? color : Theme.of(context).dividerColor,
                width: is_selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_get_icon(cat.icon), size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: is_selected ? FontWeight.bold : FontWeight.normal,
                    color: is_selected
                        ? color
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
