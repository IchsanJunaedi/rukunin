import 'package:flutter/material.dart';
import '../../../../app/tokens.dart';

class AuthButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 150),
       lowerBound: 0.97,
       upperBound: 1.0,
       value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (!widget.isLoading) _ctrl.reverse();
  }

  void _onTapUp(_) {
    if (!widget.isLoading) {
      _ctrl.forward();
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (!widget.isLoading) _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isLoading 
        ? RukuninColors.brandGreen.withValues(alpha: 0.6) 
        : (_isHovering ? RukuninColors.brandGreen.withValues(alpha: 0.9) : RukuninColors.brandGreen);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _ctrl,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : Text(
                      widget.label,
                      style: RukuninFonts.pjs(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
