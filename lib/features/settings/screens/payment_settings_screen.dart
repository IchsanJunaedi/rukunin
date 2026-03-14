import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme.dart';
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
          backgroundColor: AppColors.success,
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
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(paymentSettingsProvider);

    // Baca QRIS URL langsung dari provider — tidak perlu setState
    final existingQrisUrl = providerState.asData?.value?.qrisUrl;

    // Isi controller sekali saat data tersedia — TextEditingController
    // notifies sendiri, tidak butuh setState
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
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: Text('Rekening & Kas RW', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.grey800,
        elevation: 0,
      ),
      body: providerState.isLoading && !_isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                   _sectionLabel('Informasi Pembayaran (Transfer Bank)'),
                   const SizedBox(height: 8),
                   _card([
                     _textField(
                       ctrl: _bankNameCtrl,
                       label: 'Nama Bank (Contoh: BCA / Mandiri)',
                       icon: Icons.account_balance_outlined,
                       validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                     ),
                     const Divider(height: 1, indent: 52),
                     _textField(
                       ctrl: _accountNumberCtrl,
                       label: 'Nomor Rekening',
                       icon: Icons.numbers_outlined,
                       keyboardType: TextInputType.number,
                       validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                     ),
                     const Divider(height: 1, indent: 52),
                     _textField(
                       ctrl: _accountNameCtrl,
                       label: 'Atas Nama',
                       icon: Icons.person_outline,
                       validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                     ),
                   ]),
                   const SizedBox(height: 24),
                   
                   _sectionLabel('Atau Pakai QRIS Resmi'),
                   const SizedBox(height: 8),
                   _card([
                     Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('Upload Kode QRIS', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.grey800, fontWeight: FontWeight.w600)),
                           const SizedBox(height: 4),
                           Text('Gambar QRIS akan otomatis ditampilkan saat warga mau bayar secara mandiri dari aplikasi.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.grey600)),
                           const SizedBox(height: 16),
                           Center(
                             child: GestureDetector(
                               onTap: _pickImage,
                               child: Container(
                                 width: 200,
                                 height: 200,
                                 decoration: BoxDecoration(
                                   color: AppColors.grey100,
                                   borderRadius: BorderRadius.circular(16),
                                   border: Border.all(color: AppColors.grey300),
                                 ),
                                 child: ClipRRect(
                                   borderRadius: BorderRadius.circular(15),
                                   child: _qrisXFile != null
                                       ? (kIsWeb
                                           ? Image.network(
                                               _qrisXFile!.path,
                                               width: 200,
                                               height: 200,
                                               fit: BoxFit.contain,
                                               errorBuilder: (_, _, _) => _buildQrisPlaceholder(error: true),
                                             )
                                           : Image.file(
                                               File(_qrisXFile!.path),
                                               width: 200,
                                               height: 200,
                                               fit: BoxFit.contain,
                                               errorBuilder: (_, _, _) => _buildQrisPlaceholder(error: true),
                                             ))
                                       : existingQrisUrl != null
                                           ? CachedNetworkImage(
                                               imageUrl: existingQrisUrl,
                                               width: 200,
                                               height: 200,
                                               fit: BoxFit.contain,
                                               placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
                                               errorWidget: (_, _, _) => _buildQrisPlaceholder(error: true),
                                             )
                                           : _buildQrisPlaceholder(),
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Simpan Pengaturan', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildQrisPlaceholder({bool error = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          error ? Icons.broken_image_outlined : Icons.qr_code_2,
          size: 48,
          color: AppColors.grey400,
        ),
        const SizedBox(height: 8),
        Text(
          error ? 'Gagal memuat gambar' : 'Upload Gambar',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.grey500),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) => Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey600, letterSpacing: 0.5));

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _textField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.grey800),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.grey600),
          prefixIcon: Icon(icon, size: 18, color: AppColors.grey400),
          filled: true,
          fillColor: Colors.white,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      );
}
