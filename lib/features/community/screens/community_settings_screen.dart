import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/services/location_service.dart';
import '../../../core/supabase/supabase_client.dart';

class CommunitySettingsScreen extends ConsumerStatefulWidget {
  const CommunitySettingsScreen({super.key});

  @override
  ConsumerState<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState
    extends ConsumerState<CommunitySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _rwCtrl = TextEditingController();
  int _rtCount = 3;
  bool _isLoading = false;
  bool _isSaving = false;

  WilayahModel? _provinsi;
  WilayahModel? _kabupaten;
  WilayahModel? _kecamatan;
  WilayahModel? _kelurahan;

  String? _communityId;

  @override
  void initState() {
    super.initState();
    _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final profile = await client
          .from('profiles')
          .select('community_id')
          .eq('id', userId)
          .maybeSingle();

      final communityId = profile?['community_id'] as String?;
      if (communityId == null) return;
      _communityId = communityId;

      final c = await client
          .from('communities')
          .select()
          .eq('id', communityId)
          .maybeSingle();

      if (c != null) {
        _nameCtrl.text = c['name'] ?? '';
        _rwCtrl.text = c['rw_number'] ?? '';
        _rtCount = (c['rt_count'] as int?) ?? 3;
        if (c['province'] != null) {
          _provinsi = WilayahModel(id: '', name: c['province'] as String);
        }
        if (c['kabupaten'] != null) {
          _kabupaten = WilayahModel(id: '', name: c['kabupaten'] as String);
        }
        if (c['kecamatan'] != null) {
          _kecamatan = WilayahModel(id: '', name: c['kecamatan'] as String);
        }
        if (c['kelurahan'] != null) {
          _kelurahan = WilayahModel(id: '', name: c['kelurahan'] as String);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('communities').update({
        'name': _nameCtrl.text.trim(),
        'rw_number': _rwCtrl.text.trim(),
        'rt_count': _rtCount,
        if (_provinsi != null) 'province': _provinsi!.name,
        if (_kabupaten != null) 'kabupaten': _kabupaten!.name,
        if (_kecamatan != null) 'kecamatan': _kecamatan!.name,
        if (_kelurahan != null) 'kelurahan': _kelurahan!.name,
      }).eq('id', _communityId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Data community berhasil disimpan'),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provinsiAsync = ref.watch(provinsiProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profil Community',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // === INFO DASAR ===
                  _sectionLabel('Informasi Dasar'),
                  _card([
                    _textField(
                      ctrl: _nameCtrl,
                      label: 'Nama Community / RW',
                      icon: Icons.home_work_outlined,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    _divider(),
                    _textField(
                      ctrl: _rwCtrl,
                      label: 'Nomor RW',
                      icon: Icons.tag_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    _divider(),
                    _rtCountRow(),
                  ]),

                  const SizedBox(height: 16),

                  // === ALAMAT WILAYAH ===
                  _sectionLabel('Alamat Wilayah'),
                  _card([
                    // Provinsi
                    _wilayahDropdown(
                      label: 'Provinsi',
                      icon: Icons.map_outlined,
                      asyncValue: provinsiAsync,
                      selected: _provinsi,
                      onSelected: (v) => setState(() {
                        _provinsi = v;
                        _kabupaten = null;
                        _kecamatan = null;
                        _kelurahan = null;
                      }),
                    ),
                    _divider(),

                    // Kabupaten/Kota
                    _wilayahDropdown(
                      label: 'Kabupaten / Kota',
                      icon: Icons.location_city_outlined,
                      asyncValue: _provinsi != null
                          ? ref.watch(kabupatenProvider(_provinsi!.id))
                          : const AsyncData([]),
                      selected: _kabupaten,
                      enabled: _provinsi != null,
                      onSelected: (v) => setState(() {
                        _kabupaten = v;
                        _kecamatan = null;
                        _kelurahan = null;
                      }),
                    ),
                    _divider(),

                    // Kecamatan
                    _wilayahDropdown(
                      label: 'Kecamatan',
                      icon: Icons.place_outlined,
                      asyncValue: _kabupaten != null
                          ? ref.watch(kecamatanProvider(_kabupaten!.id))
                          : const AsyncData([]),
                      selected: _kecamatan,
                      enabled: _kabupaten != null,
                      onSelected: (v) => setState(() {
                        _kecamatan = v;
                        _kelurahan = null;
                      }),
                    ),
                    _divider(),

                    // Kelurahan/Desa
                    _wilayahDropdown(
                      label: 'Kelurahan / Desa',
                      icon: Icons.holiday_village_outlined,
                      asyncValue: _kecamatan != null
                          ? ref.watch(kelurahanProvider(_kecamatan!.id))
                          : const AsyncData([]),
                      selected: _kelurahan,
                      enabled: _kecamatan != null,
                      onSelected: (v) => setState(() => _kelurahan = v),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  GestureDetector(
                    onTap: _isSaving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 54,
                      decoration: BoxDecoration(
                        color: _isSaving
                            ? AppColors.surface.withValues(alpha: 0.6)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary))
                            : Text('Simpan',
                                style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _rtCountRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.tag_rounded, size: 18, color: AppColors.grey400),
          const SizedBox(width: 16),
          Text('Jumlah RT',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.grey600)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            color: _rtCount > 1 ? AppColors.primary : AppColors.grey400,
            onPressed: _rtCount > 1
                ? () => setState(() => _rtCount--)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$_rtCount',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: AppColors.primary,
            onPressed: () => setState(() => _rtCount++),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _wilayahDropdown({
    required String label,
    required IconData icon,
    required AsyncValue<List<WilayahModel>> asyncValue,
    required WilayahModel? selected,
    required void Function(WilayahModel) onSelected,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.grey400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppColors.grey600)),
                const SizedBox(height: 4),
                asyncValue.when(
                  loading: () => const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                  error: (e, _) => Text('Gagal memuat',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: AppColors.error)),
                  data: (list) => !enabled || list.isEmpty
                      ? Text(
                          enabled ? 'Tidak ada data' : 'Pilih ${_prevLabel(label)} dulu',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: AppColors.grey400))
                      : DropdownButton<WilayahModel>(
                          value: selected,
                          hint: Text('Pilih $label',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, color: AppColors.grey400)),
                          underline: const SizedBox(),
                          isDense: true,
                          isExpanded: true,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey800),
                          items: list
                              .map((w) => DropdownMenuItem(
                                    value: w,
                                    child: Text(w.name,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => v != null ? onSelected(v) : null,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _prevLabel(String label) {
    if (label == 'Kabupaten / Kota') return 'Provinsi';
    if (label == 'Kecamatan') return 'Kabupaten';
    if (label == 'Kelurahan / Desa') return 'Kecamatan';
    return '';
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.grey600,
                letterSpacing: 0.5)),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: children),
      );

  Widget _divider() => const Divider(height: 1, indent: 52);

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
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: AppColors.grey800),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppColors.grey600),
          prefixIcon: Icon(icon, size: 18, color: AppColors.grey400),
          filled: true,
          fillColor: Colors.white,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      );
}
