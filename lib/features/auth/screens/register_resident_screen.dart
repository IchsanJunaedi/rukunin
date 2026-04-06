import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/tokens.dart';
import '../models/register_step1_data.dart';
import '../providers/register_provider.dart';

const _kYellow = Color(0xFFFFC107);
const _kBlack = Color(0xFF0D0D0D);
const _kWhite = Color(0xFFFFFFFF);

class RegisterResidentScreen extends ConsumerStatefulWidget {
  const RegisterResidentScreen({super.key});

  @override
  ConsumerState<RegisterResidentScreen> createState() => _RegisterResidentScreenState();
}

class _RegisterResidentScreenState extends ConsumerState<RegisterResidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(registerServiceProvider);
      final community = await service.checkCommunityCode(_codeCtrl.text.trim());
      final step1Data = RegisterStep1Data(
        communityId: community.communityId,
        communityCode: _codeCtrl.text.trim().toUpperCase(),
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        rtCount: community.rtCount,
      );
      if (mounted) context.push('/register/resident/step2', extra: step1Data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kYellow,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          // Top section
          Expanded(
            flex: 3,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _kBlack.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: _kBlack, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Gabung\nKomunitas.',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: MediaQuery.of(context).size.width * 0.145,
                        fontWeight: FontWeight.w900,
                        color: _kBlack,
                        height: 1.05,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Minta kode komunitas dari admin RT/RW-mu, lalu daftar di sini.',
                      style: RukuninFonts.pjs(
                        fontSize: 13,
                        color: _kBlack.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Form section
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _kBlack,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kode komunitas — paling atas, prominent
                      TextFormField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(6)],
                        style: RukuninFonts.pjs(
                          color: _kYellow,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'KODE',
                          hintStyle: RukuninFonts.pjs(
                            color: _kYellow.withValues(alpha: 0.3),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 6,
                          ),
                          labelText: 'Kode Komunitas (6 huruf)',
                          labelStyle: RukuninFonts.pjs(
                            color: _kWhite.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: _kYellow.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Kode komunitas wajib diisi';
                          if (v.trim().length != 6) return 'Kode harus 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _DarkTextField(
                        controller: _nameCtrl,
                        hint: 'Nama Lengkap',
                        icon: Icons.person_rounded,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                          if (RegExp(r'[0-9]').hasMatch(v)) return 'Nama hanya boleh huruf';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      _DarkTextField(
                        controller: _phoneCtrl,
                        hint: 'Nomor HP (WhatsApp)',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [LengthLimitingTextInputFormatter(14)],
                        validator: (v) => v == null || v.trim().isEmpty ? 'No HP wajib diisi' : null,
                      ),
                      const SizedBox(height: 10),
                      _DarkTextField(
                        controller: _emailCtrl,
                        hint: 'Email',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email wajib diisi';
                          if (!v.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      _DarkTextField(
                        controller: _passCtrl,
                        hint: 'Password (min. 6 karakter)',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePass,
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: _kWhite.withValues(alpha: 0.4),
                          ),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password wajib diisi';
                          if (v.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      GestureDetector(
                        onTap: _loading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 56,
                          decoration: BoxDecoration(
                            color: _loading ? _kYellow.withValues(alpha: 0.6) : _kYellow,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: _kBlack),
                                  )
                                : Text(
                                    'Lanjut →',
                                    style: RukuninFonts.pjs(
                                      color: _kBlack,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      style: RukuninFonts.pjs(color: _kWhite, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: RukuninFonts.pjs(
          color: _kWhite.withValues(alpha: 0.3),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: _kWhite.withValues(alpha: 0.35), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _kWhite.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
