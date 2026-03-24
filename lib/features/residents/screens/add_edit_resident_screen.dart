import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/resident_model.dart';
import '../models/family_member.dart';
import '../providers/resident_provider.dart';

class AddEditResidentScreen extends ConsumerStatefulWidget {
  final ResidentModel? resident;
  const AddEditResidentScreen({super.key, this.resident});

  @override
  ConsumerState<AddEditResidentScreen> createState() =>
      _AddEditResidentScreenState();
}

class _AddEditResidentScreenState extends ConsumerState<AddEditResidentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _nikCtrl;
  late final TextEditingController _baseRondaCtrl;
  late final TextEditingController _costPerMotorcycleCtrl;
  late final TextEditingController _costPerCarCtrl;
  String _status = 'active';
  String _selectedBlock = 'A';
  int _selectedRt = 1;
  int _maxRt = 3;
  int _motorcycleCount = 0;
  int _carCount = 0;
  List<FamilyMember> _familyMembers = [];

  double get _totalRonda {
    final base = double.tryParse(_baseRondaCtrl.text) ?? 0;
    final perMotor = double.tryParse(_costPerMotorcycleCtrl.text) ?? 0;
    final perCar = double.tryParse(_costPerCarCtrl.text) ?? 0;
    return base + (_motorcycleCount * perMotor) + (_carCount * perCar);
  }

  bool get isEdit => widget.resident != null;

  @override
  void initState() {
    super.initState();
    final r = widget.resident;
    _nameCtrl = TextEditingController(text: r?.fullName ?? '');
    _unitCtrl = TextEditingController(text: r?.unitNumber ?? '');
    _phoneCtrl = TextEditingController(text: r?.phone ?? '');
    _nikCtrl = TextEditingController(text: r?.nik ?? '');
    _baseRondaCtrl = TextEditingController(text: '0');
    _costPerMotorcycleCtrl = TextEditingController(text: '5000');
    _costPerCarCtrl = TextEditingController(text: '10000');
    _status = r?.status ?? 'active';
    _selectedBlock = r?.block ?? 'A';
    _selectedRt = r?.rtNumber ?? 1;
    _motorcycleCount = r?.motorcycleCount ?? 0;
    _carCount = r?.carCount ?? 0;
    _loadCommunityData();
    if (isEdit) {
      _loadFamilyMembers();
    }
  }

  Future<void> _loadFamilyMembers() async {
    if (widget.resident == null) return;
    try {
      final client = ref.read(supabaseClientProvider);
      final res = await client
          .from('family_members')
          .select()
          .eq('resident_id', widget.resident!.id);

      if (mounted) {
        setState(() {
          _familyMembers = (res as List).map((e) => FamilyMember.fromMap(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat anggota keluarga: $e');
    }
  }

  Future<void> _loadCommunityData() async {
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

    final community = await client
        .from('communities')
        .select('rt_count')
        .eq('id', communityId)
        .maybeSingle();

    if (community != null && mounted) {
      setState(() {
        _maxRt = (community['rt_count'] as int?) ?? 3;
        if (_selectedRt > _maxRt) _selectedRt = 1;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _phoneCtrl.dispose();
    _nikCtrl.dispose();
    _baseRondaCtrl.dispose();
    _costPerMotorcycleCtrl.dispose();
    _costPerCarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(residentNotifierProvider.notifier);

    if (isEdit) {
      await notifier.updateResident(
        id: widget.resident!.id,
        fullName: _nameCtrl.text.trim(),
        unitNumber: _unitCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        nik: _nikCtrl.text.trim(),
        status: _status,
        rtNumber: _selectedRt,
        block: _selectedBlock,
        motorcycleCount: _motorcycleCount,
        carCount: _carCount,
        familyMembers: _familyMembers,
      );
    } else {
      await notifier.addResident(
        fullName: _nameCtrl.text.trim(),
        unitNumber: _unitCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        nik: _nikCtrl.text.trim(),
        rtNumber: _selectedRt,
        block: _selectedBlock,
        motorcycleCount: _motorcycleCount,
        carCount: _carCount,
        familyMembers: _familyMembers,
      );
    }

    final state = ref.read(residentNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal: ${state.error}'),
        backgroundColor: RukuninColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Auto-create invoice Ronda bulan ini jika ada biaya ronda
    if (_totalRonda > 0) {
      try {
        final client = ref.read(supabaseClientProvider);
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          final profileData = await client
              .from('profiles')
              .select('community_id')
              .eq('id', userId)
              .maybeSingle();
          final communityId = profileData?['community_id'] as String?;

          // Cari billing_type untuk Ronda (case-insensitive)
          final billingTypes = await client
              .from('billing_types')
              .select('id, billing_day')
              .ilike('name', '%ronda%')
              .eq('is_active', true)
              .limit(1);

          final now = DateTime.now();
          final residentId = isEdit ? widget.resident!.id
              : (await client.from('profiles').select('id').eq('phone', _phoneCtrl.text.trim()).eq('role', 'resident').maybeSingle())?['id'];

          if (communityId != null && billingTypes.isNotEmpty && residentId != null) {
            final bt = billingTypes.first;
            final billingDay = (bt['billing_day'] as int?) ?? 10;
            final dueDate = DateTime(now.year, now.month, billingDay);

            // Upsert: kalau sudah ada invoice bulan ini, jangan insert duplikat
            await client.from('invoices').upsert(
              {
                'community_id': communityId,
                'resident_id': residentId,
                'billing_type_id': bt['id'],
                'amount': _totalRonda,
                'month': now.month,
                'year': now.year,
                'due_date': dueDate.toIso8601String(),
                'status': 'pending',
                'created_at': now.toIso8601String(),
              },
              onConflict: 'resident_id,billing_type_id,month,year',
              ignoreDuplicates: false, // update amount jika sudah ada
            );
          }
        }
      } catch (e) {
        // Gagal insert invoice tidak menghalangi save profil
        debugPrint('Gagal buat invoice Ronda: $e');
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(residentNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Warga' : 'Tambah Warga',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar Preview
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: RukuninColors.brandGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    _getInitials(_nameCtrl.text),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // === DATA PRIBADI ===
            _sectionLabel('Data Pribadi'),
            _card([
              _field(
                ctrl: _nameCtrl,
                label: 'Nama Lengkap',
                icon: Icons.person_outline_rounded,
                onChanged: (_) => setState(() {}),
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              _divider(),
              _field(
                ctrl: _nikCtrl,
                label: 'NIK (16 digit) — Opsional',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                maxLength: 16,
              ),
              _divider(),
              _field(
                ctrl: _phoneCtrl,
                label: 'Nomor HP / WhatsApp',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Nomor HP wajib diisi' : null,
              ),
            ]),

            const SizedBox(height: 16),

            // === DATA HUNIAN ===
            _sectionLabel('Data Hunian'),
            _card([
              // Blok — text input bebas
              _field(
                ctrl: TextEditingController(text: _selectedBlock)
                  ..addListener(() {}),
                label: 'Blok (opsional, contoh: A, B, C)',
                icon: Icons.grid_view_rounded,
                onChanged: (v) => setState(() => _selectedBlock = v.toUpperCase()),
              ),
              _divider(),

              // RT dropdown
              _dropdownRow(
                icon: Icons.location_on_outlined,
                label: 'RT',
                child: DropdownButton<int>(
                  value: _selectedRt,
                  underline: const SizedBox(),
                  isDense: true,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
                  items: List.generate(
                    _maxRt,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('RT ${i + 1}'),
                    ),
                  ),
                  onChanged: (v) => setState(() => _selectedRt = v!),
                ),
              ),
              _divider(),

              // Nomor rumah
              _field(
                ctrl: _unitCtrl,
                label: 'Nomor Rumah',
                icon: Icons.home_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Nomor rumah wajib diisi' : null,
              ),

              if (isEdit) ...[
                _divider(),
                _statusToggle(),
              ],
            ]),

            const SizedBox(height: 16),

            // === ANGGOTA RUMAH ===
            _sectionLabel('Anggota Rumah'),
            _card([
              ..._familyMembers.asMap().entries.map((e) {
                final idx = e.key;
                final member = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(member.relationship == 'Anak' ? Icons.child_care : Icons.face, size: 18, color: RukuninColors.brandGreen),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${member.fullName} (${member.relationship})', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                                if (member.nik != null && member.nik!.isNotEmpty)
                                  Text('NIK: ${member.nik}', style: GoogleFonts.plusJakartaSans(color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: RukuninColors.error, size: 20),
                            onPressed: () => setState(() => _familyMembers.removeAt(idx)),
                          ),
                        ],
                      ),
                    ),
                    if (idx < _familyMembers.length - 1) _divider(),
                  ],
                );
              }),

              if (_familyMembers.isNotEmpty) _divider(),

              InkWell(
                onTap: _addFamilyMemberDialog,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: RukuninColors.brandGreen, size: 20),
                      const SizedBox(width: 8),
                      Text('Tambah Anggota Keluarga', style: GoogleFonts.plusJakartaSans(color: RukuninColors.brandGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // === KENDARAAN ===
            _sectionLabel('Data Kendaraan (untuk Iuran Keamanan/Ronda)'),
            _card([
              _dropdownRow(
                icon: Icons.two_wheeler,
                label: 'Jumlah Motor',
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: _motorcycleCount > 0
                          ? () => setState(() => _motorcycleCount--)
                          : null,
                      color: RukuninColors.brandGreen,
                    ),
                    Text(
                      '$_motorcycleCount',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => setState(() => _motorcycleCount++),
                      color: RukuninColors.brandGreen,
                    ),
                  ],
                ),
              ),
              _divider(),
              _dropdownRow(
                icon: Icons.directions_car_outlined,
                label: 'Jumlah Mobil',
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: _carCount > 0
                          ? () => setState(() => _carCount--)
                          : null,
                      color: RukuninColors.brandGreen,
                    ),
                    Text(
                      '$_carCount',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => setState(() => _carCount++),
                      color: RukuninColors.brandGreen,
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // === KALKULATOR RONDA ===
            _sectionLabel('🛺 Kalkulator Tagihan Ronda'),
            Container(
              decoration: BoxDecoration(
                color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2),
              ),
              child: Column(
                children: [
                  _field(
                    ctrl: _baseRondaCtrl,
                    label: 'Biaya Rata Ronda (Rp)',
                    icon: Icons.security_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  _divider(),
                  _field(
                    ctrl: _costPerMotorcycleCtrl,
                    label: 'Tambahan per Motor (Rp)',
                    icon: Icons.two_wheeler,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  _divider(),
                  _field(
                    ctrl: _costPerCarCtrl,
                    label: 'Tambahan per Mobil (Rp)',
                    icon: Icons.directions_car_outlined,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Preview Total Ronda
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RukuninColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RukuninColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rincian Tagihan Ronda Bulan Ini',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.security_outlined, size: 14, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                      const SizedBox(width: 6),
                      Text('Biaya rata', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
                      const Spacer(),
                      Text('Rp ${(double.tryParse(_baseRondaCtrl.text) ?? 0).toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.two_wheeler, size: 14, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                      const SizedBox(width: 6),
                      Text('$_motorcycleCount motor × Rp ${(double.tryParse(_costPerMotorcycleCtrl.text) ?? 0).toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
                      const Spacer(),
                      Text('Rp ${(_motorcycleCount * (double.tryParse(_costPerMotorcycleCtrl.text) ?? 0)).toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_car_outlined, size: 14, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                      const SizedBox(width: 6),
                      Text('$_carCount mobil × Rp ${(double.tryParse(_costPerCarCtrl.text) ?? 0).toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
                      const Spacer(),
                      Text('Rp ${(_carCount * (double.tryParse(_costPerCarCtrl.text) ?? 0)).toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Divider(color: RukuninColors.success.withValues(alpha: 0.3), height: 20),
                  Row(
                    children: [
                      Text('Total Tagihan Ronda',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800, fontSize: 14, color: RukuninColors.success)),
                      const Spacer(),
                      Text(
                        'Rp ${_totalRonda.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800, fontSize: 18, color: RukuninColors.success),
                      ),
                    ],
                  ),
                  if (_totalRonda > 0) ...
                    [const SizedBox(height: 6),
                    Text(
                      '📌 Invoice Ronda bulan ini akan otomatis dibuat/diperbarui saat simpan.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                    )],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Info alamat preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_work_outlined,
                      size: 16, color: RukuninColors.brandGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Blok $_selectedBlock · No. ${_unitCtrl.text.isEmpty ? "?" : _unitCtrl.text} · RT $_selectedRt',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: RukuninColors.brandGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Tombol Simpan
            GestureDetector(
              onTap: isLoading ? null : _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 54,
                decoration: BoxDecoration(
                  color: isLoading
                      ? (isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface).withValues(alpha: 0.6)
                      : (isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: RukuninColors.brandGreen,
                          ),
                        )
                      : Text(
                          isEdit ? 'Simpan Perubahan' : 'Tambah Warga',
                          style: GoogleFonts.plusJakartaSans(
                            color: RukuninColors.brandGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2 && p[0].isNotEmpty && p[1].isNotEmpty) {
      return '${p[0][0]}${p[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                letterSpacing: 0.5,
              ),
            );
          },
        ),
      );

  Widget _card(List<Widget> children) => Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          );
        },
      );

  Widget _divider() => const Divider(height: 1, indent: 52);

  void _addFamilyMemberDialog() {
    final fmName = TextEditingController();
    final fmNik = TextEditingController();
    String fmRel = 'Istri';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tambah Anggota Keluarga', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: fmName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: fmRel,
                    decoration: InputDecoration(
                      labelText: 'Hubungan Keluarga *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Istri', 'Suami', 'Anak', 'Orang Tua', 'Lainnya']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.plusJakartaSans(fontSize: 14))))
                        .toList(),
                    onChanged: (v) => setModalState(() => fmRel = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: fmNik,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'NIK (Opsional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (fmName.text.trim().isEmpty) return;
                        setState(() {
                          _familyMembers.add(FamilyMember(
                            fullName: fmName.text.trim(),
                            relationship: fmRel,
                            nik: fmNik.text.trim(),
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RukuninColors.brandGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text('Tambah', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int? maxLength,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          maxLength: maxLength,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
            prefixIcon: Icon(icon, size: 18, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
            filled: true,
            fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: RukuninColors.brandGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: RukuninColors.error),
            ),
          ),
        );
      },
    );
  }

  Widget _dropdownRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
              const SizedBox(width: 16),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
              const Spacer(),
              child,
            ],
          ),
        );
      },
    );
  }

  Widget _statusToggle() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.circle,
                  size: 10,
                  color: _status == 'active' ? Colors.green : (isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
              const SizedBox(width: 16),
              Text('Status',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
              const Spacer(),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                      value: 'active',
                      label: Text('Aktif',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12))),
                  ButtonSegment(
                      value: 'inactive',
                      label: Text('Nonaktif',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12))),
                ],
                selected: {_status},
                onSelectionChanged: (v) => setState(() => _status = v.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((s) {
                    if (s.contains(WidgetState.selected)) return RukuninColors.brandGreen;
                    return Colors.transparent;
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
