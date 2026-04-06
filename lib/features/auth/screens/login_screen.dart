import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../app/tokens.dart';
import '../../../app/components.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    final s = ref.read(authNotifierProvider);
    if (s.hasError && mounted) {
      showToast(context, _parseError(s.error.toString()),
          type: ToastType.error);
    }
  }

  String _parseError(String e) {
    if (e.contains('Invalid login credentials')) return 'Email atau password salah.';
    if (e.contains('network')) return 'Tidak ada koneksi internet.';
    return 'Terjadi kesalahan. Coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // ── Logo pill ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: RukuninColors.brandGradient,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home_work_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Rukunin',
                          style: RukuninFonts.pjs(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Headline ───────────────────────────────────────────
                  Text(
                    'Selamat\nDatang Kembali.',
                    style: RukuninFonts.pjs(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1.1,
                      color: isDark
                          ? RukuninColors.darkTextPrimary
                          : RukuninColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk ke akun komunitasmu.',
                    style: RukuninFonts.pjs(
                      fontSize: 15,
                      color: isDark
                          ? RukuninColors.darkTextSecondary
                          : RukuninColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Form ──────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _InputField(
                          controller: _emailCtrl,
                          hint: 'Email',
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email wajib diisi';
                            if (!v.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _InputField(
                          controller: _passCtrl,
                          hint: 'Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: isDark
                                  ? RukuninColors.darkTextTertiary
                                  : RukuninColors.lightTextTertiary,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password wajib diisi';
                            if (v.length < 6) return 'Minimal 6 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () =>
                                context.push('/forgot-password'),
                            child: Text(
                              'Lupa password?',
                              style: RukuninFonts.pjs(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: RukuninColors.brandGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          label: 'Masuk',
                          isLoading: isLoading,
                          onTap: _login,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Register options ───────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _RegisterOption(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Daftar sbg Admin RT/RW',
                          onTap: () => context.push('/register/admin'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RegisterOption(
                          icon: Icons.people_outline_rounded,
                          label: 'Gabung sbg Warga',
                          onTap: () =>
                              context.push('/register/resident'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final void Function(String)? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: RukuninFonts.pjs(
        fontSize: 15,
        color: isDark
            ? RukuninColors.darkTextPrimary
            : RukuninColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon,
            size: 18,
            color: isDark
                ? RukuninColors.darkTextTertiary
                : RukuninColors.lightTextTertiary),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _RegisterOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RegisterOption({
    required this.icon, required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? RukuninColors.darkSurface
              : RukuninColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: RukuninColors.brandGreen, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: RukuninFonts.pjs(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? RukuninColors.darkTextSecondary
                    : RukuninColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
