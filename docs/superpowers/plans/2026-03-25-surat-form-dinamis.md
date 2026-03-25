# Form Dinamis Permohonan Surat & Auto-Generate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign alur permohonan surat sehingga warga mengisi form lengkap per jenis surat, admin tinggal verifikasi dan ACC, surat ter-generate otomatis, dan warga bisa unduh dokumennya di app.

**Architecture:** Data form warga disimpan sebagai `form_data JSONB` di tabel `letter_requests`. Saat admin ACC, `LayananService.verifyAndGenerateLetter()` memanggil `LetterPdfGenerator.getTemplate()` dengan mapping dari `form_data`, lalu insert ke tabel `letters`. Resident dapat melihat dokumennya di `ResidentLettersScreen` baru via route `/resident/dokumen-saya`.

**Tech Stack:** Flutter, Riverpod (`FutureProvider.autoDispose`, `Provider`), Supabase (postgres, RLS), GoRouter, `pdf` package (`LetterPdfGenerator`), `flutter_test` untuk unit test model.

**Spec:** `docs/superpowers/specs/2026-03-25-surat-form-dinamis-design.md`

---

## File Map

| File | Status | Tanggung Jawab |
|---|---|---|
| `supabase/migrations/20260325_letter_request_form_data.sql` | Buat baru | Tambah `form_data`, `applicant_name`; ganti CHECK constraint; tambah `leader_name` di communities |
| `lib/features/layanan/models/letter_request_model.dart` | Modifikasi | Tambah field `formData`, `applicantName`; update status labels & `progressPercent` |
| `test/features/layanan/models_test.dart` | Modifikasi | Update test untuk status baru + field baru |
| `lib/features/layanan/screens/layanan_screen.dart` | Modifikasi | Update `_statusColor()` dan `_StatusBadge._label` untuk `verified` |
| `lib/features/layanan/providers/layanan_provider.dart` | Modifikasi | Tambah `verifyAndGenerateLetter()`, `rejectRequest()`; update `createLetterRequest()` |
| `lib/features/letters/providers/letter_provider.dart` | Modifikasi | Tambah `myLettersProvider` |
| `lib/features/layanan/screens/request_letter_screen.dart` | Modifikasi total | Multi-step form dinamis per jenis surat |
| `lib/features/layanan/screens/admin_requests_screen.dart` | Modifikasi | Ganti tombol "Buat Surat" → "Verifikasi"; update filter chips; hapus `_UpdateStatusSheet` |
| `lib/features/layanan/screens/verify_request_screen.dart` | Buat baru | Tampil data warga + aksi ACC/Tolak + auto-generate |
| `lib/features/letters/screens/resident_letters_screen.dart` | Buat baru | Halaman "Dokumen Saya" untuk resident |
| `lib/app/router.dart` | Modifikasi | Tambah route `/admin/layanan-verifikasi/:id` dan `/resident/dokumen-saya` |

---

## Task 1: Database Migration

**Files:**
- Create: `supabase/migrations/20260325_letter_request_form_data.sql`

- [ ] **Step 1: Tulis file migration**

```sql
-- supabase/migrations/20260325_letter_request_form_data.sql

-- 1. Tambah kolom baru di letter_requests
ALTER TABLE letter_requests
  ADD COLUMN IF NOT EXISTS form_data JSONB,
  ADD COLUMN IF NOT EXISTS applicant_name TEXT;

-- 2. Ganti CHECK constraint status
--    (nama constraint mungkin berbeda di live DB — cek dulu dengan query di bawah
--     sebelum jalankan: SELECT conname FROM pg_constraint WHERE conrelid = 'letter_requests'::regclass)
ALTER TABLE letter_requests
  DROP CONSTRAINT IF EXISTS letter_requests_status_check;

ALTER TABLE letter_requests
  ADD CONSTRAINT letter_requests_status_check
  CHECK (status IN ('pending', 'verified', 'completed', 'rejected'));

-- 3. Tambah leader_name di communities
--    (dipakai Edge Function generate-letter tapi belum ada di migrations)
ALTER TABLE communities
  ADD COLUMN IF NOT EXISTS leader_name TEXT;
```

- [ ] **Step 2: Jalankan migration di Supabase SQL Editor**

Buka Supabase dashboard → SQL Editor → paste isi file → Run.

Verifikasi berhasil: tidak ada error, query berikut mengembalikan kolom baru:
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'letter_requests'
AND column_name IN ('form_data', 'applicant_name');
```

- [ ] **Step 3: Commit**

```bash
rtk git add supabase/migrations/20260325_letter_request_form_data.sql
rtk git commit -m "chore(db): add form_data and applicant_name to letter_requests, verified status"
```

---

## Task 2: Update LetterRequestModel + Tests

**Files:**
- Modify: `lib/features/layanan/models/letter_request_model.dart`
- Modify: `test/features/layanan/models_test.dart`

- [ ] **Step 1: Tulis test yang akan gagal**

Buka `test/features/layanan/models_test.dart`. Ganti seluruh group `LetterRequestModel` dengan:

```dart
group('LetterRequestModel', () {
  final baseMap = {
    'id': 'req-1',
    'community_id': 'com-1',
    'resident_id': 'res-1',
    'letter_type': 'domisili',
    'purpose': 'Melamar kerja',
    'notes': null,
    'status': 'pending',
    'admin_notes': null,
    'letter_id': null,
    'form_data': {'nik': '3201xxx', 'ttl': 'Jakarta, 01-01-1990', 'gender': 'Laki-laki', 'agama': 'Islam', 'keperluan': 'Melamar kerja'},
    'applicant_name': 'Budi Santoso',
    'created_at': '2026-03-25T10:00:00.000Z',
    'updated_at': '2026-03-25T10:00:00.000Z',
    'profiles': {'full_name': 'Budi Santoso', 'unit_number': '12'},
  };

  test('fromMap parses new fields correctly', () {
    final model = LetterRequestModel.fromMap(baseMap);
    expect(model.id, 'req-1');
    expect(model.applicantName, 'Budi Santoso');
    expect(model.formData, isNotNull);
    expect(model.formData!['nik'], '3201xxx');
  });

  test('fromMap handles null form_data and applicant_name', () {
    final map = {...baseMap, 'form_data': null, 'applicant_name': null};
    final model = LetterRequestModel.fromMap(map);
    expect(model.formData, isNull);
    expect(model.applicantName, isNull);
  });

  test('progressPercent reflects new status flow', () {
    expect(LetterRequestModel.fromMap({...baseMap, 'status': 'pending'}).progressPercent, 0.25);
    expect(LetterRequestModel.fromMap({...baseMap, 'status': 'verified'}).progressPercent, 0.9);
    expect(LetterRequestModel.fromMap({...baseMap, 'status': 'completed'}).progressPercent, 1.0);
    expect(LetterRequestModel.fromMap({...baseMap, 'status': 'rejected'}).progressPercent, 0.0);
  });

  test('isActive returns true for pending and verified', () {
    expect(LetterRequestModel.fromMap({...baseMap, 'status': 'pending'}).isActive, true);
    expect(LetterRequestModel.fromMap({...baseMap, 'status': 'verified'}).isActive, true);
    expect(LetterRequestModel.fromMap({...baseMap, 'status': 'completed'}).isActive, false);
    expect(LetterRequestModel.fromMap({...baseMap, 'status': 'rejected'}).isActive, false);
  });

  test('typeLabel returns correct label', () {
    expect(LetterRequestModel.fromMap(baseMap).typeLabel, 'Keterangan Domisili');
  });
});
```

- [ ] **Step 2: Jalankan test — pastikan gagal**

```bash
flutter test test/features/layanan/models_test.dart
```

Expected: FAIL — field `applicantName` dan `formData` tidak ada di model.

- [ ] **Step 3: Update LetterRequestModel**

Edit `lib/features/layanan/models/letter_request_model.dart`:

```dart
const letterRequestStatusLabels = {
  'pending': 'Menunggu Verifikasi',
  'verified': 'Surat Siap',
  'completed': 'Selesai',
  'rejected': 'Ditolak',
};

const letterRequestTypeLabels = {
  'ktp_kk': 'Pengantar KTP & KK',
  'domisili': 'Keterangan Domisili',
  'sktm': 'Keterangan Tidak Mampu',
  'skck': 'Pengantar SKCK',
  'kematian': 'Keterangan Kematian',
  'nikah': 'Pengantar Nikah',
  'sku': 'Keterangan Usaha',
  'custom': 'Lainnya',
};

class LetterRequestModel {
  final String id;
  final String communityId;
  final String residentId;
  final String letterType;
  final String? purpose;
  final String? notes;
  final String status;
  final String? adminNotes;
  final String? letterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? residentName;
  final String? residentUnit;
  final Map<String, dynamic>? formData;
  final String? applicantName;

  const LetterRequestModel({
    required this.id,
    required this.communityId,
    required this.residentId,
    required this.letterType,
    this.purpose,
    this.notes,
    required this.status,
    this.adminNotes,
    this.letterId,
    required this.createdAt,
    required this.updatedAt,
    this.residentName,
    this.residentUnit,
    this.formData,
    this.applicantName,
  });

  factory LetterRequestModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return LetterRequestModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      residentId: map['resident_id'] as String,
      letterType: map['letter_type'] as String,
      purpose: map['purpose'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'pending',
      adminNotes: map['admin_notes'] as String?,
      letterId: map['letter_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      residentName: profile?['full_name'] as String?,
      residentUnit: profile?['unit_number'] as String?,
      formData: map['form_data'] as Map<String, dynamic>?,
      applicantName: map['applicant_name'] as String?,
    );
  }

  String get typeLabel => letterRequestTypeLabels[letterType] ?? letterType;
  String get statusLabel => letterRequestStatusLabels[status] ?? status;
  bool get isActive => status != 'completed' && status != 'rejected';

  double get progressPercent => switch (status) {
    'pending'   => 0.25,
    'verified'  => 0.9,
    'completed' => 1.0,
    _           => 0.0,
  };
}
```

- [ ] **Step 4: Jalankan test — pastikan lulus**

```bash
flutter test test/features/layanan/models_test.dart
```

Expected: PASS semua test.

- [ ] **Step 5: Pastikan tidak ada compile error**

```bash
flutter analyze lib/features/layanan/models/letter_request_model.dart
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
rtk git add lib/features/layanan/models/letter_request_model.dart test/features/layanan/models_test.dart
rtk git commit -m "feat(layanan): update LetterRequestModel with formData, applicantName, new status flow"
```

---

## Task 3: Update Status Colors & Labels di layanan_screen.dart

**Files:**
- Modify: `lib/features/layanan/screens/layanan_screen.dart:38-44` (fungsi `_statusColor`)
- Modify: `lib/features/layanan/screens/layanan_screen.dart:451-458` (getter `_StatusBadge._label`)

- [ ] **Step 1: Update `_statusColor()`**

Ganti fungsi `_statusColor` (sekitar line 38):

```dart
Color _statusColor(String status) => switch (status) {
  'pending'                     => RukuninColors.warning,
  'verified' || 'completed' || 'resolved' => RukuninColors.success,
  'rejected'                    => RukuninColors.error,
  _                             => RukuninColors.darkTextTertiary,
};
```

- [ ] **Step 2: Update `_StatusBadge._label`**

Cari getter `_label` di class `_StatusBadge` (sekitar line 451). Ganti seluruh switch:

```dart
String get _label => switch (status) {
  'pending'   => 'Menunggu',
  'verified'  => 'Surat Siap',
  'completed' => 'Selesai',
  'rejected'  => 'Ditolak',
  'resolved'  => 'Selesai',
  _           => status,
};
```

- [ ] **Step 3: Pastikan tidak ada compile error**

```bash
flutter analyze lib/features/layanan/screens/layanan_screen.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
rtk git add lib/features/layanan/screens/layanan_screen.dart
rtk git commit -m "feat(layanan): update status colors and labels for verified status"
```

---

## Task 4: Tambah verifyAndGenerateLetter & rejectRequest ke LayananService

**Files:**
- Modify: `lib/features/layanan/providers/layanan_provider.dart`

- [ ] **Step 1: Hapus branch `'ready'` dari `updateLetterRequestStatus()`**

Setelah migration, status `'ready'` tidak lagi valid di DB. Hapus branch if-block untuk `newStatus == 'ready'` (sekitar line 204-222) dari method `updateLetterRequestStatus`. Ganti notif body dengan satu baris generic saja:

```dart
// Ganti blok if (newStatus == 'ready') { ... } dengan:
String notifBody = 'Status permohonan surat kamu diperbarui: ${letterRequestStatusLabels[newStatus] ?? newStatus}';
```

- [ ] **Step 2: Update `createLetterRequest()` untuk terima `formData` dan `applicantName`**

Ganti method `createLetterRequest` yang ada:

```dart
Future<void> createLetterRequest({
  required String communityId,
  required String residentId,
  required String letterType,
  required String applicantName,
  required Map<String, dynamic> formData,
  String? purpose,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('letter_requests').insert({
    'community_id': communityId,
    'resident_id': residentId,
    'letter_type': letterType,
    'applicant_name': applicantName,
    'form_data': formData,
    if (purpose != null) 'purpose': purpose,
  });
  ref.invalidate(myLetterRequestsProvider);
}
```

- [ ] **Step 3: Tambah helper `_computeAge()` sebagai static method di class `LayananService`**

```dart
static String _computeAge(String? ttl) {
  if (ttl == null || ttl.isEmpty) return '-';
  final parts = ttl.split(',');
  if (parts.length < 2) return '-';
  try {
    final dateParts = parts.last.trim().split('-');
    if (dateParts.length != 3) return '-';
    final dob = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    return '$age tahun';
  } catch (_) {
    return '-';
  }
}
```

- [ ] **Step 4: Tambah helper `_extractPurpose()` sebagai static method**

```dart
static String? _extractPurpose(String letterType, Map<String, dynamic> formData) {
  if (letterType == 'kematian') return null;
  if (letterType == 'sktm') return formData['alasan'] as String?;
  return formData['keperluan'] as String?;
}
```

- [ ] **Step 5: Tambah method `rejectRequest()`**

```dart
Future<void> rejectRequest({
  required String requestId,
  required String residentId,
  required String communityId,
  required String alasan,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client
      .from('letter_requests')
      .update({
        'status': 'rejected',
        'admin_notes': alasan,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', requestId)
      .eq('community_id', communityId);

  await insertNotification(
    client: client,
    userId: residentId,
    communityId: communityId,
    type: 'letter_request',
    title: 'Permohonan Surat Ditolak',
    body: 'Permohonan surat kamu ditolak. Alasan: $alasan',
  );
  ref.invalidate(adminLetterRequestsProvider);
  ref.invalidate(myLetterRequestsProvider);
}
```

- [ ] **Step 6: Tambah method `verifyAndGenerateLetter()`**

Tambahkan import di atas file:
```dart
import '../../../core/utils/letter_pdf_generator.dart';
import '../../letters/providers/letter_provider.dart';
```

Lalu tambahkan method:

```dart
Future<void> verifyAndGenerateLetter({
  required LetterRequestModel request,
}) async {
  final client = ref.read(supabaseClientProvider);

  // 1. Fetch profil admin untuk community_id
  final adminProfile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', client.auth.currentUser!.id)
      .single();
  final communityId = adminProfile['community_id'] as String;

  // 2. Fetch data komunitas (termasuk rt_number dan leader_name)
  final communityData = await client
      .from('communities')
      .select('name, rt_number, rw_number, kelurahan, kecamatan, kabupaten, province, leader_name')
      .eq('id', communityId)
      .single();

  final fd = request.formData ?? {};
  final letterType = request.letterType;

  // 3. Mapping form_data → getTemplate() parameters
  final isKematian = letterType == 'kematian';
  final hasTtl = fd.containsKey('ttl');
  final hasTtlAlmarhum = fd.containsKey('ttl_almarhum');

  final residentNik = isKematian
      ? (fd['nik_almarhum'] as String? ?? '-')
      : (fd['nik'] as String? ?? '-');

  final ttlRaw = isKematian
      ? fd['ttl_almarhum'] as String?
      : (hasTtl ? fd['ttl'] as String? : null);
  final residentAge = _computeAge(ttlRaw);

  final noGenderTypes = {'ktp_kk', 'sktm', 'kematian', 'custom'};
  final residentGender = noGenderTypes.contains(letterType)
      ? '-'
      : (fd['gender'] as String? ?? '-');

  final rw = communityData['rw_number']?.toString() ?? '01';
  final rt = communityData['rt_number']?.toString() ?? '01';
  final kelurahan = communityData['kelurahan'] as String? ?? '';
  final kecamatan = communityData['kecamatan'] as String? ?? '';
  final kabupaten = communityData['kabupaten'] as String? ?? '';

  final residentAddress = 'RT $rt/RW $rw, Kel. $kelurahan, Kec. $kecamatan, $kabupaten';
  final purpose = _extractPurpose(letterType, fd);

  final generatedContent = LetterPdfGenerator.getTemplate(
    letterType: letterType,
    residentName: request.applicantName ?? '-',
    residentNik: residentNik,
    residentAge: residentAge,
    residentGender: residentGender,
    residentAddress: residentAddress,
    rtNumber: rt,
    rwNumber: rw,
    village: kelurahan,
    district: kecamatan,
    city: kabupaten,
    purpose: purpose,
  );

  // 4. Generate nomor surat
  final now = DateTime.now();
  final roman = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
  final letterNumber = '${now.millisecondsSinceEpoch % 1000}/RW-$rw/${roman[now.month - 1]}/${now.year}';

  // 5. Insert ke tabel letters
  final inserted = await client.from('letters').insert({
    'community_id': communityId,
    'resident_id': request.residentId,
    'letter_type': letterType,
    'letter_number': letterNumber,
    'purpose': purpose,
    'generated_content': generatedContent,
    'status': 'done',
  }).select('id').single();

  final letterId = inserted['id'] as String;

  // 6. Update status request ke verified
  await client
      .from('letter_requests')
      .update({
        'status': 'verified',
        'letter_id': letterId,
        'updated_at': now.toIso8601String(),
      })
      .eq('id', request.id)
      .eq('community_id', communityId);

  // 7. Notifikasi warga
  await insertNotification(
    client: client,
    userId: request.residentId,
    communityId: communityId,
    type: 'letter_request',
    title: 'Surat Kamu Sudah Siap',
    body: 'Surat ${request.typeLabel} kamu sudah diverifikasi dan siap diunduh.',
  );

  ref.invalidate(adminLetterRequestsProvider);
  ref.invalidate(myLetterRequestsProvider);
  ref.invalidate(myLettersProvider); // resident document list di ResidentLettersScreen
}
```

- [ ] **Step 7: Pastikan tidak ada compile error**

```bash
flutter analyze lib/features/layanan/providers/layanan_provider.dart
```

Expected: No issues found.

- [ ] **Step 8: Commit**

```bash
rtk git add lib/features/layanan/providers/layanan_provider.dart
rtk git commit -m "feat(layanan): add verifyAndGenerateLetter and rejectRequest to LayananService"
```

---

## Task 5: Tambah myLettersProvider

**Files:**
- Modify: `lib/features/letters/providers/letter_provider.dart`

- [ ] **Step 1: Tambah provider di akhir file (sebelum akhir file)**

Buka `lib/features/letters/providers/letter_provider.dart`. Tambahkan di bawah `generateLetterProvider`:

```dart
// Resident: dokumen surat milik saya
final myLettersProvider = FutureProvider.autoDispose<List<LetterModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final response = await client
      .from('letters')
      .select()
      .eq('resident_id', userId)
      .order('created_at', ascending: false);

  return (response as List).map((e) => LetterModel.fromMap(e)).toList();
});
```

- [ ] **Step 2: Pastikan tidak ada compile error**

```bash
flutter analyze lib/features/letters/providers/letter_provider.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
rtk git add lib/features/letters/providers/letter_provider.dart
rtk git commit -m "feat(letters): add myLettersProvider for resident document list"
```

---

## Task 6: Redesign RequestLetterScreen (Multi-Step Form)

**Files:**
- Modify: `lib/features/layanan/screens/request_letter_screen.dart` (tulis ulang total)

Logika utama: tiga step (`_Step.type`, `_Step.form`, `_Step.review`). Form field ditentukan oleh `_buildFormFields()` yang switch berdasarkan `_selectedType`. Semua input dikumpulkan ke `_formData` map lalu di-submit.

- [ ] **Step 1: Tulis ulang request_letter_screen.dart**

```dart
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
          _dropdownField('Hubungan Pelapor dengan Almarhum *', _RequestLetterScreenState._hubunganPelaporOptions, _hubunganPelapor, (v) => setState(() => _hubunganPelapor = v)),
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
        value: value,
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
```

- [ ] **Step 2: Pastikan tidak ada compile error**

```bash
flutter analyze lib/features/layanan/screens/request_letter_screen.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
rtk git add lib/features/layanan/screens/request_letter_screen.dart
rtk git commit -m "feat(layanan): redesign RequestLetterScreen with dynamic multi-step form"
```

---

## Task 7: Update AdminRequestsScreen

**Files:**
- Modify: `lib/features/layanan/screens/admin_requests_screen.dart`

- [ ] **Step 1: Update filter chips options dan labels**

Ganti konstanta `_filterOptions` dan `_filterLabels` (sekitar line 22-29):

```dart
static const _filterOptions = ['semua', 'pending', 'verified', 'completed', 'rejected'];
static const _filterLabels = {
  'semua': 'Semua',
  'pending': 'Menunggu',
  'verified': 'Surat Siap',
  'completed': 'Selesai',
  'rejected': 'Ditolak',
};
```

- [ ] **Step 2: Update `_statusColor()` di file ini**

Ganti method `_statusColor` (sekitar line 31-39):

```dart
Color _statusColor(String status) {
  return switch (status) {
    'pending'   => RukuninColors.warning,
    'verified'  => RukuninColors.success,
    'completed' => RukuninColors.darkTextTertiary,
    'rejected'  => RukuninColors.error,
    _           => RukuninColors.darkTextTertiary,
  };
}
```

- [ ] **Step 3: Ganti tombol "Buat Surat" di `_RequestCard` menjadi "Verifikasi"**

Di class `_RequestCard`, cari tombol pertama di Row actions (sekitar line 378-400). Ganti:

```dart
Expanded(
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: RukuninColors.brandGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    onPressed: () => context.push('/admin/layanan-verifikasi/${request.id}', extra: request),
    child: const Text('Verifikasi'),
  ),
),
```

- [ ] **Step 4: Hapus tombol "Update Status" dan widget `_UpdateStatusSheet`**

Hapus tombol kedua (OutlinedButton "Update Status") dari Row actions di `_RequestCard`.

Hapus seluruh class `_UpdateStatusSheet` dan `_UpdateStatusSheetState` dari file.

Hapus parameter `onUpdateStatus` dari `_RequestCard` dan semua pemanggilan `_showUpdateStatusSheet`.

- [ ] **Step 5: Pastikan tidak ada compile error**

```bash
flutter analyze lib/features/layanan/screens/admin_requests_screen.dart
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
rtk git add lib/features/layanan/screens/admin_requests_screen.dart
rtk git commit -m "feat(layanan): update AdminRequestsScreen - Verifikasi button, new filter chips, remove UpdateStatusSheet"
```

---

## Task 8: Buat VerifyRequestScreen

**Files:**
- Create: `lib/features/layanan/screens/verify_request_screen.dart`

- [ ] **Step 1: Buat file baru**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/tokens.dart';
import '../models/letter_request_model.dart';
import '../providers/layanan_provider.dart';

class VerifyRequestScreen extends ConsumerStatefulWidget {
  final LetterRequestModel request;
  const VerifyRequestScreen({super.key, required this.request});

  @override
  ConsumerState<VerifyRequestScreen> createState() => _VerifyRequestScreenState();
}

class _VerifyRequestScreenState extends ConsumerState<VerifyRequestScreen> {
  final _alasanCtrl = TextEditingController();
  bool _loadingAcc = false;
  bool _loadingTolak = false;

  @override
  void dispose() {
    _alasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _acc() async {
    setState(() => _loadingAcc = true);
    try {
      await ref.read(layananServiceProvider).verifyAndGenerateLetter(request: widget.request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surat berhasil di-generate!'), backgroundColor: RukuninColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: RukuninColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAcc = false);
    }
  }

  Future<void> _tolak() async {
    if (_alasanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan penolakan wajib diisi'), backgroundColor: RukuninColors.error),
      );
      return;
    }
    setState(() => _loadingTolak = true);
    try {
      await ref.read(layananServiceProvider).rejectRequest(
        requestId: widget.request.id,
        residentId: widget.request.residentId,
        communityId: widget.request.communityId,
        alasan: _alasanCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permohonan ditolak.'), backgroundColor: RukuninColors.warning),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: RukuninColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTolak = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final request = widget.request;
    final fd = request.formData ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Permohonan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info warga
            _card(
              isDark: isDark,
              title: 'Data Warga',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row('Nama', request.residentName ?? '-'),
                if (request.residentUnit != null) _row('Unit', request.residentUnit!),
                _row('Jenis Surat', request.typeLabel),
                _row('Diajukan', _formatDate(request.createdAt)),
              ]),
            ),
            const SizedBox(height: 12),

            // Data form yang diisi warga
            _card(
              isDark: isDark,
              title: 'Data yang Diisi Warga',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fd.isEmpty
                    ? [Text('Tidak ada data form.', style: GoogleFonts.plusJakartaSans(fontSize: 13))]
                    : fd.entries.map((e) => _row(_labelFor(e.key), e.value.toString())).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol ACC
            ElevatedButton.icon(
              onPressed: _loadingAcc || _loadingTolak ? null : _acc,
              style: ElevatedButton.styleFrom(
                backgroundColor: RukuninColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _loadingAcc
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_loadingAcc ? 'Memproses...' : 'ACC & Generate Surat', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),

            Divider(color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
            const SizedBox(height: 16),

            Text('Tolak Permohonan', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: RukuninColors.error)),
            const SizedBox(height: 8),
            TextField(
              controller: _alasanCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadingAcc || _loadingTolak ? null : _tolak,
              style: OutlinedButton.styleFrom(
                foregroundColor: RukuninColors.error,
                side: const BorderSide(color: RukuninColors.error),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loadingTolak
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: RukuninColors.error, strokeWidth: 2))
                  : Text('Tolak Permohonan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _card({required bool isDark, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 140, child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: RukuninColors.darkTextTertiary))),
      Expanded(child: Text(value.isEmpty ? '-' : value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  String _labelFor(String key) => const {
    'nik': 'NIK', 'ttl': 'TTL', 'gender': 'Jenis Kelamin', 'agama': 'Agama',
    'keperluan': 'Keperluan', 'alasan': 'Alasan', 'keterangan': 'Keterangan',
    'no_kk': 'No KK', 'pernyataan_kondisi': 'Kondisi Ekonomi', 'marital_status': 'Status Nikah',
    'pekerjaan': 'Pekerjaan', 'nama_usaha': 'Nama Usaha', 'jenis_usaha': 'Jenis Usaha',
    'alamat_usaha': 'Alamat Usaha', 'nama_ayah': 'Nama Ayah', 'nama_ibu': 'Nama Ibu',
    'nama_almarhum': 'Nama Almarhum', 'nik_almarhum': 'NIK Almarhum', 'ttl_almarhum': 'TTL Almarhum',
    'tanggal_meninggal': 'Tgl Meninggal', 'penyebab': 'Penyebab', 'hubungan_pelapor': 'Hubungan Pelapor',
  }[key] ?? key;
}
```

- [ ] **Step 2: Pastikan tidak ada compile error**

```bash
flutter analyze lib/features/layanan/screens/verify_request_screen.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
rtk git add lib/features/layanan/screens/verify_request_screen.dart
rtk git commit -m "feat(layanan): create VerifyRequestScreen with ACC and reject flow"
```

---

## Task 9: Buat ResidentLettersScreen

**Files:**
- Create: `lib/features/letters/screens/resident_letters_screen.dart`

- [ ] **Step 1: Buat file baru**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../../../app/tokens.dart';
import '../../../core/utils/letter_pdf_generator.dart';
import '../../../core/supabase/supabase_client.dart';
import '../providers/letter_provider.dart';

class ResidentLettersScreen extends ConsumerWidget {
  const ResidentLettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lettersAsync = ref.watch(myLettersProvider);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: Text('Dokumen Saya', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myLettersProvider),
          ),
        ],
      ),
      body: lettersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: RukuninColors.brandGreen)),
        error: (e, _) => Center(child: Text('Gagal memuat dokumen: $e', style: GoogleFonts.plusJakartaSans())),
        data: (letters) {
          if (letters.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.folder_open_outlined, size: 56, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                const SizedBox(height: 12),
                Text('Belum ada dokumen', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
                const SizedBox(height: 4),
                Text('Dokumen yang sudah diverifikasi admin akan muncul di sini', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
              ]),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: letters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _LetterCard(letter: letters[i]),
          );
        },
      ),
    );
  }
}

class _LetterCard extends StatefulWidget {
  final LetterModel letter;
  const _LetterCard({required this.letter});

  @override
  State<_LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<_LetterCard> {
  bool _generatingPdf = false;

  Future<void> _downloadPdf() async {
    if (widget.letter.generatedContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konten surat tidak tersedia'), backgroundColor: RukuninColors.error),
      );
      return;
    }

    setState(() => _generatingPdf = true);
    try {
      // Ambil data komunitas untuk PDF header
      final client = ProviderScope.containerOf(context).read(supabaseClientProvider);
      final profile = await client.from('profiles').select('community_id').eq('id', client.auth.currentUser!.id).single();
      final community = await client.from('communities').select('name, rt_number, rw_number, kelurahan, kecamatan, kabupaten, province, leader_name').eq('id', profile['community_id']).single();

      final bytes = await LetterPdfGenerator.generate(
        letterNumber: widget.letter.letterNumber,
        letterType: widget.letter.letterType,
        generatedContent: widget.letter.generatedContent!,
        resident: {'full_name': '-', 'nik': '-', 'gender': '-', 'date_of_birth': '', 'place_of_birth': '', 'religion': '-', 'marital_status': '-', 'occupation': '-', 'age': '-'},
        community: {
          'name': community['name'] ?? '',
          'rt_number': community['rt_number']?.toString() ?? '01',
          'rw_number': community['rw_number']?.toString() ?? '01',
          'village': community['kelurahan'] ?? '',
          'district': community['kecamatan'] ?? '',
          'city': community['kabupaten'] ?? '',
          'province': community['province'] ?? '',
          'leader_name': community['leader_name'] ?? 'Ketua RW',
        },
      );

      final safeName = (letterTypeLabels[widget.letter.letterType] ?? 'Surat').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      await FileSaver.instance.saveFile(name: 'Surat_$safeName.pdf', bytes: bytes, mimeType: MimeType.pdf);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF berhasil disimpan!'), backgroundColor: RukuninColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: RukuninColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final letter = widget.letter;
    final dateStr = DateFormat('d MMM y', 'id').format(letter.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(letterTypeLabels[letter.letterType] ?? letter.letterType, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('No. ${letter.letterNumber}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
        const SizedBox(height: 4),
        Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generatingPdf ? null : _downloadPdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: RukuninColors.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _generatingPdf
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.download, size: 18),
            label: Text(_generatingPdf ? 'Membuat PDF...' : 'Unduh PDF', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 2: Pastikan tidak ada compile error**

```bash
flutter analyze lib/features/letters/screens/resident_letters_screen.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
rtk git add lib/features/letters/screens/resident_letters_screen.dart
rtk git commit -m "feat(letters): create ResidentLettersScreen - Dokumen Saya for residents"
```

---

## Task 10: Update Router & Wire Semua Bersama

**Files:**
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Tambah import untuk screen baru**

Di bagian atas `router.dart`, tambahkan import:

```dart
import '../features/layanan/screens/verify_request_screen.dart';
import '../features/letters/screens/resident_letters_screen.dart';
```

- [ ] **Step 2: Tambah route admin verifikasi**

Cari section komentar `// Admin layanan full-screen routes (no bottom nav)` dan tambahkan route baru setelah `/admin/layanan-requests`:

```dart
GoRoute(
  path: '/admin/layanan-verifikasi/:id',
  builder: (context, state) {
    final request = state.extra as LetterRequestModel;
    return VerifyRequestScreen(request: request);
  },
),
```

- [ ] **Step 3: Tambah route resident dokumen saya**

Cari section komentar `// Layanan full-screen routes (no bottom nav)` dan tambahkan:

```dart
GoRoute(
  path: '/resident/dokumen-saya',
  builder: (context, state) => const ResidentLettersScreen(),
),
```

- [ ] **Step 4: Tambah import LetterRequestModel di router.dart jika belum ada**

```dart
import '../features/layanan/models/letter_request_model.dart';
```

- [ ] **Step 5: Tambah shortcut ke ResidentLettersScreen dari layanan_screen.dart**

Di `layanan_screen.dart`, cari class `_RequestCard` (atau widget yang merender tiap permohonan surat di tab surat warga). Tambahkan tombol shortcut **setelah `LinearProgressIndicator`** dan sebelum penutup `Column`:

```dart
// Tambahkan setelah blok LinearProgressIndicator yang sudah ada
if (request.status == 'verified' && request.letterId != null) ...[
  const SizedBox(height: 8),
  Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () => context.push('/resident/dokumen-saya'),
      icon: const Icon(Icons.download_outlined, size: 16),
      label: Text('Lihat Dokumen', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
      style: TextButton.styleFrom(foregroundColor: RukuninColors.brandGreen, padding: EdgeInsets.zero),
    ),
  ),
],
```

- [ ] **Step 6: Pastikan tidak ada compile error di seluruh proyek**

```bash
flutter analyze lib/
```

Expected: No issues found.

- [ ] **Step 7: Final build check**

```bash
flutter build apk --debug 2>&1 | tail -20
```

Expected: Build berhasil tanpa error.

- [ ] **Step 8: Commit**

```bash
rtk git add lib/app/router.dart lib/features/layanan/screens/layanan_screen.dart
rtk git commit -m "feat(router): add /admin/layanan-verifikasi and /resident/dokumen-saya routes"
```

---

## Checklist Verifikasi Manual (End-to-End)

Setelah semua task selesai, verifikasi flow end-to-end di device/emulator:

- [ ] Resident: buka Layanan → Permohonan Surat → pilih "Keterangan Domisili" → isi form → review → kirim → muncul di daftar status "Menunggu Verifikasi"
- [ ] Admin: buka Permohonan Surat Warga → card baru muncul → tap "Verifikasi" → data warga tampil rapi → tap "ACC & Generate Surat" → sukses
- [ ] Resident: status berubah jadi "Surat Siap" → tap "Lihat Dokumen" → ResidentLettersScreen terbuka → dokumen muncul → tap "Unduh PDF" → PDF ter-download
- [ ] Admin: tap "Verifikasi" → isi alasan → tap "Tolak" → sukses → Resident: status berubah jadi "Ditolak" dengan alasan tampil
- [ ] Repeat dengan jenis surat "Kematian" untuk verifikasi field almarhum ter-handle dengan benar
