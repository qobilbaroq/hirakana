import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../learn/learn_screen.dart';
import '../practice/practice_screen.dart';
import '../progress/progress_screen.dart';

/// Satu Scaffold dengan bottom navigation 4 tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Dibuat sebagai notifier (bukan listener pada NavigationBar) supaya
  /// halaman di dalam IndexedStack tahu tab mana yang sedang tampil.
  /// PracticeScreen butuh ini untuk menghitung ulang jumlah kata setelah
  /// pengguna mengubah huruf aktif.
  final ValueNotifier<int> _tabIndex = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          const LearnScreen(),
          PracticeScreen(tabIndex: _tabIndex),
          const ProgressScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          _tabIndex.value = i;
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.layers_outlined),
              selectedIcon: Icon(Icons.layers),
              label: 'Learn'),
          NavigationDestination(
              icon: Icon(Icons.edit_outlined),
              selectedIcon: Icon(Icons.edit),
              label: 'Practice'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Progress'),
        ],
      ),
    );
  }
}
