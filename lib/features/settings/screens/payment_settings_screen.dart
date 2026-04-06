import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/tokens.dart';
import '../providers/payment_settings_provider.dart';

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  XFile? _qrisXFile;
  bool _isSaving = false;
  bool _dataLoaded = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) {
      setState(() => _qrisXFile = pickedFile);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      Uint8List? qrisBytes;
      String? qrisFileExt;
      if (_qrisXFile != null) {
        qrisBytes = await _qrisXFile!.readAsBytes();
        qrisFileExt = _qrisXFile!.path.split('.').last.toLowerCase();
        if (qrisFileExt.isEmpty || qrisFileExt == _qrisXFile!.path) qrisFileExt = 'jpg';
      }
      await ref.read(paymentSettingsProvider.notifier).updateSettings(
        bankName: _bankNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim(),
        qrisBytes: qrisBytes,
        qrisFileExt: qrisFileExt,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pengaturan rekening & QRIS berhasil disimpan.'),
          backgroundColor: RukuninColors.success,
        ));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/admin');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: RukuninColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final providerState = ref.watch(paymentSettingsProvider);
    final existingQrisUrl = providerState.asData?.value?.qrisUrl;

    ref.listen<AsyncValue<PaymentSettingsModel?>>(paymentSettingsProvider, (_, next) {
      if (_dataLoaded || _isSaving) return;
      next.whenData((settings) {
        if (settings == null) return;
        _dataLoaded = true;
        _bankNameCtrl.text = settings.bankName ?? '';
        _accountNumberCtrl.text = settings.accountNumber ?? '';
        _accountNameCtrl.text = settings.accountName ?? '';
      });
    });

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: Text('Rekening & Kas RW',
            style: RukuninFonts.pjs(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        foregroundColor: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
        elevation: 0,
      ),
      body: providerState.isLoading && !_isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _sectionLabel(context, 'Informasi Pembayaran (Transfer Bank)'),
                  const SizedBox(height: 8),
                  _card(context, [
                    _textField(context, ctrl: _bankNameCtrl, label: 'Nama Bank (Contoh: BCA / Mandiri)',
                        icon: Icons.account_balance_outlined,
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                    const Divider(height: 1, indent: 52),
                    _textField(context, ctrl: _accountNumberCtrl, label: 'Nomor Rekening',
                        icon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                    const Divider(height: 1, indent: 52),
                    _textField(context, ctrl: _accountNameCtrl, label: 'Atas Nama',
                        icon: Icons.person_outline,
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  ]),
                  const SizedBox(height: 24),

                  _sectionLabel(context, 'Atau Pakai QRIS Resmi'),
                  const SizedBox(height: 8),
                  _card(context, [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Upload Kode QRIS',
                              style: RukuninFonts.pjs(fontSize: 14,
                                  color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Gambar QRIS akan otomatis ditampilkan saat warga mau bayar secara mandiri dari aplikasi.',
                              style: RukuninFonts.pjs(fontSize: 12,
                                  color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: isDark ? RukuninColors.darkBg : RukuninColors.lightCardSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isDark ? null : RukuninShadow.card,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: _qrisXFile != null
                                      ? (kIsWeb
                                          ? Image.network(_qrisXFile!.path, width: 200, height: 200, fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) => _buildQrisPlaceholder(context))
                                          : Image.file(File(_qrisXFile!.path), width: 200, height: 200, fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) => _buildQrisPlaceholder(context)))
                                      : existingQrisUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: existingQrisUrl,
                                              width: 200, height: 200, fit: BoxFit.contain,
                                              placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
                                              errorWidget: (_, _, _) => _buildQrisPlaceholder(context, error: true))
                                          : _buildQrisPlaceholder(context),
                                ),
                              ),
                            ),
                          ),
                          if (_qrisXFile != null || existingQrisUrl != null) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Ganti Gambar'),
                              ),
                            ),
                          ]
                        ],
                      ),
                    )
                  ]),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RukuninColors.brandGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Simpan Pengaturan',
                            style: RukuninFonts.pjs(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildQrisPlaceholder(BuildContext context, {bool error = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          error ? Icons.broken_image_outlined : Icons.qr_code_2,
          size: 48,
          color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
        ),
        const SizedBox(height: 8),
        Text(
          error ? 'Gagal memuat gambar' : 'Upload Gambar',
          style: RukuninFonts.pjs(
              fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(label, style: RukuninFonts.pjs(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
        letterSpacing: 0.5));
  }

  Widget _card(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _textField(BuildContext context, {
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: RukuninFonts.pjs(fontSize: 14,
          color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: RukuninFonts.pjs(fontSize: 13,
            color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
        prefixIcon: Icon(icon, size: 18,
            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
        filled: true,
        fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
    );
  }
}
