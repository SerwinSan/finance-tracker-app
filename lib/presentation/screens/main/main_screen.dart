/// MainScreen — halaman utama dengan bottom navigation.
/// 4 tab: Beranda, Transaksi, Analytics, Profil.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../config/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../transaction/transaction_list_screen.dart';
import '../analytics/analytics_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selected_index = 0;

  // Screens untuk setiap tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const TransactionListScreen(),
    const AnalyticsScreen(),
    const _ProfileScreen(),
  ];

  void _on_tab_tapped(int index) {
    setState(() {
      _selected_index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selected_index,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected_index,
        onTap: _on_tab_tapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}


/// Profil Screen — menampilkan info user, toggle tema, dan logout.
class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth_provider = context.watch<AuthProvider>();
    final theme_provider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // === Info User ===
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      auth_provider.display_name.isNotEmpty
                          ? auth_provider.display_name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth_provider.display_name,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth_provider.user?.email ?? '',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // === Settings ===
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_rounded),
                  title: const Text('Mode Gelap'),
                  subtitle: Text(theme_provider.is_dark_mode
                      ? 'Aktif'
                      : 'Nonaktif'),
                  value: theme_provider.is_dark_mode,
                  onChanged: (_) => theme_provider.toggle_theme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // === Logout ===
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _confirm_logout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.expense),
              label: const Text('Keluar',
                  style: TextStyle(color: AppColors.expense)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.expense),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm_logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu yakin mau keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
