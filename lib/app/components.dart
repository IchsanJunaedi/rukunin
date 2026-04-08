import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';

import 'tokens.dart';

// ── 1. GRADIENT BUTTON ────────────────────────────────────────────────────────

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final double? width;
  final Widget? leadingIcon;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.height = 52,
    this.width,
    this.leadingIcon,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isLoading || onTap == null) ? null : () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: (isLoading || onTap == null) ? 0.6 : 1.0,
        child: Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            gradient: (isLoading || onTap == null)
                ? null
                : RukuninColors.brandGradient,
            color: (isLoading || onTap == null)
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: (isLoading || onTap == null) ? null : RukuninShadow.brand,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leadingIcon != null) ...[
                        leadingIcon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: RukuninFonts.pjs(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── 2. SURFACE CARD ──────────────────────────────────────────────────────────

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? accentColor;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? RukuninColors.darkSurface : RukuninColors.lightCardSurface;

    Widget card = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : RukuninShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (accentColor != null)
                Container(width: 3, color: accentColor),
              Expanded(
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ── 3. STATUS BADGE ──────────────────────────────────────────────────────────

enum BadgeStatus { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final bool small;

  const StatusBadge(this.label, {
    super.key,
    this.status = BadgeStatus.neutral,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final text = switch (status) {
      BadgeStatus.success => isDark ? RukuninColors.successTextDark : RukuninColors.successText,
      BadgeStatus.warning => isDark ? RukuninColors.warningTextDark : RukuninColors.warningText,
      BadgeStatus.error => isDark ? RukuninColors.errorTextDark : RukuninColors.errorText,
      BadgeStatus.info => isDark ? RukuninColors.infoTextDark : RukuninColors.infoText,
      BadgeStatus.neutral => isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
    };

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10,
          vertical: small ? 2 : 4),
      child: Text(
        label,
        style: RukuninFonts.pjs(
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

// ── 4. SHIMMER SKELETON ───────────────────────────────────────────────────────

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  const ShimmerBox.line({
    super.key,
    required this.width,
    this.height = 14,
    this.borderRadius = 4,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2;
    final shimmer = isDark ? const Color(0xFF252D3A) : const Color(0xFFE8ECF2);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.4, 0.6, 1.0],
              colors: [base, shimmer, shimmer, base],
              transform: _GradientTranslation(_anim.value),
            ),
          ),
        );
      },
    );
  }
}

class _GradientTranslation implements GradientTransform {
  final double dx;
  const _GradientTranslation(this.dx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * dx, 0, 0);
  }
}

class InvoiceCardSkeleton extends StatelessWidget {
  const InvoiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox.line(width: 120),
              ShimmerBox(width: 64, height: 22, borderRadius: 100),
            ],
          ),
          const SizedBox(height: 10),
          ShimmerBox.line(width: 160),
          const SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 1, borderRadius: 0),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox.line(width: 80),
              ShimmerBox.line(width: 60),
            ],
          ),
        ],
      ),
    );
  }
}

class ResidentCardSkeleton extends StatelessWidget {
  const ResidentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ShimmerBox(width: 46, height: 46, borderRadius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox.line(width: 140),
                const SizedBox(height: 6),
                ShimmerBox.line(width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. EMPTY STATE ────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSec = isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RukuninColors.brandGreen.withValues(alpha: 0.12),
                    RukuninColors.brandTeal.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 36, color: RukuninColors.brandGreen),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: RukuninFonts.pjs(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? RukuninColors.darkTextPrimary
                    : RukuninColors.lightTextPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: RukuninFonts.pjs(
                  fontSize: 14,
                  color: textSec,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 24),
              GradientButton(
                label: ctaLabel!,
                onTap: onCta,
                width: 200,
                height: 46,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 6. CUSTOM TOAST ───────────────────────────────────────────────────────────

enum ToastType { success, error, warning, info }

void showToast(BuildContext context, String message, {
  ToastType type = ToastType.success,
  Duration duration = const Duration(seconds: 2),
}) {
  HapticFeedback.lightImpact();

  final isDark = Theme.of(context).brightness == Brightness.dark;

  final (icon, bg, textColor) = switch (type) {
    ToastType.success => (
        Icons.check_circle_rounded,
        isDark ? const Color(0xFF0A2416) : const Color(0xFF00C853),
        Colors.white,
      ),
    ToastType.error => (
        Icons.error_rounded,
        isDark ? const Color(0xFF200A09) : const Color(0xFFFF3B30),
        Colors.white,
      ),
    ToastType.warning => (
        Icons.warning_rounded,
        isDark ? const Color(0xFF201500) : const Color(0xFFFFB300),
        isDark ? Colors.white : const Color(0xFF0D1117),
      ),
    ToastType.info => (
        Icons.info_rounded,
        isDark ? const Color(0xFF001B30) : const Color(0xFF0091EA),
        Colors.white,
      ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: RukuninShadow.lg,
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: RukuninFonts.pjs(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

// ── 7. SECTION HEADER ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPri = isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: RukuninFonts.pjs(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPri,
            letterSpacing: -0.3,
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: RukuninFonts.pjs(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RukuninColors.brandGreen,
              ),
            ),
          ),
      ],
    );
  }
}

// ── 8. GRADIENT AVATAR ────────────────────────────────────────────────────────

class GradientAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final String? imageUrl;
  final double? borderRadius;

  const GradientAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.imageUrl,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? size * 0.3;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(br),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(br),
        ),
      );
    }
    return _placeholder(br);
  }

  Widget _placeholder(double br) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RukuninColors.brandGradient,
        borderRadius: BorderRadius.circular(br),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: RukuninFonts.pjs(
          color: Colors.white,
          fontSize: size * 0.33,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── 9. STAT CARD ──────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? accentColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconC = iconColor ?? RukuninColors.brandGreen;
    final textPri = isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary;
    final textSec = isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary;

    return SurfaceCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconC.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconC),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: RukuninFonts.pjs(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPri,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: RukuninFonts.pjs(
              fontSize: 12,
              color: textSec,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 10. BOTTOM SHEET HANDLE ───────────────────────────────────────────────────

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

// ── 11. GRADIENT APPBAR ───────────────────────────────────────────────────────

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBack;

  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : 56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RukuninColors.brandGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: RukuninFonts.pjs(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: RukuninFonts.pjs(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

// ── 12. MENU TILE ──────────────────────────────────────────────────────────────

class MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;

  const MenuTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPri = isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary;
    final textSec = isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary;
    final borderColor = isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: RukuninFonts.pjs(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPri,
                          )),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: RukuninFonts.pjs(
                              fontSize: 12,
                              color: textSec,
                            )),
                    ],
                  ),
                ),
                trailing ??
                    Icon(Icons.chevron_right_rounded, size: 18, color: textSec),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 0.5, thickness: 0.5, indent: 52, color: borderColor),
      ],
    );
  }
}

// ── GLASS CARD ────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: RukuninShadow.interactiveGlow,
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    // Light mode: plain surface without blur
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: RukuninColors.lightCardSurface,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: RukuninShadow.card,
        ),
        child: child,
      ),
    );
  }
}

// ── LOTTIE SUCCESS DIALOG ─────────────────────────────────────────────────────

class LottieSuccessDialog extends StatefulWidget {
  final String message;
  const LottieSuccessDialog({super.key, required this.message});

  @override
  State<LottieSuccessDialog> createState() => _LottieSuccessDialogState();
}

class _LottieSuccessDialogState extends State<LottieSuccessDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Lottie.asset(
              'assets/lottie/payment_success.json',
              fit: BoxFit.contain,
              repeat: false,
              onLoaded: (comp) {
                Future.delayed(
                  comp.duration + const Duration(milliseconds: 400),
                  () {
                    if (context.mounted) Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: RukuninFonts.pjs(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
