import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/tokens.dart';
import '../providers/poll_provider.dart';

class CreatePollScreen extends ConsumerStatefulWidget {
  const CreatePollScreen({super.key});

  @override
  ConsumerState<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends ConsumerState<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _startsAt = DateTime.now();
  DateTime _endsAt = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final initial = isEnd ? _endsAt : _startsAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isEnd) {
        _endsAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      } else {
        _startsAt = DateTime(picked.year, picked.month, picked.day);
        if (_endsAt.isBefore(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(days: 7));
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endsAt.isBefore(_startsAt) || _endsAt.isAtSameMomentAs(_startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal berakhir harus setelah tanggal mulai')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(pollNotifierProvider.notifier).createPoll(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            startsAt: _startsAt,
            endsAt: _endsAt,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = DateFormat('dd MMM yyyy', 'id');

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Buat Polling Baru',
          style: RukuninFonts.pjs(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Pertanyaan Polling *',
                style: RukuninFonts.pjs(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              style: RukuninFonts.pjs(
                  color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
              decoration: InputDecoration(
                hintText: 'Contoh: Setuju naikkan iuran kebersihan?',
                hintStyle: RukuninFonts.pjs(
                    color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                filled: true,
                fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RukuninColors.brandGreen, width: 2),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Pertanyaan wajib diisi' : null,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text('Keterangan (opsional)',
                style: RukuninFonts.pjs(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              style: RukuninFonts.pjs(
                  color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
              decoration: InputDecoration(
                hintText: 'Tambahkan konteks atau penjelasan...',
                hintStyle: RukuninFonts.pjs(
                    color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                filled: true,
                fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RukuninColors.brandGreen, width: 2),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text('Pilihan Jawaban',
                style: RukuninFonts.pjs(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Polling ini menggunakan format Ya / Tidak',
                    style: RukuninFonts.pjs(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.thumb_up_rounded, size: 16, color: RukuninColors.brandGreen),
                              const SizedBox(width: 6),
                              Text('Ya',
                                  style: RukuninFonts.pjs(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: RukuninColors.brandGreen)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: RukuninColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: RukuninColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.thumb_down_rounded, size: 16, color: RukuninColors.error),
                              const SizedBox(width: 6),
                              Text('Tidak',
                                  style: RukuninFonts.pjs(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: RukuninColors.error)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Tanggal Mulai *',
                style: RukuninFonts.pjs(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
            const SizedBox(height: 6),
            _DateTile(
              label: fmt.format(_startsAt),
              isDark: isDark,
              onTap: () => _pickDate(isEnd: false),
            ),
            const SizedBox(height: 16),
            Text('Tanggal Berakhir *',
                style: RukuninFonts.pjs(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
            const SizedBox(height: 6),
            _DateTile(
              label: fmt.format(_endsAt),
              isDark: isDark,
              onTap: () => _pickDate(isEnd: true),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RukuninColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RukuninColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: RukuninColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: RukuninFonts.pjs(
                          fontSize: 12,
                          color: RukuninColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RukuninColors.brandGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Buat Polling',
                        style: RukuninFonts.pjs(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18, color: RukuninColors.brandGreen),
            const SizedBox(width: 12),
            Text(
              label,
              style: RukuninFonts.pjs(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
