/// Halaman Saving Goals — daftar target + form buat/edit + kontribusi.
/// Tampilkan progress bar dan deadline, bisa contribute dari pocket.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/models/saving_goal_model.dart';
import '../../../utils/formatters.dart';
import '../../../utils/validators.dart';
import '../../providers/pocket_provider.dart';
import '../../providers/saving_goal_provider.dart';

class SavingGoalListScreen extends StatefulWidget {
  const SavingGoalListScreen({super.key});

  @override
  State<SavingGoalListScreen> createState() => _SavingGoalListScreenState();
}

class _SavingGoalListScreenState extends State<SavingGoalListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavingGoalProvider>().load_goals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SavingGoalProvider>();
    final active = provider.active_goals;
    final completed = provider.completed_goals;

    return Scaffold(
      appBar: AppBar(title: const Text('Target Tabungan')),
      body: RefreshIndicator(
        onRefresh: () => provider.load_goals(),
        child: provider.is_loading && provider.goals.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.goals.isEmpty
                ? _build_empty_state(theme)
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Active goals
                      if (active.isNotEmpty) ...[
                        Text('Sedang Berjalan 🎯',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ...active.map((g) => _build_goal_card(g, theme)),
                        const SizedBox(height: 20),
                      ],
                      // Completed goals
                      if (completed.isNotEmpty) ...[
                        Text('Sudah Tercapai 🎉',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ...completed.map((g) => _build_goal_card(g, theme)),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'saving_goal_fab',
        onPressed: () => _show_goal_form(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Target'),
      ),
    );
  }

  /// Card satu saving goal.
  Widget _build_goal_card(SavingGoal goal, ThemeData theme) {
    final color = _parse_color(goal.color);
    final progress = goal.progress;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _show_goal_actions(context, goal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: icon + name + menu
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      goal.is_completed
                          ? Icons.check_circle_rounded
                          : Icons.savings_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.name, style: theme.textTheme.titleMedium),
                        if (goal.deadline != null)
                          Text(
                            goal.is_overdue
                                ? '⚠️ Melewati tenggat!'
                                : 'Target: ${Formatters.format_date(goal.deadline!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: goal.is_overdue
                                  ? AppColors.expense
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Percentage badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: goal.is_completed
                          ? AppColors.income.withValues(alpha: 0.15)
                          : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${goal.progress_percentage}%',
                      style: TextStyle(
                        color: goal.is_completed ? AppColors.income : color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    goal.is_completed ? AppColors.income : color,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.format_currency(goal.current_amount, goal.currency),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Formatters.format_currency(goal.target_amount, goal.currency),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Actions sheet untuk goal: kontribusi, edit, hapus.
  void _show_goal_actions(BuildContext context, SavingGoal goal) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!goal.is_completed)
              ListTile(
                leading: const Icon(Icons.add_circle_rounded,
                    color: AppColors.income),
                title: const Text('Tambah Tabungan'),
                subtitle: const Text('Sisihkan uang dari dompet'),
                onTap: () {
                  Navigator.pop(ctx);
                  _show_contribute_dialog(context, goal);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Target'),
              onTap: () {
                Navigator.pop(ctx);
                _show_goal_form(context, goal: goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded,
                  color: AppColors.expense),
              title: const Text('Hapus Target',
                  style: TextStyle(color: AppColors.expense)),
              onTap: () {
                Navigator.pop(ctx);
                _confirm_delete(context, goal);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog kontribusi — pilih pocket + jumlah.
  void _show_contribute_dialog(BuildContext context, SavingGoal goal) {
    final amount_controller = TextEditingController();
    final note_controller = TextEditingController();
    String? selected_pocket_id;
    final pockets = context.read<PocketProvider>().pockets;

    if (pockets.isNotEmpty) {
      selected_pocket_id = pockets.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tambah Tabungan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sisa: ${Formatters.format_currency(goal.remaining, goal.currency)}'),
                const SizedBox(height: 16),
                // Pilih pocket
                DropdownButtonFormField<String>(
                  initialValue: selected_pocket_id,
                  decoration: const InputDecoration(
                    labelText: 'Dari Dompet',
                    prefixIcon: Icon(Icons.wallet_rounded),
                  ),
                  items: pockets.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} (${Formatters.format_currency(p.balance, p.currency)})'),
                      )).toList(),
                  onChanged: (v) => setState(() => selected_pocket_id = v),
                ),
                const SizedBox(height: 12),
                // Jumlah
                TextFormField(
                  controller: amount_controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.money_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                // Catatan
                TextFormField(
                  controller: note_controller,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(amount_controller.text) ?? 0;
                if (amount <= 0 || selected_pocket_id == null) return;

                Navigator.pop(ctx);

                final success = await context.read<SavingGoalProvider>().contribute(
                      goal_id: goal.id,
                      pocket_id: selected_pocket_id!,
                      amount: amount,
                      note: note_controller.text.trim().isEmpty
                          ? null
                          : note_controller.text.trim(),
                    );

                if (mounted) {
                  // Refresh pocket balances
                  context.read<PocketProvider>().load_pockets();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Tabungan berhasil ditambah! 💰'
                          : 'Gagal menambah tabungan'),
                      backgroundColor:
                          success ? AppColors.income : AppColors.expense,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Sisihkan'),
            ),
          ],
        ),
      ),
    );
  }

  /// Form buat/edit goal.
  void _show_goal_form(BuildContext context, {SavingGoal? goal}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SavingGoalFormScreen(goal: goal),
      ),
    ).then((_) {
      // Refresh setelah kembali
      if (mounted) {
        context.read<SavingGoalProvider>().load_goals();
      }
    });
  }

  /// Konfirmasi hapus goal.
  void _confirm_delete(BuildContext context, SavingGoal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Target?'),
        content: Text(
          'Target "${goal.name}" akan dihapus permanen beserta semua riwayat kontribusinya. Yakin mau hapus?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SavingGoalProvider>().delete_goal(goal.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _build_empty_state(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_rounded, size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Belum ada target', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Yuk buat target tabunganmu!\nMisalnya "Beli Part Sepeda" 🚲',
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _show_goal_form(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Target'),
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

// =================================================================
// FORM SCREEN — Buat / Edit Saving Goal
// =================================================================

class _SavingGoalFormScreen extends StatefulWidget {
  final SavingGoal? goal;
  const _SavingGoalFormScreen({this.goal});

  @override
  State<_SavingGoalFormScreen> createState() => _SavingGoalFormScreenState();
}

class _SavingGoalFormScreenState extends State<_SavingGoalFormScreen> {
  final _form_key = GlobalKey<FormState>();
  final _name_controller = TextEditingController();
  final _amount_controller = TextEditingController();

  DateTime? _deadline;
  bool _has_deadline = false;
  String _selected_color = '#FF7043';

  bool get _is_editing => widget.goal != null;

  // Pilihan warna untuk goal
  static const _color_options = [
    '#FF7043', '#42A5F5', '#66BB6A', '#FFA726',
    '#EF5350', '#AB47BC', '#26C6DA', '#EC407A',
  ];

  @override
  void initState() {
    super.initState();
    if (_is_editing) {
      _name_controller.text = widget.goal!.name;
      _amount_controller.text = widget.goal!.target_amount.toString();
      _deadline = widget.goal!.deadline;
      _has_deadline = widget.goal!.deadline != null;
      _selected_color = widget.goal!.color;
    }
  }

  @override
  void dispose() {
    _name_controller.dispose();
    _amount_controller.dispose();
    super.dispose();
  }

  Future<void> _handle_save() async {
    if (!_form_key.currentState!.validate()) return;

    final target = int.tryParse(_amount_controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (target <= 0) return;

    final provider = context.read<SavingGoalProvider>();
    bool success;

    if (_is_editing) {
      final updated = widget.goal!.copy_with(
        name: _name_controller.text.trim(),
        target_amount: target,
        deadline: _has_deadline ? _deadline : null,
        clear_deadline: !_has_deadline,
        color: _selected_color,
      );
      success = await provider.update_goal(updated);
    } else {
      success = await provider.create_goal(
        name: _name_controller.text.trim(),
        target_amount: target,
        deadline: _has_deadline ? _deadline : null,
        color: _selected_color,
      );
    }

    if (mounted && success) {
      Navigator.pop(context);
    }
  }

  Future<void> _pick_deadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SavingGoalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_is_editing ? 'Edit Target' : 'Buat Target Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form_key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama target
              TextFormField(
                controller: _name_controller,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validators.validate_required(v, 'Nama Target'),
                decoration: const InputDecoration(
                  labelText: 'Nama Target',
                  hintText: 'Contoh: Beli Part Sepeda',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Jumlah target
              TextFormField(
                controller: _amount_controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.validate_amount,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Target',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.money_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // Deadline toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tentukan Tenggat Waktu'),
                subtitle: const Text('Opsional — biar lebih semangat nabung!'),
                value: _has_deadline,
                onChanged: (v) => setState(() => _has_deadline = v),
              ),
              if (_has_deadline) ...[
                InkWell(
                  onTap: _pick_deadline,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                      labelText: 'Tanggal Tenggat',
                    ),
                    child: Text(
                      _deadline != null
                          ? Formatters.format_date(_deadline!)
                          : 'Pilih tanggal',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),

              // Warna
              Text('Warna', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _color_options.map((hex) {
                  final color = _parse_color(hex);
                  final is_selected = _selected_color == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selected_color = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: is_selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: is_selected
                            ? [BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                              )]
                            : null,
                      ),
                      child: is_selected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: provider.is_loading ? null : _handle_save,
                  icon: provider.is_loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_is_editing ? 'Simpan Perubahan' : 'Buat Target'),
                ),
              ),
            ],
          ),
        ),
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
