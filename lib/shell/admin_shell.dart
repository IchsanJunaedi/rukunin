import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'float_nav.dart';

// ─── Tab definitions ──────────────────────────────────────────────────────────
const _tabs = [
  NavTabDef(Icons.home_outlined,         Icons.home_rounded),
  NavTabDef(Icons.group_outlined,        Icons.group_rounded),
  NavTabDef(Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  NavTabDef(Icons.bar_chart_rounded,     Icons.bar_chart_rounded),
  NavTabDef(Icons.description_outlined,  Icons.description_rounded),
  NavTabDef(Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell>
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
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/admin/warga'))   return 1;
    if (loc.startsWith('/admin/tagihan')) return 2;
    if (loc.startsWith('/admin/laporan')) return 3;
    if (loc.startsWith('/admin/surat'))   return 4;
    if (loc.startsWith('/admin/ai'))      return 5;
    return 0;
  }

  void _navigate(BuildContext ctx, int i) {
    const paths = [
      '/admin',
      '/admin/warga',
      '/admin/tagihan',
      '/admin/laporan',
      '/admin/surat',
      '/admin/ai',
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
