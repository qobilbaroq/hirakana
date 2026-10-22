import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/update/update_prompt.dart';
import '../learn/learn_screen.dart';
import '../practice/practice_screen.dart';
import '../profile/profile_screen.dart';
import '../words/words_screen.dart';

/// Satu Scaffold dengan navigasi pill mengambang.
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

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const _items = [
    _NavItemData(label: 'Kana', glyph: 'あ'),
    _NavItemData(label: 'Practice', icon: Icons.grid_view_rounded),
    _NavItemData(label: 'Words', icon: Icons.menu_book_outlined),
    _NavItemData(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.line.withValues(alpha: 0.9),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark ? 0.32 : 0.10,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Center(
                    child: _NavButton(
                      item: _items[i],
                      selected: i == index,
                      onTap: () => onSelected(i),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.label, this.glyph, this.icon});

  final String label;
  final String? glyph;
  final IconData? icon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onActive : AppColors.muted;
    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: selected ? 54 : 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? AppColors.active : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Center(
                child: AnimatedScale(
                  scale: selected ? 1 : 0.94,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: item.glyph != null
                      ? Text(
                          item.glyph!,
                          style: TextStyle(
                            fontFamily: 'Noto Sans JP',
                            fontSize: 19,
                            height: 1,
                            fontWeight: FontWeight.w500,
                            color: fg,
                          ),
                        )
                      : Icon(item.icon, size: 20, color: fg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
