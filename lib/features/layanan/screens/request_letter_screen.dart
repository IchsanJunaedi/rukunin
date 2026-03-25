import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/tokens.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/letter_request_model.dart';
import '../providers/layanan_provider.dart';

enum _Step { type, form, review }

class RequestLetterScreen extends ConsumerStatefulWidget {
  final String? initialType;
  const RequestLetterScreen({super.key, this.initialType});

  @override
  ConsumerState<RequestLetterScreen> createState() => _RequestLetterScreenState();
}

class _RequestLetterScreenState extends ConsumerState<RequestLetterScreen> {
  _Step _step = _Step.type;
  String? _selectedType;
  bool _loading = false;

  // Semua controller untuk semua field (lazy, hanya yang relevan dipakai)
  final _nikCtrl = TextEditingController();
  final _ttlCtrl = TextEditingController();
  final _keperluanCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  final _noKkCtrl = TextEditingController();
  final _pernyataanKondisiCtrl = TextEditingController();
  final _namaUsahaCtrl = TextEditingController();
  final _jenisUsahaCtrl = TextEditingController();
  final _alamatUsahaCtrl = TextEditingController();
  final _pekerjaanCtrl = TextEditingController();
  final _namaAyahCtrl = TextEditingController();
  final _namaIbuCtrl = TextEditingController();
  final _namaAlmarhumCtrl = TextEditingController();
  final _nikAlmarhumCtrl = TextEditingController();
  final _ttlAlmarhumCtrl = TextEditingController();
  final _penyebabCtrl = TextEditingController();

  String? _gender;
  String? _agama;
  String? _maritalStatus;
  String? _alasanKtpKk;
  String? _alasanSktm;
  String? _hubunganPelapor;
  String? _tanggalMeninggal;

  static const _genderOptions = ['Laki-laki', 'Perempuan'];
  static const _agamaOptions = ['Islam', 'Kristen Protestan', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'];
  static const _maritalOptions = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];
  static const _alasanKtpKkOptions = [
    'KTP baru', 'KTP hilang', 'KTP rusak', 'Perpanjangan KTP',
    'KK baru', 'Perbaikan data KK',
  ];
  static const _alasanSktmOptions = ['Pendidikan', 'Kesehatan / Pengobatan', 'Lainnya'];
  static const _hubunganPelaporOptions = ['Anak', 'Istri', 'Suami', 'Orang Tua', 'Saudara', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType;
      _step = _Step.form;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nikCtrl, _ttlCtrl, _keperluanCtrl, _keteranganCtrl, _noKkCtrl,
      _pernyataanKondisiCtrl, _namaUsahaCtrl, _jenisUsahaCtrl, _alamatUsahaCtrl,
      _pekerjaanCtrl, _namaAyahCtrl, _namaIbuCtrl, _namaAlmarhumCtrl,
      _nikAlmarhumCtrl, _ttlAlmarhumCtrl, _penyebabCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Build form_data dari semua controller sesuai jenis surat ──
  Map<String, dynamic> _buildFormData() {
    switch (_selectedType) {
      case 'domisili':
        return {'nik': _nikCtrl.text.trim(), 'ttl': _ttlCtrl.text.trim(), 'gender': _gender ?? '-', 'agama': _agama ?? '-', 'keperluan': _keperluanCtrl.text.trim()};
      case 'ktp_kk':
        return {'nik': _nikCtrl.text.trim(), 'alasan': _alasanKtpKk ?? '', 'keterangan': _keteranganCtrl.text.trim()};
      case 'skck':
        return {'nik': _nikCtrl.text.trim(), 'ttl': _ttlCtrl.text.trim(), 'gender': _gender ?? '-', 'agama': _agama ?? '-', 'marital_status': _maritalStatus ?? '-', 'pekerjaan': _pekerjaanCtrl.text.trim(), 'keperluan': _keperluanCtrl.text.trim()};
      case 'sktm':
        return {'nik': _nikCtrl.text.trim(), 'no_kk': _noKkCtrl.text.trim(), 'alasan': _alasanSktm ?? '', 'pernyataan_kondisi': _pernyataanKondisiCtrl.text.trim()};
      case 'sku':
        return {'nik': _nikCtrl.text.trim(), 'ttl': _ttlCtrl.text.trim(), 'gender': _gender ?? '-', 'nama_usaha': _namaUsahaCtrl.text.trim(), 'jenis_usaha': _jenisUsahaCtrl.text.trim(), 'alamat_usaha': _alamatUsahaCtrl.text.trim(), 'keperluan': _keperluanCtrl.text.trim()};
      case 'nikah':
        return {'nik': _nikCtrl.text.trim(), 'ttl': _ttlCtrl.text.trim(), 'gender': _gender ?? '-', 'pekerjaan': _pekerjaanCtrl.text.trim(), 'nama_ayah': _namaAyahCtrl.text.trim(), 'nama_ibu': _namaIbuCtrl.text.trim()};
      case 'kematian':
        return {'nama_almarhum': _namaAlmarhumCtrl.text.trim(), 'nik_almarhum': _nikAlmarhumCtrl.text.trim(), 'ttl_almarhum': _ttlAlmarhumCtrl.text.trim(), 'tanggal_meninggal': _tanggalMeninggal ?? '', 'penyebab': _penyebabCtrl.text.trim(), 'hubungan_pelapor': _hubunganPelapor ?? ''};
      case 'custom':
      default:
        return {'keperluan': _keperluanCtrl.text.trim()};
    }
  }

  String? _extractPurpose(Map<String, dynamic> fd) {
    if (_selectedType == 'kematian') return null;
    if (_selectedType == 'sktm') return fd['alasan'] as String?;
    return fd['keperluan'] as String?;
  }

  // ── Validasi form sebelum lanjut ke review ────────────────────
  String? _validate() {
    final fd = _buildFormData();
    if (_selectedType == 'kematian') {
      if ((fd['nama_almarhum'] as String).isEmpty) return 'Nama almarhum wajib diisi';
      if ((fd['nik_almarhum'] as String).isEmpty) return 'NIK almarhum wajib diisi';
      if ((fd['ttl_almarhum'] as String).isEmpty) return 'TTL almarhum wajib diisi';
      if ((fd['tanggal_meninggal'] as String).isEmpty) return 'Tanggal meninggal wajib diisi';
    } else if (_selectedType == 'ktp_kk') {
      if ((fd['nik'] as String).isEmpty) return 'NIK wajib diisi';
      if (_alasanKtpKk == null) return 'Alasan wajib dipilih';
    } else if (_selectedType == 'sktm') {
      if ((fd['nik'] as String).isEmpty) return 'NIK wajib diisi';
      if ((fd['no_kk'] as String).isEmpty) return 'No KK wajib diisi';
      if (_alasanSktm == null) return 'Alasan wajib dipilih';
    } else if (_selectedType == 'custom') {
      if ((fd['keperluan'] as String).isEmpty) return 'Keperluan wajib diisi';
    } else {
      if ((fd['nik'] as String? ?? '').isEmpty) return 'NIK wajib diisi';
      if ((fd['ttl'] as String? ?? '').isEmpty) return 'TTL wajib diisi';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser!.id;
      final profile = await client
          .from('profiles')
          .select('community_id, full_name')
          .eq('id', userId)
          .single();

      final fd = _buildFormData();
      final isKematian = _selectedType == 'kematian';
      final applicantName = isKematian
          ? (fd['nama_almarhum'] as String)
          : (profile['full_name'] as String);

      await ref.read(layananServiceProvider).createLetterRequest(
        communityId: profile['community_id'] as String,
        residentId: userId,
        letterType: _selectedType!,
        applicantName: applicantName,
        formData: fd,
        purpose: _extractPurpose(fd),
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permohonan berhasil dikirim!'),
            backgroundColor: RukuninColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: RukuninColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == _Step.type ? 'Permohonan Surat' : _step == _Step.form ? 'Isi Data' : 'Konfirmasi'),
        leading: _step == _Step.type
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step = _step == _Step.review ? _Step.form : _Step.type),
              ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_step) {
          _Step.type   => _buildStepType(),
          _Step.form   => _buildStepForm(),
          _Step.review => _buildStepReview(),
        },
      ),
    );
  }

  // ── Step 1: Pilih Jenis ───────────────────────────────────────
  Widget _buildStepType() {
    return ListView(
      key: const ValueKey('step-type'),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pilih jenis surat yang dibutuhkan:', style: GoogleFonts.plusJakartaSans(fontSize: 14)),
        const SizedBox(height: 16),
        ...letterRequestTypeLabels.entries.map((e) => _TypeTile(
          key: ValueKey(e.key),
          typeKey: e.key,
          label: e.value,
          onTap: () => setState(() { _selectedType = e.key; _step = _Step.form; }),
        )),
      ],
    );
  }

  // ── Step 2: Isi Form ──────────────────────────────────────────
  Widget _buildStepForm() {
    return SingleChildScrollView(
      key: const ValueKey('step-form'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildFormFields(),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RukuninColors.brandGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () {
              final err = _validate();
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: RukuninColors.error));
                return;
              }
              setState(() => _step = _Step.review);
            },
            child: const Text('Lanjut: Konfirmasi'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    switch (_selectedType) {
      case 'domisili':
        return [
          _nikField(),
          _ttlField(),
          _genderDropdown(),
          _agamaDropdown(),
          _keperluanField(),
        ];
      case 'ktp_kk':
        return [
          _nikField(),
          _dropdownField('Alasan Permohonan *', _alasanKtpKkOptions, _alasanKtpKk, (v) => setState(() => _alasanKtpKk = v)),
          _textField(_keteranganCtrl, 'Keterangan Tambahan (opsional)', lines: 2),
        ];
      case 'skck':
        return [
          _nikField(),
          _ttlField(),
          _genderDropdown(),
          _agamaDropdown(),
          _maritalDropdown(),
          _textField(_pekerjaanCtrl, 'Pekerjaan *'),
          _keperluanField(),
        ];
      case 'sktm':
        return [
          _nikField(),
          _textField(_noKkCtrl, 'No Kartu Keluarga (KK) *', inputType: TextInputType.number),
          _dropdownField('Alasan Kebutuhan *', _alasanSktmOptions, _alasanSktm, (v) => setState(() => _alasanSktm = v)),
          _textField(_pernyataanKondisiCtrl, 'Pernyataan Kondisi Ekonomi *', lines: 3, hint: 'Contoh: Kepala keluarga tidak bekerja akibat sakit'),
        ];
      case 'sku':
        return [
          _nikField(),
          _ttlField(),
          _genderDropdown(),
          _textField(_namaUsahaCtrl, 'Nama Usaha *'),
          _textField(_jenisUsahaCtrl, 'Jenis Usaha *', hint: 'Contoh: Warung makan, Toko kelontong'),
          _textField(_alamatUsahaCtrl, 'Alamat Usaha *', hint: 'Jika berbeda dari alamat tinggal'),
          _keperluanField(),
        ];
      case 'nikah':
        return [
          _nikField(),
          _ttlField(),
          _genderDropdown(),
          _textField(_pekerjaanCtrl, 'Pekerjaan *'),
          _textField(_namaAyahCtrl, 'Nama Ayah *'),
          _textField(_namaIbuCtrl, 'Nama Ibu *'),
        ];
      case 'kematian':
        return [
          _textField(_namaAlmarhumCtrl, 'Nama Almarhum/Almarhumah *'),
          _textField(_nikAlmarhumCtrl, 'NIK Almarhum *', inputType: TextInputType.number, maxLength: 16),
          _textField(_ttlAlmarhumCtrl, 'TTL Almarhum *', hint: 'Contoh: Solo, 12-12-1950'),
          _datePickerField('Tanggal Meninggal *'),
          _textField(_penyebabCtrl, 'Penyebab Kematian *', hint: 'Contoh: Sakit, Kecelakaan'),
          _dropdownField('Hubungan Pelapor dengan Almarhum *', _hubunganPelaporOptions, _hubunganPelapor, (v) => setState(() => _hubunganPelapor = v)),
        ];
      case 'custom':
      default:
        return [_keperluanField(label: 'Keperluan / Keterangan *', lines: 4)];
    }
  }

  // ── Step 3: Review ────────────────────────────────────────────
  Widget _buildStepReview() {
    final fd = _buildFormData();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      key: const ValueKey('step-review'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Periksa data berikut sebelum mengirim:', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewRow('Jenis Surat', letterRequestTypeLabels[_selectedType] ?? '-'),
                ...fd.entries.map((e) => _reviewRow(_labelFor(e.key), e.value.toString())),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => setState(() => _step = _Step.form),
            child: const Text('Edit Data'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RukuninColors.brandGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Kirim Permohonan'),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: RukuninColors.darkTextSecondary)),
        ),
        Expanded(child: Text(value.isEmpty ? '-' : value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600))),
      ],
    ),
  );

  String _labelFor(String key) => const {
    'nik': 'NIK',
    'ttl': 'Tempat, Tgl Lahir',
    'gender': 'Jenis Kelamin',
    'agama': 'Agama',
    'keperluan': 'Keperluan',
    'alasan': 'Alasan',
    'keterangan': 'Keterangan',
    'no_kk': 'No KK',
    'pernyataan_kondisi': 'Kondisi Ekonomi',
    'marital_status': 'Status Perkawinan',
    'pekerjaan': 'Pekerjaan',
    'nama_usaha': 'Nama Usaha',
    'jenis_usaha': 'Jenis Usaha',
    'alamat_usaha': 'Alamat Usaha',
    'nama_ayah': 'Nama Ayah',
    'nama_ibu': 'Nama Ibu',
    'nama_almarhum': 'Nama Almarhum',
    'nik_almarhum': 'NIK Almarhum',
    'ttl_almarhum': 'TTL Almarhum',
    'tanggal_meninggal': 'Tgl Meninggal',
    'penyebab': 'Penyebab',
    'hubungan_pelapor': 'Hubungan Pelapor',
  }[key] ?? key;

  // ── Field helpers ─────────────────────────────────────────────
  Widget _nikField() => _textField(_nikCtrl, 'NIK *', inputType: TextInputType.number, maxLength: 16);

  Widget _ttlField() => _textField(_ttlCtrl, 'Tempat, Tanggal Lahir *', hint: 'Contoh: Jakarta, 15-02-1990');

  Widget _keperluanField({String label = 'Keperluan / Tujuan *', int lines = 2}) =>
      _textField(_keperluanCtrl, label, lines: lines, hint: 'Jelaskan untuk apa surat ini dibutuhkan');

  Widget _genderDropdown() => _dropdownField('Jenis Kelamin *', _genderOptions, _gender, (v) => setState(() => _gender = v));
  Widget _agamaDropdown() => _dropdownField('Agama *', _agamaOptions, _agama, (v) => setState(() => _agama = v));
  Widget _maritalDropdown() => _dropdownField('Status Perkawinan *', _maritalOptions, _maritalStatus, (v) => setState(() => _maritalStatus = v));

  Widget _textField(TextEditingController ctrl, String label, {int lines = 1, String? hint, TextInputType? inputType, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        keyboardType: inputType,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: maxLength != null ? null : '',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        inputFormatters: inputType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
      ),
    );
  }

  Widget _dropdownField(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: GoogleFonts.plusJakartaSans(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _datePickerField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null && mounted) {
            setState(() {
              _tanggalMeninggal = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(
            _tanggalMeninggal ?? 'Pilih tanggal',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _tanggalMeninggal == null ? Colors.grey : null),
          ),
        ),
      ),
    );
  }
}

// ── Type tile ─────────────────────────────────────────────────
class _TypeTile extends StatelessWidget {
  final String typeKey;
  final String label;
  final VoidCallback onTap;

  const _TypeTile({super.key, required this.typeKey, required this.label, required this.onTap});

  IconData get _icon => switch (typeKey) {
    'ktp_kk'    => Icons.badge_outlined,
    'domisili'  => Icons.home_outlined,
    'sktm'      => Icons.volunteer_activism_outlined,
    'skck'      => Icons.security_outlined,
    'kematian'  => Icons.sentiment_very_dissatisfied_outlined,
    'nikah'     => Icons.favorite_outline,
    'sku'       => Icons.store_outlined,
    _           => Icons.article_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder)),
      child: ListTile(
        leading: Icon(_icon, color: RukuninColors.brandGreen),
        title: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
