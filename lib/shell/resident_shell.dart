import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'float_nav.dart';

// ─── Tab definitions ──────────────────────────────────────────────────────────
const _tabs = [
  NavTabDef(Icons.home_outlined,         Icons.home_rounded),
  NavTabDef(Icons.campaign_outlined,     Icons.campaign_rounded),
  NavTabDef(Icons.article_outlined,      Icons.article_rounded),
  NavTabDef(Icons.storefront_outlined,   Icons.storefront_rounded),
  NavTabDef(Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  NavTabDef(Icons.person_outline,        Icons.person_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
class ResidentShell extends StatefulWidget {
  final Widget child;
  const ResidentShell({super.key, required this.child});

  @override
  State<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends State<ResidentShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<Offset>   _entrySlide;
  late Animation<double>   _entryFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 1.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/resident/pengumuman'))  return 1;
    if (loc.startsWith('/resident/layanan'))     return 2;
    if (loc.startsWith('/resident/marketplace')) return 3;
    if (loc.startsWith('/resident/tagihan'))     return 4;
    if (loc.startsWith('/resident/akun'))        return 5;
    return 0;
  }

  void _navigate(BuildContext ctx, int i) {
    const paths = [
      '/resident',
      '/resident/pengumuman',
      '/resident/layanan',
      '/resident/marketplace',
      '/resident/tagihan',
      '/resident/akun',
    ];
    ctx.go(paths[i]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: FloatingNavBar(
            tabs: _tabs,
            current: _currentIndex(context),
            onTap: (i) => _navigate(context, i),
          ),
        ),
      ),
    );
  }
}
