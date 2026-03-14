import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────
//  WARNA
// ─────────────────────────────────────────
class _NC {
  static const Color navbarBg    = Color(0x38FFFFFF);
  static const Color navBorder   = Color(0x72FFFFFF);
  static const Color orb1        = Color(0xFFFFF9C4);
  static const Color orb2        = Color(0xFFFFD740);
  static const Color orb3        = Color(0xFFFFB300);
  static const Color iconActive  = Color(0xFFE65100);
  static const Color iconInactive= Color(0xB3FFFFFF); // white 70%
  static const Color dot         = Colors.white;
}

// ─────────────────────────────────────────
//  NAV ITEMS
// ─────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

const _kItems = [
  _NavItem('Beranda', Icons.home_rounded),
  _NavItem('Warga',   Icons.people_alt_rounded),
  _NavItem('Tagihan', Icons.receipt_long_rounded),
  _NavItem('Laporan', Icons.bar_chart_rounded),
  _NavItem('Surat',   Icons.description_rounded),
  _NavItem('AI',      Icons.auto_awesome_rounded),
];

// ─────────────────────────────────────────
//  GEOMETRY CONSTANTS
// ─────────────────────────────────────────
const double _kNavH    = 58.0;  // pill height
const double _kOrbD    = 44.0;  // orb diameter
const double _kOrbOvfl = 2.0;   // px orb floats above pill (subtle lift)
// Stack height = _kNavH + _kOrbOvfl = 60
// Pill sits at bottom:0, height:58 → top edge at y=2 in Stack
// Orb at top:0 → center-Y = 22 in Stack
// Icon center in tab column (no spacer, mainAxisCenter):
//   content ≈ 20+2+10+2+3 = 37 px → pad = (58-37)/2 ≈ 10.5
//   icon center in pill = 10.5 + 10 = 20.5 → in Stack = 2 + 20.5 = 22.5
// ✓ Orb center (22) vs icon center (22.5) → 0.5 px – negligible

// ─────────────────────────────────────────
//  ADMIN SHELL
// ─────────────────────────────────────────
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
      duration: const Duration(milliseconds: 550),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _entryFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  int _idx(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/admin/warga'))   return 1;
    if (loc.startsWith('/admin/tagihan')) return 2;
    if (loc.startsWith('/admin/laporan')) return 3;
    if (loc.startsWith('/admin/surat'))   return 4;
    if (loc.startsWith('/admin/ai'))      return 5;
    return 0;
  }

  void _go(BuildContext ctx, int i) {
    const paths = [
      '/admin', '/admin/warga', '/admin/tagihan',
      '/admin/laporan', '/admin/surat', '/admin/ai',
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
          child: _GlassNavbar(
            currentIndex: _idx(context),
            onTap: (i) => _go(context, i),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  GLASS NAVBAR  (StatefulWidget for smooth orb)
// ─────────────────────────────────────────
class _GlassNavbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _GlassNavbar({required this.currentIndex, required this.onTap});

  @override
  State<_GlassNavbar> createState() => _GlassNavbarState();
}

class _GlassNavbarState extends State<_GlassNavbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late Animation<double>   _orbAnim;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Start already at the correct position (no animation on first build)
    _orbAnim = AlwaysStoppedAnimation(widget.currentIndex.toDouble());
  }

  @override
  void didUpdateWidget(_GlassNavbar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      // Capture current animated position (mid-flight if user taps fast)
      final from = _orbAnim.value;
      final to   = widget.currentIndex.toDouble();
      _orbAnim = Tween<double>(begin: from, end: to).animate(
        CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOutCubic),
      );
      _orbCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomPad + 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalW   = constraints.maxWidth;
          final itemW    = totalW / _kItems.length;

          return SizedBox(
            height: _kNavH + _kOrbOvfl,
            child: AnimatedBuilder(
              animation: _orbAnim,
              builder: (context, _) {
                // Smooth fractional position — works mid-flight too
                final orbLeft = _orbAnim.value * itemW + (itemW - _kOrbD) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── 1. Frosted glass pill ─────────────────
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      height: _kNavH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _NC.navbarBg,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _NC.navBorder, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── 2. Yellow orb — rendered BELOW icons ──
                    Positioned(
                      left:   orbLeft,
                      top:    0,                 // 2px above pill = subtle float
                      width:  _kOrbD,
                      height: _kOrbD,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end:   Alignment.bottomRight,
                              colors: [_NC.orb1, _NC.orb2, _NC.orb3],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _NC.orb2.withValues(alpha: 0.55),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── 3. Tab icons/labels — ABOVE orb ──────
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      height: _kNavH,
                      child: Row(
                        children: List.generate(_kItems.length, (i) {
                          return Expanded(
                            child: _NavTabItem(
                              item:     _kItems[i],
                              isActive: widget.currentIndex == i,
                              onTap:    () => widget.onTap(i),
                            ),
                          );
                        }),
                      ),
                    ),

                    // ── 4. Shimmer gloss stripe ───────────────
                    Positioned(
                      left: 0, right: 0,
                      bottom: _kNavH - 22,
                      height: 22,
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft:  Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end:   Alignment.bottomCenter,
                                colors: [
                                  Color(0x40FFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
//  NAV TAB ITEM
// ─────────────────────────────────────────
class _NavTabItem extends StatefulWidget {
  final _NavItem  item;
  final bool      isActive;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTabItem> createState() => _NavTabItemState();
}

class _NavTabItemState extends State<_NavTabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Smooth color tween: inactive white-70% → active deep-orange
  late Animation<Color?> _iconColor;
  // Opacity for label
  late Animation<double>  _labelOpacity;
  // Scale for icon (no bounce — easeOutCubic only)
  late Animation<double>  _iconScale;
  // Dot scale
  late Animation<double>  _dotScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);

    _iconColor = ColorTween(
      begin: _NC.iconInactive,
      end:   _NC.iconActive,
    ).animate(curve);

    _labelOpacity = Tween<double>(begin: 0.55, end: 1.0).animate(curve);
    _iconScale    = Tween<double>(begin: 0.88, end: 1.12).animate(curve);
    _dotScale     = Tween<double>(begin: 0.0,  end: 1.0 ).animate(curve);

    if (widget.isActive) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_NavTabItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) {
      widget.isActive ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Transform.scale(
                scale: _iconScale.value,
                child: Icon(
                  widget.item.icon,
                  size: 20,
                  color: _iconColor.value,
                ),
              ),

              const SizedBox(height: 2),

              // Label
              Opacity(
                opacity: _labelOpacity.value,
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: widget.isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),

              const SizedBox(height: 2),

              // Active dot
              Transform.scale(
                scale: _dotScale.value,
                child: Container(
                  width: 3, height: 3,
                  decoration: const BoxDecoration(
                    color: _NC.dot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
