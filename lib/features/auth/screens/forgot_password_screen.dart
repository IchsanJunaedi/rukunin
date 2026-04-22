import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/tokens.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

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
    debugPrint('[ForgotPassword] error: $error');
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
        child: CustomScrollView(
          slivers: [
            // === TOP SECTION ===
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
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

                    const SizedBox(height: 32),

                    Text(
                      _emailSent ? 'Cek\nEmailmu.' : 'Lupa\nPassword?',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: (size.width * 0.14).clamp(32.0, 48.0),
                        fontWeight: FontWeight.w900,
                        color: _kBlack,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // === BOTTOM SECTION — Form / Confirmation ===
            SliverFillRemaining(
              hasScrollBody: false,
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
            style: RukuninFonts.pjs(
              color: _kWhite.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          AuthTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email wajib diisi';
              if (!v.contains('@')) return 'Format email tidak valid';
              return null;
            },
          ),

          const Spacer(),
          const SizedBox(height: 32),

          AuthButton(
            label: 'Kirim Link Reset →',
            isLoading: isLoading,
            onTap: _handleSubmit,
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
          style: RukuninFonts.pjs(
            color: _kWhite.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          _emailController.text.trim(),
          style: RukuninFonts.pjs(
            color: _kYellow,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Klik link di email tersebut untuk membuat password baru. Pastikan cek folder Spam jika tidak muncul.',
          style: RukuninFonts.pjs(
            color: _kWhite.withValues(alpha: 0.4),
            fontSize: 13,
            height: 1.6,
          ),
        ),

        const Spacer(),

        // Kembali ke login
        AuthButton(
          label: 'Kembali ke Login',
          isLoading: false,
          onTap: () => context.go('/login'),
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


