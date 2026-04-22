import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/tokens.dart';
import '../providers/register_provider.dart';



class RegisterAdminScreen extends ConsumerStatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  ConsumerState<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends ConsumerState<RegisterAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminNameCtrl = TextEditingController(); // nama admin sendiri
  final _nameCtrl = TextEditingController();     // nama RT/RW
  final _rwCtrl = TextEditingController();
  final _rtCountCtrl = TextEditingController();  // jumlah RT dalam RW
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _adminNameCtrl.dispose();
    _nameCtrl.dispose();
    _rwCtrl.dispose();
    _rtCountCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(registerServiceProvider);
      final code = await service.registerAdmin(
        communityName: _nameCtrl.text.trim(),
        rwNumber: _rwCtrl.text.trim(),
        rtCount: int.parse(_rtCountCtrl.text.trim()),
        adminPhone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        adminFullName: _adminNameCtrl.text.trim(),
      );
      if (!mounted) return;
      await _showSuccessDialog(code);
      if (mounted) context.go('/admin');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendaftar: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showSuccessDialog(String code) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Komunitas Berhasil Dibuat! 🎉',
          style: RukuninFonts.pjs(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bagikan kode ini ke grup WA wargamu agar mereka bisa bergabung:',
              style: RukuninFonts.pjs(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                code,
                textAlign: TextAlign.center,
                style: GoogleFonts.ptMono(
                  color: RukuninColors.brandGreen,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kode disalin ke clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16, color: RukuninColors.brandGreen),
                label: Text(
                  'Salin Kode',
                  style: RukuninFonts.pjs(color: RukuninColors.brandGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Tutup & Lanjut',
              style: RukuninFonts.pjs(
                color: RukuninColors.brandGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
                      'Buat\nKomunitas.',
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
                      'Daftarkan lingkungan RT/RW-mu dan kelola dengan mudah dalam satu aplikasi.',
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
                      _DarkTextField(
                        controller: _adminNameCtrl,
                        hint: 'Nama Lengkap Kamu (contoh: Budi Santoso)',
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
                        controller: _nameCtrl,
                        hint: 'Nama RT/RW (contoh: RW 03 Bukit Indah)',
                        icon: Icons.home_work_rounded,
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama RT/RW wajib diisi' : null,
                      ),
                      const SizedBox(height: 10),
                      _DarkTextField(
                        controller: _rwCtrl,
                        hint: 'Nomor RW (contoh: 003)',
                        icon: Icons.tag_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nomor RW wajib diisi' : null,
                      ),
                      const SizedBox(height: 10),
                      _DarkTextField(
                        controller: _rtCountCtrl,
                        hint: 'Jumlah RT dalam RW ini (contoh: 5)',
                        icon: Icons.people_alt_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Jumlah RT wajib diisi';
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 1 || n > 20) return 'Jumlah RT harus antara 1–20';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      _DarkTextField(
                        controller: _phoneCtrl,
                        hint: 'No HP Admin (contoh: 08123456789)',
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
                      const SizedBox(height: 10),
                      _DarkTextField(
                        controller: _confirmPassCtrl,
                        hint: 'Konfirmasi Password',
                        icon: Icons.lock_rounded,
                        obscureText: true,
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        validator: (v) {
                          if (v != _passCtrl.text) return 'Password tidak sama';
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
                                    'Daftar & Buat Komunitas →',
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
