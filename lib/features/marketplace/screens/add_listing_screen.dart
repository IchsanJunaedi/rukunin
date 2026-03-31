import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/marketplace_listing_model.dart';
import '../providers/marketplace_provider.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  /// Jika diisi, form akan masuk mode EDIT; jika null, mode CREATE
  final MarketplaceListingModel? existingListing;

  const AddListingScreen({super.key, this.existingListing});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  String _category = 'barang';
  final List<XFile> _pickedImages = [];
  /// URL gambar yang sudah ada (dari Supabase), hanya ada di mode edit
  List<String> _existingImageUrls = [];
  bool _loading = false;

  bool get _isEditMode => widget.existingListing != null;

  static const _categories = [
    ('makanan', '🍱 Makanan'),
    ('jasa', '🔧 Jasa'),
    ('barang', '📦 Barang'),
    ('tanaman', '🌿 Tanaman'),
    ('lainnya', '🛍️ Lainnya'),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill jika mode edit
    final existing = widget.existingListing;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _descCtrl.text = existing.description ?? '';
      _priceCtrl.text = existing.price != null && existing.price! > 0
          ? existing.price.toString()
          : '';
      _stockCtrl.text = existing.stock.toString();
      _category = existing.category;
      _existingImageUrls = List<String>.from(existing.images);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final totalImages = _existingImageUrls.length + _pickedImages.length;
    if (totalImages >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 3 foto')),
      );
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() => _pickedImages.add(file));
    }
  }

  Future<List<String>> _uploadImages(String communityId) async {
    final client = ref.read(supabaseClientProvider);
    final imageUrls = <String>[];
    for (final file in _pickedImages) {
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? 'image/jpeg';
      final ext = mime.split('/').last;
      final path =
          '$communityId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await client.storage
          .from('marketplace_images')
          .uploadBinary(path, bytes,
              fileOptions: FileOptions(contentType: mime));
      final url = client.storage
          .from('marketplace_images')
          .getPublicUrl(path);
      imageUrls.add(url);
    }
    return imageUrls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Tidak ada sesi login');

      final price = _priceCtrl.text.isNotEmpty
          ? int.tryParse(_priceCtrl.text.replaceAll('.', ''))
          : null;
      final stock = int.tryParse(_stockCtrl.text) ?? 1;

      if (_isEditMode) {
        // ── MODE EDIT ──
        final profile = await client
            .from('profiles')
            .select('community_id')
            .eq('id', userId)
            .maybeSingle();
        final communityId = profile?['community_id'] as String?;

        // Upload foto baru jika ada
        List<String>? newUrls;
        if (_pickedImages.isNotEmpty) {
          final uploaded = communityId != null
              ? await _uploadImages(communityId)
              : <String>[];
          newUrls = [..._existingImageUrls, ...uploaded];
        } else if (_existingImageUrls.length != widget.existingListing!.images.length) {
          // Foto lama ada yang dihapus
          newUrls = _existingImageUrls;
        }

        await ref.read(marketplaceServiceProvider).editListing(
              listingId: widget.existingListing!.id,
              title: _titleCtrl.text.trim(),
              category: _category,
              description: _descCtrl.text.trim().isNotEmpty
                  ? _descCtrl.text.trim()
                  : null,
              price: price,
              imageUrls: newUrls,
              stock: stock,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Iklan berhasil diperbarui! ✅'),
              backgroundColor: RukuninColors.success,
            ),
          );
          Navigator.of(context).pop(true); // return true → tanda berhasil edit
        }
      } else {
        // ── MODE CREATE ──
        final profile = await client
            .from('profiles')
            .select('community_id')
            .eq('id', userId)
            .maybeSingle();

        final communityId = profile?['community_id'] as String?;
        if (communityId == null) throw Exception('Community ID tidak ditemukan');

        final imageUrls =
            _pickedImages.isNotEmpty ? await _uploadImages(communityId) : <String>[];

        await ref.read(marketplaceServiceProvider).createListing(
              communityId: communityId,
              sellerId: userId,
              title: _titleCtrl.text.trim(),
              category: _category,
              description: _descCtrl.text.trim().isNotEmpty
                  ? _descCtrl.text.trim()
                  : null,
              price: price,
              imageUrls: imageUrls,
              stock: stock,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Listing berhasil dipasang! 🎉'),
              backgroundColor: RukuninColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: RukuninColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = _isEditMode;
    final totalImages = _existingImageUrls.length + _pickedImages.length;

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        foregroundColor: Colors.white,
        title: Text(
          isEdit ? 'Edit Iklan' : 'Pasang Iklan',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: RukuninColors.brandGreen, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(
                isEdit ? 'Simpan' : 'Pasang',
                style: GoogleFonts.poppins(
                    color: RukuninColors.brandGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Upload foto ──
            Text(
              'Foto Produk (maks. 3)',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Foto lama (dari edit mode)
                  ..._existingImageUrls.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(entry.value),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => setState(() =>
                                _existingImageUrls.removeAt(entry.key)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // Foto baru yang baru dipilih
                  ..._pickedImages.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(entry.value.path)
                                      as ImageProvider
                                  : FileImage(File(entry.value.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _pickedImages.removeAt(entry.key)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (totalImages < 3)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
                              style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 32, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                            const SizedBox(height: 4),
                            Text(
                              'Tambah Foto',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ── Judul ──
            _label(isDark, 'Judul Iklan'),
            const SizedBox(height: 8),
            _textField(
              isDark: isDark,
              controller: _titleCtrl,
              hint: 'Contoh: Nasi Goreng Bu Siti, Jasa Cuci Motor',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 18),
            // ── Kategori ──
            _label(isDark, 'Kategori'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final (val, label) = cat;
                final isSelected = _category == val;
                return GestureDetector(
                  onTap: () => setState(() => _category = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? RukuninColors.brandGreen : (isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? RukuninColors.brandGreen
                            : (isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            // ── Harga ──
            _label(isDark, 'Harga (kosongkan jika Gratis/Nego)'),
            const SizedBox(height: 8),
            _textField(
              isDark: isDark,
              controller: _priceCtrl,
              hint: 'Contoh: 25000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 18),
            // ── Stok ──
            _label(isDark, 'Stok'),
            const SizedBox(height: 8),
            _textField(
              isDark: isDark,
              controller: _stockCtrl,
              hint: 'Jumlah stok tersedia',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Stok wajib diisi';
                final n = int.tryParse(v);
                if (n == null || n < 0) return 'Stok harus angka ≥ 0';
                return null;
              },
            ),
            const SizedBox(height: 18),
            // ── Deskripsi ──
            _label(isDark, 'Deskripsi (opsional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ceritakan detail produk/jasa kamu...',
                hintStyle: GoogleFonts.poppins(
                    color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary, fontSize: 14),
                filled: true,
                fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.poppins(
                  fontSize: 14, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: Icon(
                  isEdit ? Icons.save_rounded : Icons.check_circle_rounded),
              label: Text(
                isEdit ? 'Simpan Perubahan' : 'Pasang Iklan Sekarang',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: RukuninColors.brandGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(bool isDark, String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
      );

  Widget _textField({
    required bool isDark,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary, fontSize: 14),
        filled: true,
        fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style:
          GoogleFonts.poppins(fontSize: 15, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
      validator: validator,
    );
  }
}
