import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

const _kYellow = Color(0xFFFFC107);
const _kBlack = Color(0xFF0D0D0D);
const _kWhite = Color(0xFFFFFFFF);

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).sendPasswordReset(
          email: _emailController.text.trim(),
        );
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_parseError(authState.error.toString())),
          backgroundColor: _kBlack,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (!authState.hasError && mounted) {
      setState(() => _emailSent = true);
    }
  }

  String _parseError(String error) {
    if (error.contains('network')) return 'Tidak ada koneksi internet.';
    if (error.contains('rate limit')) return 'Terlalu banyak percobaan. Tunggu sebentar.';
    return 'Terjadi kesalahan. Coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kYellow,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // === TOP SECTION ===
            Expanded(
              flex: 4,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _kBlack.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: _kBlack,
                            size: 20,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        _emailSent ? 'Cek\nEmailmu.' : 'Lupa\nPassword?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: size.width * 0.14,
                          fontWeight: FontWeight.w900,
                          color: _kBlack,
                          height: 1.0,
                          letterSpacing: -2,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // === BOTTOM SECTION — Form / Confirmation ===
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _kBlack,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
                child: _emailSent ? _buildSentState() : _buildFormState(isLoading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masukkan emailmu, kami kirimkan link reset password.',
            style: GoogleFonts.plusJakartaSans(
              color: _kWhite.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          _DarkTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email wajib diisi';
              if (!v.contains('@')) return 'Format email tidak valid';
              return null;
            },
          ),

          const Spacer(),

          GestureDetector(
            onTap: isLoading ? null : _handleSubmit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 56,
              decoration: BoxDecoration(
                color: isLoading ? _kYellow.withValues(alpha: 0.6) : _kYellow,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _kBlack,
                        ),
                      )
                    : Text(
                        'Kirim Link Reset →',
                        style: GoogleFonts.plusJakartaSans(
                          color: _kBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon check
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _kYellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: _kYellow, size: 28),
        ),

        const SizedBox(height: 24),

        Text(
          'Link reset password sudah dikirim ke',
          style: GoogleFonts.plusJakartaSans(
            color: _kWhite.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          _emailController.text.trim(),
          style: GoogleFonts.plusJakartaSans(
            color: _kYellow,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Klik link di email tersebut untuk membuat password baru. Pastikan cek folder Spam jika tidak muncul.',
          style: GoogleFonts.plusJakartaSans(
            color: _kWhite.withValues(alpha: 0.4),
            fontSize: 13,
            height: 1.6,
          ),
        ),

        const Spacer(),

        // Kembali ke login
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _kYellow,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
                'Kembali ke Login',
                style: GoogleFonts.plusJakartaSans(
                  color: _kBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Kirim ulang
        GestureDetector(
          onTap: () => setState(() => _emailSent = false),
          child: Center(
            child: Text(
              'Tidak menerima email? Coba lagi',
              style: GoogleFonts.plusJakartaSans(
                color: _kWhite.withValues(alpha: 0.4),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: _kWhite.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.plusJakartaSans(
        color: _kWhite,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: _kWhite.withValues(alpha: 0.3),
          fontSize: 14,
        ),
        prefixIcon:
            Icon(icon, color: _kWhite.withValues(alpha: 0.35), size: 18),
        filled: true,
        fillColor: _kWhite.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _kWhite.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _kWhite.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kYellow, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
