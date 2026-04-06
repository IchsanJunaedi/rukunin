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

  final _namaCtrl           = TextEditingController();
  final _ttlCtrl            = TextEditingController();
  final _nikCtrl            = TextEditingController();
  final _kewarganegaraanCtrl = TextEditingController();
  final _pekerjaanCtrl      = TextEditingController();
  final _alamatCtrl         = TextEditingController();

  String? _gender;
  String? _agama;
  String? _maritalStatus;

  static const _genderOptions  = ['Laki-laki', 'Perempuan'];
  static const _agamaOptions   = ['Islam', 'Kristen Protestan', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'];
  static const _maritalOptions = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];

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
    for (final c in [_namaCtrl, _ttlCtrl, _nikCtrl, _kewarganegaraanCtrl, _pekerjaanCtrl, _alamatCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildFormData() => {
    'nama'           : _namaCtrl.text.trim(),
    'ttl'            : _ttlCtrl.text.trim(),
    'gender'         : _gender ?? '',
    'nik'            : _nikCtrl.text.trim(),
    'kewarganegaraan': _kewarganegaraanCtrl.text.trim(),
    'agama'          : _agama ?? '',
    'pekerjaan'      : _pekerjaanCtrl.text.trim(),
    'marital_status' : _maritalStatus ?? '',
    'alamat'         : _alamatCtrl.text.trim(),
  };

  String? _validate() {
    if (_namaCtrl.text.trim().isEmpty)            return 'Nama wajib diisi';
    if (_ttlCtrl.text.trim().isEmpty)             return 'Tempat, tanggal lahir wajib diisi';
    if (_gender == null)                          return 'Jenis kelamin wajib dipilih';
    if (_nikCtrl.text.trim().isEmpty)             return 'NIK / No KTP / KK wajib diisi';
    if (_kewarganegaraanCtrl.text.trim().isEmpty) return 'Kewarganegaraan wajib diisi';
    if (_agama == null)                           return 'Agama wajib dipilih';
    if (_pekerjaanCtrl.text.trim().isEmpty)       return 'Pekerjaan wajib diisi';
    if (_maritalStatus == null)                   return 'Status perkawinan wajib dipilih';
    if (_alamatCtrl.text.trim().isEmpty)          return 'Alamat wajib diisi';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser!.id;
      final profile = await client
          .from('profiles')
          .select('community_id')
          .eq('id', userId)
          .single();

      final fd = _buildFormData();

      await ref.read(layananServiceProvider).createLetterRequest(
        communityId  : profile['community_id'] as String,
        residentId   : userId,
        letterType   : _selectedType!,
        applicantName: fd['nama'] as String,
        formData     : fd,
        purpose      : null,
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
                onPressed: () {
                  if (_step == _Step.review) {
                    setState(() => _step = _Step.form);
                  } else if (_step == _Step.form && widget.initialType != null) {
                    context.pop();
                  } else {
                    setState(() => _step = _Step.type);
                  }
                },
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
        Text('Pilih jenis surat yang dibutuhkan:', style: RukuninFonts.pjs(fontSize: 14)),
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
          _textField(_namaCtrl, 'Nama *', hint: 'Nama lengkap sesuai KTP'),
          _textField(_ttlCtrl, 'Tempat, Tanggal Lahir *', hint: 'Contoh: Jakarta, 15-02-1990'),
          _dropdownField('Jenis Kelamin *', _genderOptions, _gender, (v) => setState(() => _gender = v)),
          _textField(_nikCtrl, 'NIK / No KTP / KK *', inputType: TextInputType.number, maxLength: 16),
          _textField(_kewarganegaraanCtrl, 'Kewarganegaraan *', hint: 'Contoh: WNI'),
          _dropdownField('Agama *', _agamaOptions, _agama, (v) => setState(() => _agama = v)),
          _textField(_pekerjaanCtrl, 'Pekerjaan *', hint: 'Contoh: Wiraswasta, Karyawan Swasta'),
          _dropdownField('Status Perkawinan *', _maritalOptions, _maritalStatus, (v) => setState(() => _maritalStatus = v)),
          _textField(_alamatCtrl, 'Alamat *', lines: 2, hint: 'Alamat lengkap sesuai KTP'),
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
          Text('Periksa data berikut sebelum mengirim:', style: RukuninFonts.pjs(fontSize: 14, fontWeight: FontWeight.w600)),
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
          width: 150,
          child: Text(label, style: RukuninFonts.pjs(fontSize: 12, color: RukuninColors.darkTextSecondary)),
        ),
        Expanded(child: Text(value.isEmpty ? '-' : value, style: RukuninFonts.pjs(fontSize: 12, fontWeight: FontWeight.w600))),
      ],
    ),
  );

  String _labelFor(String key) => const {
    'nama'           : 'Nama',
    'ttl'            : 'Tempat, Tgl Lahir',
    'gender'         : 'Jenis Kelamin',
    'nik'            : 'NIK / No KTP / KK',
    'kewarganegaraan': 'Kewarganegaraan',
    'agama'          : 'Agama',
    'pekerjaan'      : 'Pekerjaan',
    'marital_status' : 'Status Perkawinan',
    'alamat'         : 'Alamat',
  }[key] ?? key;

  // ── Field helpers ─────────────────────────────────────────────
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
          border: InputBorder.none,
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
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: RukuninFonts.pjs(fontSize: 14)))).toList(),
        onChanged: onChanged,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(_icon, color: RukuninColors.brandGreen),
        title: Text(label, style: RukuninFonts.pjs(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
