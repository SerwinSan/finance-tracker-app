/// Form buat / edit Pocket (Dompet Virtual).
/// Bisa digunakan untuk create (pocket = null) atau edit (pocket != null).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/models/pocket_model.dart';
import '../../../utils/validators.dart';
import '../../providers/pocket_provider.dart';

class PocketFormScreen extends StatefulWidget {
  final Pocket? pocket; // null = mode create, not null = mode edit

  const PocketFormScreen({super.key, this.pocket});

  @override
  State<PocketFormScreen> createState() => _PocketFormScreenState();
}

class _PocketFormScreenState extends State<PocketFormScreen> {
  final _form_key = GlobalKey<FormState>();
  late TextEditingController _name_controller;
  late String _selected_type;
  late String _selected_currency;
  late String _selected_color;
  late String _selected_icon;

  bool get _is_edit_mode => widget.pocket != null;

  // Pilihan warna (tanpa ungu/indigo)
  final List<Map<String, dynamic>> _color_options = [
    {'color': '#00897B', 'name': 'Teal'},
    {'color': '#1E88E5', 'name': 'Blue'},
    {'color': '#43A047', 'name': 'Green'},
    {'color': '#FF7043', 'name': 'Orange'},
    {'color': '#E53935', 'name': 'Red'},
    {'color': '#FFA726', 'name': 'Amber'},
    {'color': '#78909C', 'name': 'Grey'},
    {'color': '#26C6DA', 'name': 'Cyan'},
  ];

  // Pilihan ikon
  final List<Map<String, dynamic>> _icon_options = [
    {'icon': 'wallet', 'data': Icons.account_balance_wallet_rounded, 'name': 'Dompet'},
    {'icon': 'savings', 'data': Icons.savings_rounded, 'name': 'Tabungan'},
    {'icon': 'credit_card', 'data': Icons.credit_card_rounded, 'name': 'Kartu'},
    {'icon': 'money', 'data': Icons.money_rounded, 'name': 'Uang'},
    {'icon': 'people', 'data': Icons.people_rounded, 'name': 'Orang'},
    {'icon': 'handshake', 'data': Icons.handshake_rounded, 'name': 'Titipan'},
    {'icon': 'shopping_bag', 'data': Icons.shopping_bag_rounded, 'name': 'Belanja'},
    {'icon': 'business', 'data': Icons.business_rounded, 'name': 'Bisnis'},
  ];

  @override
  void initState() {
    super.initState();
    _name_controller = TextEditingController(text: widget.pocket?.name ?? '');
    _selected_type = widget.pocket?.type ?? 'personal';
    _selected_currency = widget.pocket?.currency ?? 'IDR';
    _selected_color = widget.pocket?.color ?? '#00897B';
    _selected_icon = widget.pocket?.icon ?? 'wallet';
  }

  @override
  void dispose() {
    _name_controller.dispose();
    super.dispose();
  }

  /// Simpan pocket (create atau update).
  Future<void> _handle_save() async {
    if (!_form_key.currentState!.validate()) return;

    final pocket_provider = context.read<PocketProvider>();
    bool success;

    if (_is_edit_mode) {
      // Update pocket yang ada
      final updated = widget.pocket!.copy_with(
        name: _name_controller.text.trim(),
        type: _selected_type,
        currency: _selected_currency,
        color: _selected_color,
        icon: _selected_icon,
      );
      success = await pocket_provider.update_pocket(updated);
    } else {
      // Buat pocket baru
      success = await pocket_provider.create_pocket(
        name: _name_controller.text.trim(),
        type: _selected_type,
        currency: _selected_currency,
        color: _selected_color,
        icon: _selected_icon,
      );
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _is_edit_mode ? 'Dompet berhasil diupdate! ✅' : 'Dompet berhasil dibuat! 🎉',
            ),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pocket_provider.error_message ?? 'Gagal menyimpan dompet'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pocket_provider = context.watch<PocketProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_is_edit_mode ? 'Edit Dompet' : 'Buat Dompet Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form_key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Nama Pocket ===
              TextFormField(
                controller: _name_controller,
                textCapitalization: TextCapitalization.words,
                validator: Validators.validate_name,
                decoration: const InputDecoration(
                  labelText: 'Nama Dompet',
                  hintText: 'Contoh: Uang Pribadi, Titipan Budi',
                  prefixIcon: Icon(Icons.wallet_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // === Tipe Pocket ===
              Text('Tipe Dompet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _type_chip(
                      label: 'Pribadi',
                      icon: Icons.person_rounded,
                      value: 'personal',
                      is_selected: _selected_type == 'personal',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _type_chip(
                      label: 'Titipan',
                      icon: Icons.people_rounded,
                      value: 'entrusted',
                      is_selected: _selected_type == 'entrusted',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // === Mata Uang ===
              Text('Mata Uang', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _type_chip(
                      label: 'Rupiah (IDR)',
                      icon: Icons.attach_money_rounded,
                      value: 'IDR',
                      is_selected: _selected_currency == 'IDR',
                      on_tap: () => setState(() => _selected_currency = 'IDR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _type_chip(
                      label: 'Dollar (USD)',
                      icon: Icons.monetization_on_rounded,
                      value: 'USD',
                      is_selected: _selected_currency == 'USD',
                      on_tap: () => setState(() => _selected_currency = 'USD'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // === Warna ===
              Text('Warna', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _color_options.map((option) {
                  final color = Color(
                    int.parse(
                      (option['color'] as String).replaceFirst('#', '0xFF'),
                    ),
                  );
                  final is_selected = _selected_color == option['color'];
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selected_color = option['color'] as String,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: is_selected
                            ? Border.all(
                                color: theme.colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                        boxShadow: is_selected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: is_selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 22)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // === Ikon ===
              Text('Ikon', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icon_options.map((option) {
                  final is_selected = _selected_icon == option['icon'];
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selected_icon = option['icon'] as String,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: is_selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: is_selected
                            ? Border.all(
                                color: theme.colorScheme.primary, width: 2)
                            : Border.all(
                                color: theme.dividerColor, width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            option['data'] as IconData,
                            size: 22,
                            color: is_selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option['name'] as String,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: is_selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: is_selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // === Tombol Simpan ===
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: pocket_provider.is_loading ? null : _handle_save,
                  icon: pocket_provider.is_loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_is_edit_mode
                          ? Icons.save_rounded
                          : Icons.add_rounded),
                  label: Text(_is_edit_mode ? 'Simpan Perubahan' : 'Buat Dompet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget chip untuk pilihan tipe/currency.
  Widget _type_chip({
    required String label,
    required IconData icon,
    required String value,
    required bool is_selected,
    VoidCallback? on_tap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: on_tap ??
          () => setState(() => _selected_type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: is_selected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: is_selected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: is_selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: is_selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    is_selected ? FontWeight.w600 : FontWeight.normal,
                color: is_selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
