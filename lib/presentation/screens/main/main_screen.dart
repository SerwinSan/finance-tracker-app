/// MainScreen — halaman utama dengan bottom navigation.
/// 4 tab: Beranda, Transaksi, Analytics, Profil.
library;

import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selected_index = 0;

  // Placeholder screens untuk setiap tab (akan diganti di phase berikutnya)
  final List<Widget> _screens = [
    const _PlaceholderScreen(title: 'Beranda', icon: Icons.home_rounded),
    const _PlaceholderScreen(title: 'Transaksi', icon: Icons.receipt_long_rounded),
    const _PlaceholderScreen(title: 'Analytics', icon: Icons.bar_chart_rounded),
    const _PlaceholderScreen(title: 'Profil', icon: Icons.person_rounded),
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

/// Placeholder screen sementara untuk tab yang belum diimplementasi.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              '$title akan hadir segera!',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini sedang dalam pengembangan',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
