import 'package:flutter/material.dart';

class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showShadow;
  final double scaleDownFactor;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 16.0,
    this.showShadow = true,
    this.scaleDownFactor = 0.97,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Fallback colors from theme
    final defaultBg = isDark ? theme.colorScheme.surface : theme.cardColor;
    final bgColor = widget.backgroundColor ?? defaultBg;
    
    // Shadow colors
    final shadowColor = isDark 
        ? Colors.black.withValues(alpha: 0.3) 
        : Colors.black.withValues(alpha: 0.05);

    return AnimatedScale(
      scale: _scaleAnimation.value,
      duration: const Duration(milliseconds: 150),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.showShadow
                ? [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: _isHovered ? 12 : 8,
                      offset: const Offset(0, 4),
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onHover: (hovering) {
                setState(() => _isHovered = hovering);
              },
              highlightColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              splashColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(16.0),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
