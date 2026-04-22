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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _success = false;
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
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).updatePassword(
          newPassword: _passwordController.text,
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
      ref.read(recoveryModeProvider.notifier).setRecovery(false);
      setState(() => _success = true);
    }
  }

  String _parseError(String error) {
    debugPrint('[ResetPassword] error: $error');
    if (error.contains('network')) return 'Tidak ada koneksi internet.';
    if (error.contains('same password')) return 'Password baru tidak boleh sama dengan yang lama.';
    if (error.contains('session')) return 'Sesi telah berakhir. Minta link reset ulang.';
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
                    // Logo pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kBlack,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.home_work_rounded,
                              color: _kYellow, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Rukunin',
                            style: RukuninFonts.pjs(
                              color: _kYellow,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      _success ? 'Password\nBerhasil\nDiubah!' : 'Buat\nPassword\nBaru.',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: (size.width * 0.135).clamp(32.0, 48.0),
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

            // === BOTTOM SECTION ===
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _kBlack,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
                child: _success ? _buildSuccessState() : _buildFormState(isLoading),
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
            'Masukkan password baru untuk akunmu.',
            style: RukuninFonts.pjs(
              color: _kWhite.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Password baru
          AuthTextField(
            controller: _passwordController,
            hint: 'Password baru',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: _kWhite.withValues(alpha: 0.4),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 6) return 'Minimal 6 karakter';
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Konfirmasi password
          AuthTextField(
            controller: _confirmController,
            hint: 'Konfirmasi password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: _kWhite.withValues(alpha: 0.4),
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
              if (v != _passwordController.text) return 'Password tidak cocok';
              return null;
            },
          ),

          const Spacer(),
          const SizedBox(height: 32),

          AuthButton(
            label: 'Simpan Password →',
            isLoading: isLoading,
            onTap: _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _kYellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: _kYellow, size: 28),
        ),

        const SizedBox(height: 24),

        Text(
          'Password kamu sudah diperbarui. Silakan login dengan password barumu.',
          style: RukuninFonts.pjs(
            color: _kWhite.withValues(alpha: 0.5),
            fontSize: 13,
            height: 1.6,
          ),
        ),

        const Spacer(),

        AuthButton(
          label: 'Masuk Sekarang →',
          isLoading: false,
          onTap: () => context.go('/login'),
        ),
      ],
    );
  }
}


