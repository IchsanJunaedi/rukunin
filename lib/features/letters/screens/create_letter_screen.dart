import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/tokens.dart';
import '../providers/letter_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/letter_pdf_generator.dart';
import '../../layanan/providers/layanan_provider.dart';

class CreateLetterScreen extends ConsumerStatefulWidget {
  const CreateLetterScreen({
    super.key,
    this.prefilledResidentId,
    this.prefilledLetterType,
    this.prefilledPurpose,
    this.fromRequestId,
  });

  /// Auto-set selected resident ID (used when linking to a letter request)
  final String? prefilledResidentId;

  /// Auto-set letter type dropdown value
  final String? prefilledLetterType;

  /// Auto-fill the purpose text field
  final String? prefilledPurpose;

  /// If not null, link the created letter to this letter_request id
  final String? fromRequestId;

  @override
  ConsumerState<CreateLetterScreen> createState() => _CreateLetterScreenState();
}

class _CreateLetterScreenState extends ConsumerState<CreateLetterScreen> {
  // ── Controllers ──────────────────────────────
  final _nameCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _ttlCtrl = TextEditingController(); // Format: Kota, DD-MM-YYYY
  final _occupationCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  // ── Dropdown values ───────────────────────────
  String? _gender;
  String? _religion;
  String? _marital;

  // ── State ─────────────────────────────────────
  String _letterType = 'ktp_kk';
  String? _selectedResidentId;
  Map<String, dynamic>? _communityData;
  bool _loadingCommunity = true;
  bool _pdfReady = false;
  bool _savingLetter = false;

  static const _genderOptions = ['Laki-laki', 'Perempuan'];
  static const _religionOptions = ['Islam', 'Kristen Protestan', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'];
  static const _maritalOptions = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];

  @override
  void initState() {
    super.initState();
    _fetchCommunity();
    // Apply pre-filled values from caller
    if (widget.prefilledLetterType != null) {
      _letterType = widget.prefilledLetterType!;
    }
    if (widget.prefilledPurpose != null) {
      _purposeCtrl.text = widget.prefilledPurpose!;
    }
    if (widget.prefilledResidentId != null) {
      _selectedResidentId = widget.prefilledResidentId!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nikCtrl.dispose();
    _ttlCtrl.dispose();
    _occupationCtrl.dispose();
    _purposeCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ─────────────────────────────────────
  Future<void> _fetchCommunity() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await ref.read(currentProfileProvider.future);
      final communityId = profile?['community_id'];
      if (communityId == null) {
        setState(() => _loadingCommunity = false);
        return;
      }

      final res = await client
          .from('communities')
          .select('name, rw_number, kelurahan, kecamatan, kabupaten, province')
          .eq('id', communityId)
          .single();

      setState(() {
        _communityData = res;
        _loadingCommunity = false;
      });
    } catch (_) {
      setState(() => _loadingCommunity = false);
    }
  }

  // ── Template ──────────────────────────────────
  void _applyTemplate() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama lengkap terlebih dahulu')));
      return;
    }

    final c = _communityData ?? {};
    final rw = c['rw_number'] ?? '01';
    final kelurahan = c['kelurahan'] ?? '';
    final kecamatan = c['kecamatan'] ?? '';
    final kabupaten = c['kabupaten'] ?? '';

    // Hitung umur dari TTL jika format benar
    String age = '-';
    final ttlParts = _ttlCtrl.text.split(',');
    if (ttlParts.length >= 2) {
      try {
        final dateParts = ttlParts.last.trim().split('-');
        if (dateParts.length == 3) {
          final dob = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
          final a = DateTime.now().difference(dob).inDays ~/ 365;
          age = '$a tahun';
        }
      } catch (_) {}
    }

    final content = LetterPdfGenerator.getTemplate(
      letterType: _letterType,
      residentName: name,
      residentNik: _nikCtrl.text.trim().isEmpty ? '-' : _nikCtrl.text.trim(),
      residentAge: age,
      residentGender: _gender ?? '-',
      residentAddress: 'RW $rw, Kel. $kelurahan, Kec. $kecamatan, $kabupaten',
      rtNumber: '01',
      rwNumber: rw,
      village: kelurahan,
      district: kecamatan,
      city: kabupaten,
      purpose: _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
    );

    setState(() {
      _contentCtrl.text = content;
      _pdfReady = true;
    });
  }

  // ── Export PDF ────────────────────────────────
  Future<void> _exportPdf({required bool isShare}) async {
    if (!_pdfReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tekan "Terapkan ke Surat" terlebih dahulu')));
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          const SizedBox(width: 12),
          Text('Membuat PDF...', style: RukuninFonts.pjs()),
        ]),
        duration: const Duration(seconds: 2),
      ));

      final now = DateTime.now();
      final roman = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
      final c = _communityData ?? {};
      final rw = c['rw_number'] ?? '01';
      final letterNumber = '${now.millisecondsSinceEpoch % 1000}/RW-$rw/${roman[now.month - 1]}/${now.year}';

      // Hitung umur
      String age = '-';
      final ttlParts = _ttlCtrl.text.split(',');
      if (ttlParts.length >= 2) {
        try {
          final dp = ttlParts.last.trim().split('-');
          if (dp.length == 3) {
            final dob = DateTime(int.parse(dp[2]), int.parse(dp[1]), int.parse(dp[0]));
            age = '${DateTime.now().difference(dob).inDays ~/ 365} tahun';
          }
        } catch (_) {}
      }

      final bytes = await LetterPdfGenerator.generate(
        letterNumber: letterNumber,
        letterType: _letterType,
        generatedContent: _contentCtrl.text,
        resident: {
          'full_name': _nameCtrl.text.trim(),
          'nik': _nikCtrl.text.trim().isEmpty ? '-' : _nikCtrl.text.trim(),
          'gender': _gender ?? '-',
          'date_of_birth': '',
          'place_of_birth': ttlParts.isNotEmpty ? ttlParts.first.trim() : '-',
          'religion': _religion ?? '-',
          'marital_status': _marital ?? '-',
          'occupation': _occupationCtrl.text.trim().isEmpty ? '-' : _occupationCtrl.text.trim(),
          'age': age,
        },
        community: {
          'name': c['name'] ?? 'RW',
          'rt_number': '01',
          'rw_number': rw,
          'village': c['kelurahan'] ?? '',
          'district': c['kecamatan'] ?? '',
          'city': c['kabupaten'] ?? '',
          'province': c['province'] ?? '',
          'leader_name': 'Ketua RW',
        },
      );

      final safeName = _nameCtrl.text.trim().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      final typeLabel = (letterTypeLabels[_letterType] ?? 'Surat').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = 'Surat_${typeLabel}_$safeName';

      if (isShare) {
        final tmp = File('${Directory.systemTemp.path}/$fileName.pdf');
        await tmp.writeAsBytes(bytes);
        if (mounted) {
          await SharePlus.instance.share(ShareParams(files: [XFile(tmp.path, mimeType: 'application/pdf', name: '$fileName.pdf')]));
        }
      } else {
        await FileSaver.instance.saveFile(name: '$fileName.pdf', bytes: bytes, mimeType: MimeType.pdf);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text('PDF berhasil disimpan!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
      }
    }
  }

  // ── Save letter & link to request ─────────────
  Future<void> _saveLetterAndLinkRequest() async {
    if (!_pdfReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tekan "Terapkan ke Surat" terlebih dahulu')));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap wajib diisi')));
      return;
    }

    setState(() => _savingLetter = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await ref.read(currentProfileProvider.future);
      final communityId = profile?['community_id'] as String?;
      if (communityId == null) throw Exception('Community ID tidak ditemukan');

      final now = DateTime.now();
      final roman = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
      final c = _communityData ?? {};
      final rw = c['rw_number'] ?? '01';
      final letterNumber = '${now.millisecondsSinceEpoch % 1000}/RW-$rw/${roman[now.month - 1]}/${now.year}';

      // Determine resident id: use prefilled or fall back to current user
      final residentId = _selectedResidentId ?? client.auth.currentUser?.id;
      if (residentId == null) throw Exception('Resident ID tidak ditemukan');

      final inserted = await client.from('letters').insert({
        'community_id': communityId,
        'resident_id': residentId,
        'letter_type': _letterType,
        'letter_number': letterNumber,
        'purpose': _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
        'generated_content': _contentCtrl.text,
        'status': 'done',
      }).select('id').single();

      final letterId = inserted['id'] as String;

      if (widget.fromRequestId != null) {
        final service = ref.read(layananServiceProvider);
        await service.updateLetterRequestStatus(
          requestId: widget.fromRequestId!,
          residentId: residentId,
          communityId: communityId,
          newStatus: 'ready',
          letterId: letterId,
        );
      }

      ref.invalidate(lettersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Surat berhasil disimpan!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingLetter = false);
    }
  }

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: Text('Buat Surat Keterangan', style: RukuninFonts.pjs(fontWeight: FontWeight.w700)),
      ),
      body: _loadingCommunity
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Jenis Surat ────────────────────────
                  _card(
                    context: context,
                    icon: Icons.article,
                    title: 'Jenis Surat',
                    child: DropdownButtonFormField<String>(
                      initialValue: _letterType,
                      isExpanded: true,
                      decoration: _deco(context, 'Pilih jenis surat...'),
                      items: letterTypeLabels.entries.map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, style: RukuninFonts.pjs(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) => setState(() { _letterType = v!; _pdfReady = false; }),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Data Pemohon ───────────────────────
                  _card(
                    context: context,
                    icon: Icons.person,
                    title: 'Data Pemohon',
                    child: Column(children: [
                      _field(context, _nameCtrl, 'Nama Lengkap *'),
                      _nikField(context),
                      _field(context, _ttlCtrl, 'Tempat, Tanggal Lahir (contoh: Jakarta, 15-02-2004)'),
                      _dropdown(context, 'Jenis Kelamin', _genderOptions, _gender, (v) => setState(() => _gender = v)),
                      _dropdown(context, 'Agama', _religionOptions, _religion, (v) => setState(() => _religion = v)),
                      _dropdown(context, 'Status Perkawinan', _maritalOptions, _marital, (v) => setState(() => _marital = v)),
                      _field(context, _occupationCtrl, 'Pekerjaan'),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // ── Keperluan ──────────────────────────
                  _card(
                    context: context,
                    icon: Icons.notes,
                    title: 'Keperluan / Tujuan Surat (Opsional)',
                    child: _field(context, _purposeCtrl, 'Contoh: Untuk keperluan syarat pendaftaran beasiswa KIP Kuliah...', lines: 2),
                  ),
                  const SizedBox(height: 16),

                  // ── Tombol Terapkan ────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _applyTemplate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RukuninColors.brandGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.auto_fix_high, color: Colors.white, size: 20),
                      label: Text('Terapkan ke Surat', style: RukuninFonts.pjs(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Preview & Edit Isi Surat ───────────
                  if (_pdfReady) ...[
                    _card(
                      context: context,
                      icon: Icons.article_outlined,
                      title: 'Isi Surat (Bisa Diedit Manual)',
                      child: TextFormField(
                        controller: _contentCtrl,
                        maxLines: null,
                        style: RukuninFonts.pjs(fontSize: 13, height: 1.7),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => _exportPdf(isShare: true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RukuninColors.brandGreen,
                          side: const BorderSide(color: RukuninColors.brandGreen),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: Text('Bagikan', style: RukuninFonts.pjs(fontWeight: FontWeight.w600)),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () => _exportPdf(isShare: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RukuninColors.brandGreen,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.download, color: Colors.white, size: 18),
                        label: Text('Unduh PDF', style: RukuninFonts.pjs(color: Colors.white, fontWeight: FontWeight.w600)),
                      )),
                    ]),
                    if (widget.fromRequestId != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _savingLetter ? null : _saveLetterAndLinkRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _savingLetter
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                          label: Text(
                            _savingLetter ? 'Menyimpan...' : 'Simpan & Tandai Selesai',
                            style: RukuninFonts.pjs(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: RukuninColors.brandGreen.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: RukuninColors.brandGreen, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'Isi data pemohon lalu tekan "Terapkan ke Surat".',
                          style: RukuninFonts.pjs(fontSize: 13, color: RukuninColors.brandGreen),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  // ── Helper Widgets ────────────────────────────
  Widget _card({required BuildContext context, required IconData icon, required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: RukuninColors.brandGreen, size: 18),
          const SizedBox(width: 6),
          Text(title, style: RukuninFonts.pjs(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }

  Widget _field(BuildContext context, TextEditingController ctrl, String hint, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        style: RukuninFonts.pjs(fontSize: 13),
        decoration: _deco(context, hint),
      ),
    );
  }

  Widget _nikField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _nikCtrl,
        keyboardType: TextInputType.number,
        maxLength: 16,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: RukuninFonts.pjs(fontSize: 13),
        decoration: _deco(context, 'NIK (maks. 16 digit)').copyWith(counterText: ''),
      ),
    );
  }

  Widget _dropdown(BuildContext context, String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _deco(context, label),
        items: options.map((o) => DropdownMenuItem(
          value: o,
          child: Text(o, style: RukuninFonts.pjs(fontSize: 13)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _deco(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: RukuninFonts.pjs(fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
      filled: true,
      fillColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
