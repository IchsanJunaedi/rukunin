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

const _kYellow = Color(0xFFFFC107);
const _kBlack = Color(0xFF0D0D0D);
const _kWhite = Color(0xFFFFFFFF);

class RegisterResidentStep2Screen extends ConsumerStatefulWidget {
  final RegisterStep1Data step1Data;
  const RegisterResidentStep2Screen({super.key, required this.step1Data});

  @override
  ConsumerState<RegisterResidentStep2Screen> createState() => _Step2State();
}

class _Step2State extends ConsumerState<RegisterResidentStep2Screen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nikCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();
  int? _selectedRt;
  bool _loading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nikCtrl.dispose();
    _unitCtrl.dispose();
    _blockCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(registerServiceProvider);
      await service.registerResident(
        communityId: widget.step1Data.communityId,
        fullName: widget.step1Data.fullName,
        phone: widget.step1Data.phone,
        email: widget.step1Data.email,
        password: widget.step1Data.password,
        nik: _nikCtrl.text.trim(),
        unitNumber: _unitCtrl.text.trim(),
        block: _blockCtrl.text.trim(),
        rtNumber: _selectedRt,
      );
      if (mounted) context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendaftar: $e'),
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _kYellow,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _kBlack.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: _kBlack, size: 20),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Info\nTambahan',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: (size.width * 0.115).clamp(28.0, 42.0),
                        fontWeight: FontWeight.w900,
                        color: _kBlack,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Blok dan No. RT wajib diisi.',
                      style: RukuninFonts.pjs(
                        fontSize: 13,
                        color: _kBlack.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
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
                decoration: const BoxDecoration(
                  color: _kBlack,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data ini membantu admin mengenal kamu.',
                        style: RukuninFonts.pjs(
                          color: _kWhite.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        controller: _nikCtrl,
                        hint: 'NIK (16 digit)',
                        icon: Icons.badge_rounded,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: _blockCtrl,
                        hint: 'Blok (contoh: A)',
                        icon: Icons.home_work_rounded,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [LengthLimitingTextInputFormatter(2)],
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Blok wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: _unitCtrl,
                        hint: 'No. Rumah / Unit',
                        icon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedRt,
                        dropdownColor: const Color(0xFF1A1A1A),
                        style: RukuninFonts.pjs(
                            color: _kWhite, fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Pilih No. RT',
                          hintStyle: RukuninFonts.pjs(
                            color: _kWhite.withValues(alpha: 0.3),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.location_on_rounded,
                              color: _kWhite.withValues(alpha: 0.35), size: 18),
                          filled: true,
                          fillColor: const Color(0xFF141414),
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
                          errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: _kWhite.withValues(alpha: 0.4)),
                        items: List.generate(
                          widget.step1Data.rtCount,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('RT ${i + 1}'),
                          ),
                        ),
                        onChanged: (v) => setState(() => _selectedRt = v),
                        validator: (v) => v == null ? 'No. RT wajib dipilih' : null,
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      AuthButton(
                        label: 'Daftar →',
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
