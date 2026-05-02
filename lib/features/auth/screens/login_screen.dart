import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/tokens.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../../../app/components.dart' show showToast, ToastType;

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
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
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

  Widget _buildLeftBranding(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1F13) : const Color(0xFFE8F5E9),
        image: const DecorationImage(
          image: AssetImage('assets/images/pattern.png'), // placeholder
          fit: BoxFit.cover,
          opacity: 0.05,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RukuninColors.brandGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Rukunin',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: RukuninColors.brandGreen,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Selamat Datang\nKembali!',
            style: RukuninFonts.pjs(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aplikasi manajemen komunitas RT/RW yang modern, aman, dan mempermudah segala urusan warga dalam satu genggaman.',
            style: RukuninFonts.pjs(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security_rounded, color: RukuninColors.brandGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Aman & Terpercaya',
                  style: RukuninFonts.pjs(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isDark, bool isLoading, {bool isMobile = false}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.login_rounded, color: RukuninColors.brandGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Masuk ke Akun Anda',
                style: RukuninFonts.pjs(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Masukkan email dan password untuk melanjutkan.',
            style: RukuninFonts.pjs(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          AuthTextField(
            controller: _emailCtrl,
            hint: 'Email',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email wajib diisi';
              if (!v.contains('@')) return 'Format email tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 6) return 'Minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push('/forgot-password'),
              child: Text(
                'Lupa password?',
                style: RukuninFonts.pjs(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: RukuninColors.brandGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          AuthButton(
            label: 'Masuk →',
            isLoading: isLoading,
            onTap: _login,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Atau masuk sebagai',
                  style: RukuninFonts.pjs(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
            ],
          ),
          const SizedBox(height: 24),
          if (isMobile)
            Column(
              children: [
                _RegisterCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin RT/RW',
                  desc: 'Kelola data komunitas',
                  onTap: () => context.push('/register/admin'),
                  isMobile: true,
                ),
                const SizedBox(height: 12),
                _RegisterCard(
                  icon: Icons.people_outline_rounded,
                  title: 'Warga',
                  desc: 'Gabung ke lingkunganmu',
                  onTap: () => context.push('/register/resident'),
                  isMobile: true,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _RegisterCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin RT/RW',
                    desc: 'Kelola komunitas',
                    onTap: () => context.push('/register/admin'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegisterCard(
                    icon: Icons.people_outline_rounded,
                    title: 'Warga',
                    desc: 'Gabung lingkungan',
                    onTap: () => context.push('/register/resident'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: _buildLeftBranding(isDark),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 500),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 40),
                                    padding: const EdgeInsets.all(48),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: _buildFormContent(isDark, isLoading),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : Container(
                  color: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header hero style
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 64, 24, 80),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF0A1F13), const Color(0xFF121212)]
                                  : [const Color(0xFFE8F5E9), const Color(0xFFF9FAFB)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: RukuninColors.brandGreen,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Rukunin',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: RukuninColors.brandGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Selamat Datang',
                                style: RukuninFonts.pjs(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -1,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kelola urusan RT/RW jadi lebih mudah dalam satu sentuhan.',
                                style: RukuninFonts.pjs(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Overlapping Card Form
                        Container(
                          transform: Matrix4.translationValues(0, -40, 0),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _buildFormContent(isDark, isLoading, isMobile: true),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _RegisterCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  final bool isMobile;

  const _RegisterCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
    this.isMobile = false,
  });

  @override
  State<_RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<_RegisterCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovering ? -4 : 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? (_isHovering ? const Color(0xFF222222) : const Color(0xFF141414)) : (_isHovering ? Colors.white : const Color(0xFFF9FAFB)),
            border: Border.all(
              color: _isHovering ? RukuninColors.brandGreen.withValues(alpha: 0.5) : (isDark ? Colors.white10 : Colors.black12),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: widget.isMobile
              ? Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isHovering ? RukuninColors.brandGreen.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: _isHovering ? RukuninColors.brandGreen : (isDark ? Colors.white70 : Colors.black54),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: RukuninFonts.pjs(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.desc,
                            style: RukuninFonts.pjs(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isHovering ? RukuninColors.brandGreen.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: _isHovering ? RukuninColors.brandGreen : (isDark ? Colors.white70 : Colors.black54),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: RukuninFonts.pjs(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.desc,
                      textAlign: TextAlign.center,
                      style: RukuninFonts.pjs(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
