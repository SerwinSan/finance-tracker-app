/// Halaman Beranda — tampilan utama setelah login.
/// Menampilkan ringkasan saldo, daftar pocket, dan transaksi terakhir.
/// Desain terinspirasi GoPay dengan bahasa semi-formal.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pocket_provider.dart';
import '../../widgets/pocket_card.dart';
import '../pocket/pocket_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load pockets saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PocketProvider>().load_pockets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth_provider = context.watch<AuthProvider>();
    final pocket_provider = context.watch<PocketProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => pocket_provider.load_pockets(),
          child: CustomScrollView(
            slivers: [
              // === Header Greeting ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat ${Formatters.get_greeting()}! 👋',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth_provider.display_name,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // === Total Saldo Card ===
              SliverToBoxAdapter(
                child: _build_total_balance_card(context, pocket_provider),
              ),

              // === Section Header: Dompet Kamu ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dompet Kamu',
                        style: theme.textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () => _show_create_pocket_form(context),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Tambah'),
                      ),
                    ],
                  ),
                ),
              ),

              // === Daftar Pocket ===
              if (pocket_provider.is_loading && pocket_provider.pockets.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (pocket_provider.pockets.isEmpty)
                SliverToBoxAdapter(child: _build_empty_state(context))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pocket = pocket_provider.pockets[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PocketCard(
                            pocket: pocket,
                            on_edit: () => _show_edit_pocket_form(context, pocket),
                            on_delete: () =>
                                _confirm_delete_pocket(context, pocket.id, pocket.name),
                          ),
                        );
                      },
                      childCount: pocket_provider.pockets.length,
                    ),
                  ),
                ),

              // Spacer bawah
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      // FAB untuk tambah pocket cepat
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => _show_create_pocket_form(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  /// Widget card total saldo.
  Widget _build_total_balance_card(
    BuildContext context,
    PocketProvider pocket_provider,
  ) {
    final theme = Theme.of(context);
    final totals = pocket_provider.total_balance_by_currency;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Saldo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          if (totals.isEmpty)
            Text(
              'Rp 0',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            ...totals.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    Formatters.format_currency(entry.value, entry.key),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '${pocket_provider.pockets.length} dompet aktif',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget empty state ketika belum ada pocket.
  Widget _build_empty_state(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.wallet_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada dompet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Yuk buat dompet pertamamu!\nMisalnya "Uang Pribadi" atau "Titipan Teman"',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _show_create_pocket_form(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Dompet'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan form buat pocket baru.
  void _show_create_pocket_form(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PocketFormScreen(),
      ),
    );
  }

  /// Tampilkan form edit pocket.
  void _show_edit_pocket_form(BuildContext context, pocket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PocketFormScreen(pocket: pocket),
      ),
    );
  }

  /// Dialog konfirmasi hapus pocket.
  void _confirm_delete_pocket(
    BuildContext context,
    String pocket_id,
    String pocket_name,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dompet?'),
        content: Text(
          'Dompet "$pocket_name" dan semua transaksi di dalamnya akan dihapus permanen. Yakin mau hapus?',
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
                  await context.read<PocketProvider>().delete_pocket(pocket_id);
              if (!success && context.mounted) {
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
}
