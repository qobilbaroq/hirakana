import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/update/update_prompt.dart';
import '../../core/widgets/curved_nav_bar.dart';
import '../../data/repositories/kana_repository.dart';
import '../learn/learn_screen.dart';
import '../learn/session_controller.dart';
import '../learn/session_launcher.dart';
import '../onboarding/onboarding_screen.dart';
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
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    _pageOpacity = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
    );
    _pageOffset = Tween<Offset>(
      begin: const Offset(0, 0.012),
      end: Offset.zero,
    ).animate(_pageController);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Pengguna baru melihat onboarding dulu; cek pembaruan menyusul.
      await _maybeShowOnboarding();
      if (!mounted || _checkedForUpdate) return;
      _checkedForUpdate = true;
      checkForUpdateAndPrompt(context);
    });
  }

  /// Onboarding hanya tampil sekali. Pengguna lama (sudah pernah belajar)
  /// tidak perlu perkenalan, jadi langsung ditandai selesai.
  Future<void> _maybeShowOnboarding() async {
    final repo = KanaRepository.instance;
    if (await repo.getMeta('intro_done') != null) return;
    if (await repo.getMeta('onboarded') != null || await repo.hasStudied()) {
      await repo.setMeta('intro_done', '1');
      return;
    }
    if (!mounted) return;
    final result = await Navigator.of(context)
        .pushNamed<OnboardingResult>(AppRouter.onboarding);
    await repo.setMeta('intro_done', '1');
    // Supaya dialog "Welcome" lama di launchSession tidak muncul dua kali.
    await repo.setMeta('onboarded', '1');
    if (!mounted) return;
    if (result == OnboardingResult.start) {
      launchSession(
        context,
        mode: 'flashcard',
        args: const SessionArgs(type: 'hiragana'),
      );
    } else if (result == OnboardingResult.chooseLetters) {
      Navigator.pushNamed(
        context,
        AppRouter.chooseLetters,
        arguments: 'hiragana',
      );
    }
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
          // Dipisah dari bar navigasi supaya animasi pil tidak ikut digambar
          // ulang bersama halaman.
          child: RepaintBoundary(
            child: IndexedStack(index: _index, children: _pages),
          ),
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
