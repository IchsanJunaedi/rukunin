import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/tokens.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onSubmitted;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.inputFormatters,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Background color shifts gently when focused
    final bgColor = _isFocused 
        ? (isDark ? const Color(0xFF222222) : const Color(0xFFFFFFFF))
        : (isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB));

    // Icon and text colors
    final iconColor = _isFocused 
        ? RukuninColors.brandGreen 
        : (isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.35));

    final textColor = isDark ? Colors.white : Colors.black;

    // Glowing shadow + highlighted border for focused state
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: isDark ? Colors.transparent : const Color(0xFFE5E7EB),
        width: 1,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: RukuninColors.brandGreen,
        width: 1.5,
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          if (_isFocused) 
            BoxShadow(
              color: RukuninColors.brandGreen.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 2,
            ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        onFieldSubmitted: widget.onSubmitted,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        style: RukuninFonts.pjs(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: RukuninFonts.pjs(
            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
            fontSize: 14,
          ),
          prefixIcon: Icon(widget.icon, color: iconColor, size: 20),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: bgColor,
          border: defaultBorder,
          enabledBorder: defaultBorder,
          focusedBorder: focusedBorder,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
          ),
          errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
