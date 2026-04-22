import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/tokens.dart';
import '../models/register_step1_data.dart';
import '../providers/register_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';



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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1F13) : const Color(0xFFE8F5E9),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 64, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: RukuninColors.brandGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Gabung\nWarga.',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: (MediaQuery.of(context).size.width * 0.135).clamp(32.0, 48.0),
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Minta kode komunitas dari admin RT/RW-mu, lalu daftar di sini.',
                      style: RukuninFonts.pjs(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthTextField(
                        controller: _codeCtrl,
                        hint: 'Kode Komunitas (6 huruf)',
                        icon: Icons.tag_rounded,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(6)],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Kode komunitas wajib diisi';
                          if (v.trim().length != 6) return 'Kode harus 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
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
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _phoneCtrl,
                        hint: 'Nomor HP (WhatsApp)',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [LengthLimitingTextInputFormatter(14)],
                        validator: (v) => v == null || v.trim().isEmpty ? 'No HP wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
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
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _passCtrl,
                        hint: 'Password (min. 6 karakter)',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePass,
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password wajib diisi';
                          if (v.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      AuthButton(
                        label: 'Lanjut',
                        isLoading: _loading,
                        onTap: () {
                           if (!_loading) _submit();
                        },
                      ),
                    ],
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

