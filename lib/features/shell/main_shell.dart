import 'package:flutter/material.dart';

import '../../core/update/update_prompt.dart';
import '../../core/widgets/curved_nav_bar.dart';
import '../learn/learn_screen.dart';
import '../practice/practice_screen.dart';
import '../profile/profile_screen.dart';
import '../words/words_screen.dart';

/// Satu Scaffold dengan navigasi melengkung mengambang.
/// Body memakai [extendBody] supaya konten bisa bergulir di belakang navigasi.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  // Sekali per kali app dibuka, bukan tiap pindah tab.
  static bool _checkedForUpdate = false;

  late final List<Widget> _pages = [
    const LearnScreen(),
    const PracticeScreen(),
    const WordsScreen(),
    ProfileScreen(onOpenTab: _openTab),
  ];

  late final AnimationController _pageController;
  late final Animation<double> _pageOpacity;
  late final Animation<Offset> _pageOffset;

  void _openTab(int index) {
    if (!mounted || index == _index) return;
    setState(() => _index = index);
    _pageController.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1,
    );
    _pageOpacity = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOutCubic,
    );
    _pageOffset = Tween<Offset>(
      begin: const Offset(0, 0.018),
      end: Offset.zero,
    ).animate(_pageOpacity);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_checkedForUpdate) return;
      _checkedForUpdate = true;
      checkForUpdateAndPrompt(context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _pageOpacity,
        child: SlideTransition(
          position: _pageOffset,
          child: IndexedStack(index: _index, children: _pages),
        ),
      ),
      bottomNavigationBar: _FloatingNav(index: _index, onSelected: _openTab),
    );
  }
}

/// Navigasi bawah: busur melayang. Pil aktif memanjang ke tab tujuan lalu
/// kembali ke ukuran pil (lihat [CurvedNavBar]).
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const _items = [
    CurvedNavItem(label: 'Kana', glyph: 'あ'),
    CurvedNavItem(label: 'Practice', icon: Icons.grid_view_rounded),
    CurvedNavItem(label: 'Words', icon: Icons.menu_book_outlined),
    CurvedNavItem(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: CurvedNavBar(
          items: _items,
          currentIndex: index,
          onTap: onSelected,
        ),
      ),
    );
  }
}
