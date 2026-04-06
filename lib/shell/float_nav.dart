import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FLOATING SLIDING NAVBAR  — shared by Admin & Resident shell
//
//  Design:
//  • Floating pill, 20px side margin, adapts dark/light
//  • Sliding tinted capsule under active icon (AnimatedBuilder)
//  • All icons = RukuninColors.brandGreen, inactive = 30% opacity
//  • Icon scale 0.88 → 1.06 on activate (Curves.easeOutBack)
//  • HapticFeedback.selectionClick() on every tap
// ─────────────────────────────────────────────────────────────────────────────

class NavTabDef {
  final IconData icon;
  final IconData iconFilled;

  const NavTabDef(this.icon, this.iconFilled);
}

class FloatingNavBar extends StatefulWidget {
  final List<NavTabDef> tabs;
  final int current;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.tabs,
    required this.current,
    required this.onTap,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    // Start at correct position without animating on first build
    _slideAnim = AlwaysStoppedAnimation(widget.current.toDouble());
  }

  @override
  void didUpdateWidget(FloatingNavBar old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) {
      final from = _slideAnim.value;
      _slideAnim = Tween<double>(
        begin: from,
        end: widget.current.toDouble(),
      ).animate(CurvedAnimation(
        parent: _slideCtrl,
        curve: Curves.easeInOutCubic,
      ));
      _slideCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final bg = isDark ? RukuninColors.darkSurface : RukuninColors.lightCardSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 14),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final itemW = totalW / widget.tabs.length;
              // Indicator: 8px inset on each side of the item slot
              const inset = 7.0;
              final indicatorW = itemW - (inset * 2);

              return AnimatedBuilder(
                animation: _slideAnim,
                builder: (context, _) {
                  final left = _slideAnim.value * itemW + inset;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // ── Sliding tinted capsule ───────────────
                      Positioned(
                        left: left,
                        top: 8,
                        width: indicatorW,
                        height: 46,
                        child: Container(
                          decoration: BoxDecoration(
                            color: RukuninColors.brandGreen
                                .withValues(alpha: isDark ? 0.15 : 0.09),
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),

                      // ── Icons row ────────────────────────────
                      Row(
                        children: List.generate(widget.tabs.length, (i) {
                          return Expanded(
                            child: _NavIcon(
                              tab: widget.tabs[i],
                              isActive: widget.current == i,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.onTap(i);
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Single icon with scale + opacity animation
// ─────────────────────────────────────────────────────────────────────────────

class _NavIcon extends StatefulWidget {
  final NavTabDef tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _scale   = Tween<double>(begin: 0.82, end: 1.08).animate(curve);
    _opacity = Tween<double>(begin: 0.28, end: 1.00)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.isActive) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_NavIcon old) {
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
      child: SizedBox(
        height: 62,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Center(
              child: Transform.scale(
                scale: _scale.value,
                child: Icon(
                  widget.isActive ? widget.tab.iconFilled : widget.tab.icon,
                  size: 22,
                  color: RukuninColors.brandGreen
                      .withValues(alpha: _opacity.value),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
