# Layanan & Pengaduan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tambahkan fitur "Layanan & Pengaduan" di sisi warga (2 tab: Surat & Pengaduan) yang terintegrasi penuh dengan admin side.

**Architecture:** Warga mengajukan permohonan surat (`letter_requests`) lewat form sederhana (jenis surat + keperluan + catatan). Admin melihat antrian di `/admin/layanan-requests` → tap "Buat Surat" → masuk ke `CreateLetterScreen` yang sudah ada dengan data **pre-filled** dari request warga. Setelah surat dibuat, `letter_request.letter_id` otomatis terisi + status berubah `ready` + warga dapat notifikasi. Pengaduan (`complaints`) dikelola admin secara terpisah. Status update oleh admin selalu trigger notifikasi ke warga via tabel `notifications` yang sudah ada.

**Tech Stack:** Flutter + Riverpod (FutureProvider.autoDispose, AsyncNotifier) + Supabase + GoRouter. Pattern: plain Dart model (fromMap/toMap), konsisten dengan codebase yang ada. Warna: AppColors dari `lib/app/theme.dart`. Font: Plus Jakarta Sans (body), Playfair Display (headline besar).

---

## File Structure

### Baru (create)
| File | Tanggung Jawab |
|------|----------------|
| `supabase/migrations/20260319_layanan_pengaduan.sql` | Tabel `letter_requests` + `complaints` + RLS |
| `lib/features/layanan/models/letter_request_model.dart` | `LetterRequestModel` (fromMap) |
| `lib/features/layanan/models/complaint_model.dart` | `ComplaintModel` (fromMap) |
| `lib/features/layanan/providers/layanan_provider.dart` | Semua provider layanan & pengaduan |
| `lib/features/layanan/screens/layanan_screen.dart` | Main screen resident — 2 tab (Surat / Pengaduan) |
| `lib/features/layanan/screens/request_letter_screen.dart` | Form permohonan surat baru |
| `lib/features/layanan/screens/complaint_form_screen.dart` | Form buat pengaduan baru |
| `lib/features/layanan/screens/admin_requests_screen.dart` | Admin — daftar & kelola permohonan surat |
| `lib/features/layanan/screens/admin_complaints_screen.dart` | Admin — daftar & kelola pengaduan |
| `test/features/layanan/models_test.dart` | Unit test untuk kedua model |

### Dimodifikasi (modify)
| File | Perubahan |
|------|-----------|
| `lib/shell/resident_shell.dart` | Tambah tab ke-6: Layanan (`/resident/layanan`) |
| `lib/app/router.dart` | Tambah route baru: `/resident/layanan`, `/resident/layanan/permohonan`, `/resident/layanan/pengaduan-baru`, `/admin/layanan-requests`, `/admin/pengaduan`, `/admin/surat/buat` (pre-filled) |
| `lib/features/letters/screens/create_letter_screen.dart` | Tambah 4 parameter opsional: `prefilledResidentId`, `prefilledLetterType`, `prefilledPurpose`, `fromRequestId` — untuk integrasi dari admin request screen |
| `lib/features/dashboard/screens/admin_dashboard_screen.dart` | Tambah section "Layanan Warga" dengan 2 quick-action card |

---

## Referensi Pola yang Harus Diikuti

Sebelum mulai, baca file-file ini untuk memahami pola yang sudah ada:
- **Model:** `lib/features/letters/providers/letter_provider.dart` — pola `fromMap`, relasi `profiles`
- **Provider:** `lib/features/marketplace/providers/marketplace_provider.dart` — pola FutureProvider + AsyncNotifier/service
- **Screen resident:** `lib/features/resident_portal/screens/resident_home_screen.dart` — layout, warna, font
- **Screen admin list:** `lib/features/letters/screens/letters_screen.dart` — pola card admin
- **Notifikasi:** `lib/features/notifications/providers/notifications_provider.dart` — pola insert notif
- **Router:** `lib/app/router.dart` — cara daftarkan route baru di dalam/luar ShellRoute

---

## Task 1: Database Migration

**Files:**
- Create: `supabase/migrations/20260319_layanan_pengaduan.sql`

### Skema

**`letter_requests`** — permohonan surat dari warga (antrian masuk sebelum admin proses jadi `letters`)
```
id            uuid PK default uuid_generate_v4()
community_id  uuid FK communities ON DELETE CASCADE
resident_id   uuid FK profiles ON DELETE CASCADE
letter_type   text NOT NULL  -- sama dengan letterTypeLabels: ktp_kk, domisili, sktm, skck, kematian, nikah, sku, custom
purpose       text           -- tujuan/keperluan
notes         text           -- catatan tambahan dari warga
status        text NOT NULL DEFAULT 'pending'
              CHECK ('pending','in_progress','ready','completed','rejected')
admin_notes   text           -- catatan balasan dari admin
letter_id     uuid FK letters NULL  -- diisi admin saat surat sudah dibuat
created_at    timestamptz DEFAULT now()
updated_at    timestamptz DEFAULT now()
```

**`complaints`** — pengaduan warga
```
id            uuid PK default uuid_generate_v4()
community_id  uuid FK communities ON DELETE CASCADE
resident_id   uuid FK profiles ON DELETE CASCADE
title         text NOT NULL
description   text NOT NULL
category      text NOT NULL DEFAULT 'lainnya'
              CHECK ('infrastruktur','keamanan','kebersihan','sosial','lainnya')
status        text NOT NULL DEFAULT 'pending'
              CHECK ('pending','in_progress','resolved','rejected')
admin_notes   text
photo_url     text
created_at    timestamptz DEFAULT now()
updated_at    timestamptz DEFAULT now()
```

- [ ] **Step 1: Tulis SQL migration**

```sql
-- ============================================================
-- Layanan & Pengaduan
-- ============================================================

-- 1. Tabel permohonan surat dari warga
CREATE TABLE public.letter_requests (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  community_id  uuid NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  resident_id   uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  letter_type   text NOT NULL,
  purpose       text,
  notes         text,
  status        text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','in_progress','ready','completed','rejected')),
  admin_notes   text,
  letter_id     uuid REFERENCES public.letters(id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- 2. Tabel pengaduan warga
CREATE TABLE public.complaints (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  community_id  uuid NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  resident_id   uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title         text NOT NULL,
  description   text NOT NULL,
  category      text NOT NULL DEFAULT 'lainnya'
                CHECK (category IN ('infrastruktur','keamanan','kebersihan','sosial','lainnya')),
  status        text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','in_progress','resolved','rejected')),
  admin_notes   text,
  photo_url     text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- 3. Enable RLS
ALTER TABLE public.letter_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;

-- 4. RLS letter_requests
CREATE POLICY "Admin dapat kelola semua permohonan surat"
  ON public.letter_requests FOR ALL
  USING (is_admin_of(community_id));

CREATE POLICY "Warga dapat lihat permohonan sendiri"
  ON public.letter_requests FOR SELECT
  USING (resident_id = auth.uid());

CREATE POLICY "Warga dapat buat permohonan"
  ON public.letter_requests FOR INSERT
  WITH CHECK (resident_id = auth.uid() AND community_id = my_community_id());

-- 5. RLS complaints
CREATE POLICY "Admin dapat kelola semua pengaduan"
  ON public.complaints FOR ALL
  USING (is_admin_of(community_id));

CREATE POLICY "Warga dapat lihat pengaduan sendiri"
  ON public.complaints FOR SELECT
  USING (resident_id = auth.uid());

CREATE POLICY "Warga dapat buat pengaduan"
  ON public.complaints FOR INSERT
  WITH CHECK (resident_id = auth.uid() AND community_id = my_community_id());
```

Tambahkan juga di akhir SQL (sebelum dijalankan):
```sql
-- 6. Extend notifications.type CHECK agar bisa terima tipe baru
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('payment','announcement','join_request','join_approved','join_rejected','letter_request','complaint'));
```

- [ ] **Step 2: Jalankan di Supabase SQL Editor**

Paste seluruh SQL di atas ke Supabase Dashboard → SQL Editor → Run.
Expected: "Success. No rows returned"

- [ ] **Step 3: Verifikasi tabel terbuat**

Di Supabase Table Editor, cek tabel `letter_requests` dan `complaints` muncul.

---

## Task 2: Models

**Files:**
- Create: `lib/features/layanan/models/letter_request_model.dart`
- Create: `lib/features/layanan/models/complaint_model.dart`
- Create: `test/features/layanan/models_test.dart`

Pola: plain Dart class, fromMap (tidak pakai Freezed), konsisten dengan `LetterModel`.

- [ ] **Step 1: Tulis failing test untuk LetterRequestModel**

```dart
// test/features/layanan/models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/letter_request_model.dart';
import 'package:rukunin/features/layanan/models/complaint_model.dart';

void main() {
  group('LetterRequestModel', () {
    final map = {
      'id': 'req-1',
      'community_id': 'com-1',
      'resident_id': 'res-1',
      'letter_type': 'domisili',
      'purpose': 'Melamar kerja',
      'notes': null,
      'status': 'pending',
      'admin_notes': null,
      'letter_id': null,
      'created_at': '2026-03-19T10:00:00.000Z',
      'updated_at': '2026-03-19T10:00:00.000Z',
      'profiles': {'full_name': 'Budi Santoso', 'unit_number': '12'},
    };

    test('fromMap parses correctly', () {
      final model = LetterRequestModel.fromMap(map);
      expect(model.id, 'req-1');
      expect(model.letterType, 'domisili');
      expect(model.status, 'pending');
      expect(model.residentName, 'Budi Santoso');
    });

    test('progressPercent returns correct value', () {
      expect(LetterRequestModel.fromMap({...map, 'status': 'pending'}).progressPercent, 0.25);
      expect(LetterRequestModel.fromMap({...map, 'status': 'in_progress'}).progressPercent, 0.60);
      expect(LetterRequestModel.fromMap({...map, 'status': 'ready'}).progressPercent, 0.85);
      expect(LetterRequestModel.fromMap({...map, 'status': 'completed'}).progressPercent, 1.0);
      expect(LetterRequestModel.fromMap({...map, 'status': 'rejected'}).progressPercent, 0.0);
    });

    test('isActive returns true only for non-terminal statuses', () {
      expect(LetterRequestModel.fromMap({...map, 'status': 'pending'}).isActive, true);
      expect(LetterRequestModel.fromMap({...map, 'status': 'completed'}).isActive, false);
      expect(LetterRequestModel.fromMap({...map, 'status': 'rejected'}).isActive, false);
    });
  });

  group('ComplaintModel', () {
    final map = {
      'id': 'cmp-1',
      'community_id': 'com-1',
      'resident_id': 'res-1',
      'title': 'Jalan berlubang',
      'description': 'Di depan blok A ada lubang besar',
      'category': 'infrastruktur',
      'status': 'pending',
      'admin_notes': null,
      'photo_url': null,
      'created_at': '2026-03-19T10:00:00.000Z',
      'updated_at': '2026-03-19T10:00:00.000Z',
      'profiles': {'full_name': 'Siti Rahayu', 'unit_number': '5'},
    };

    test('fromMap parses correctly', () {
      final model = ComplaintModel.fromMap(map);
      expect(model.id, 'cmp-1');
      expect(model.category, 'infrastruktur');
      expect(model.status, 'pending');
    });

    test('categoryLabel returns correct label', () {
      expect(ComplaintModel.fromMap({...map, 'category': 'infrastruktur'}).categoryLabel, 'Infrastruktur');
      expect(ComplaintModel.fromMap({...map, 'category': 'keamanan'}).categoryLabel, 'Keamanan');
    });
  });
}
```

- [ ] **Step 2: Run test — verifikasi FAIL**

```bash
flutter test test/features/layanan/models_test.dart
```
Expected: FAIL — "Target file ... does not exist"

- [ ] **Step 3: Implement LetterRequestModel**

```dart
// lib/features/layanan/models/letter_request_model.dart

const letterRequestStatusLabels = {
  'pending': 'Menunggu',
  'in_progress': 'Diproses',
  'ready': 'Siap Diambil',
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
    );
  }

  String get typeLabel => letterRequestTypeLabels[letterType] ?? letterType;
  String get statusLabel => letterRequestStatusLabels[status] ?? status;
  bool get isActive => status != 'completed' && status != 'rejected';

  double get progressPercent => switch (status) {
    'pending'     => 0.25,
    'in_progress' => 0.60,
    'ready'       => 0.85,
    'completed'   => 1.0,
    _             => 0.0,
  };
}
```

- [ ] **Step 4: Implement ComplaintModel**

```dart
// lib/features/layanan/models/complaint_model.dart

const complaintStatusLabels = {
  'pending': 'Menunggu',
  'in_progress': 'Ditindaklanjuti',
  'resolved': 'Selesai',
  'rejected': 'Ditolak',
};

const complaintCategoryLabels = {
  'infrastruktur': 'Infrastruktur',
  'keamanan': 'Keamanan',
  'kebersihan': 'Kebersihan',
  'sosial': 'Sosial',
  'lainnya': 'Lainnya',
};

class ComplaintModel {
  final String id;
  final String communityId;
  final String residentId;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? adminNotes;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? residentName;
  final String? residentUnit;

  const ComplaintModel({
    required this.id,
    required this.communityId,
    required this.residentId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.adminNotes,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.residentName,
    this.residentUnit,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return ComplaintModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      residentId: map['resident_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String? ?? 'lainnya',
      status: map['status'] as String? ?? 'pending',
      adminNotes: map['admin_notes'] as String?,
      photoUrl: map['photo_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      residentName: profile?['full_name'] as String?,
      residentUnit: profile?['unit_number'] as String?,
    );
  }

  String get categoryLabel => complaintCategoryLabels[category] ?? category;
  String get statusLabel => complaintStatusLabels[status] ?? status;
  bool get isOpen => status != 'resolved' && status != 'rejected';
}
```

- [ ] **Step 5: Run test — verifikasi PASS**

```bash
flutter test test/features/layanan/models_test.dart
```
Expected: PASS (semua 5 test hijau)

- [ ] **Step 6: Commit**

```bash
git add lib/features/layanan/models/ test/features/layanan/
git commit -m "feat: add LetterRequestModel and ComplaintModel for layanan feature"
```

---

## Task 3: Providers

**Files:**
- Create: `lib/features/layanan/providers/layanan_provider.dart`

Pola: ikuti `marketplace_provider.dart` — FutureProvider.autoDispose untuk fetch, class service untuk mutations.

- [ ] **Step 1: Implement providers**

```dart
// lib/features/layanan/providers/layanan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/letter_request_model.dart';
import '../models/complaint_model.dart';

// ── Resident: permohonan surat saya ──────────────────────────
final myLetterRequestsProvider =
    FutureProvider.autoDispose<List<LetterRequestModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await client
      .from('letter_requests')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('resident_id', userId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => LetterRequestModel.fromMap(e)).toList();
});

// ── Resident: pengaduan saya ─────────────────────────────────
final myComplaintsProvider =
    FutureProvider.autoDispose<List<ComplaintModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await client
      .from('complaints')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('resident_id', userId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => ComplaintModel.fromMap(e)).toList();
});

// ── Admin: semua permohonan surat ────────────────────────────
final adminLetterRequestsProvider =
    FutureProvider.autoDispose<List<LetterRequestModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();
  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return [];

  final res = await client
      .from('letter_requests')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('community_id', communityId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => LetterRequestModel.fromMap(e)).toList();
});

// ── Admin: semua pengaduan ───────────────────────────────────
final adminComplaintsProvider =
    FutureProvider.autoDispose<List<ComplaintModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();
  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return [];

  final res = await client
      .from('complaints')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('community_id', communityId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => ComplaintModel.fromMap(e)).toList();
});

// ── Service (mutations) ──────────────────────────────────────
final layananServiceProvider = Provider((ref) => LayananService(ref: ref));

class LayananService {
  final Ref ref;
  const LayananService({required this.ref});

  // Warga buat permohonan surat baru
  Future<void> createLetterRequest({
    required String communityId,
    required String residentId,
    required String letterType,
    String? purpose,
    String? notes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('letter_requests').insert({
      'community_id': communityId,
      'resident_id': residentId,
      'letter_type': letterType,
      'purpose': purpose,
      'notes': notes,
    });
    ref.invalidate(myLetterRequestsProvider);
  }

  // Warga buat pengaduan baru
  Future<void> createComplaint({
    required String communityId,
    required String residentId,
    required String title,
    required String description,
    required String category,
    String? photoUrl,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('complaints').insert({
      'community_id': communityId,
      'resident_id': residentId,
      'title': title,
      'description': description,
      'category': category,
      'photo_url': photoUrl,
    });
    ref.invalidate(myComplaintsProvider);
  }

  // Admin update status permohonan surat
  Future<void> updateLetterRequestStatus({
    required String requestId,
    required String residentId,
    required String communityId,
    required String newStatus,
    String? adminNotes,
    String? letterId,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('letter_requests').update({
      'status': newStatus,
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (letterId != null) 'letter_id': letterId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    // Gunakan helper yang sudah ada di notifications_provider.dart
    await insertNotification(
      client: client,
      userId: residentId,
      communityId: communityId,
      type: 'letter_request',
      title: 'Update Permohonan Surat',
      body: 'Status permohonan surat kamu diperbarui: ${letterRequestStatusLabels[newStatus] ?? newStatus}',
    );
    ref.invalidate(adminLetterRequestsProvider);
  }

  // Admin update status pengaduan
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String residentId,
    required String communityId,
    required String newStatus,
    String? adminNotes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('complaints').update({
      'status': newStatus,
      if (adminNotes != null) 'admin_notes': adminNotes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', complaintId);

    await insertNotification(
      client: client,
      userId: residentId,
      communityId: communityId,
      type: 'complaint',
      title: 'Update Pengaduan',
      body: 'Status pengaduan kamu diperbarui: ${complaintStatusLabels[newStatus] ?? newStatus}',
    );
    ref.invalidate(adminComplaintsProvider);
  }
}

// PENTING: tambahkan import ini di layanan_provider.dart:
// import '../../notifications/providers/notifications_provider.dart';
```

- [ ] **Step 2: Run `flutter analyze lib/features/layanan/providers/`**

```bash
flutter analyze lib/features/layanan/providers/layanan_provider.dart
```
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/layanan/providers/
git commit -m "feat: add layanan providers and service"
```

---

## Task 4: Resident Layanan Screen (Main)

**Files:**
- Create: `lib/features/layanan/screens/layanan_screen.dart`

Layout (adaptasi dari HTML mockup, menggunakan AppColors & Plus Jakarta Sans):
- AppBar dengan judul "Layanan & Pengaduan" + help icon
- TabBar 2 tab: "Surat" | "Pengaduan"
- **Tab Surat:**
  - Section "Permohonan Aktif" — list `myLetterRequestsProvider` yang `isActive == true`
  - Card permohonan: nomor urut, tanggal, tipe surat, status badge, progress bar, tombol Detail
  - Section "Buat Permohonan Baru" — grid 2x2 shortcut (Domisili, Pengantar, KTP/KK, Lainnya)
  - Banner "Butuh bantuan?" — kuning, "Hubungi Admin via WhatsApp" → `launchUrl(wa.me/adminPhone)`
- **Tab Pengaduan:**
  - Button "Buat Pengaduan Baru" (primary)
  - List `myComplaintsProvider` — card dengan title, kategori, status badge, tanggal

**Warna status badge:**
- `pending` → `AppColors.warning` (oranye)
- `in_progress` → `Color(0xFF3B82F6)` (biru)
- `ready` → `AppColors.success` (hijau muda)
- `completed` → `AppColors.success`
- `rejected` → `AppColors.error`

- [ ] **Step 1: Implement `LayananScreen`**

Buat file dengan struktur:
```dart
// lib/features/layanan/screens/layanan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../providers/layanan_provider.dart';
import '../models/letter_request_model.dart';
import '../models/complaint_model.dart';

class LayananScreen extends ConsumerStatefulWidget {
  const LayananScreen({super.key});

  @override
  ConsumerState<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends ConsumerState<LayananScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: Text('Layanan & Pengaduan',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [Tab(text: 'Surat'), Tab(text: 'Pengaduan')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SuratTab(),
          _PengaduanTab(),
        ],
      ),
    );
  }
}

// ── _SuratTab ──────────────────────────────────────────────
// Widget _SuratTab: tampilkan daftar permohonan aktif + grid shortcut + banner bantuan
// Gunakan ref.watch(myLetterRequestsProvider) untuk list
// Gunakan context.push('/resident/layanan/permohonan?type=...') untuk shortcut grid

// ── _PengaduanTab ──────────────────────────────────────────
// Widget _PengaduanTab: tampilkan daftar pengaduan + FAB atau button buat baru
// Gunakan ref.watch(myComplaintsProvider)

// ── _RequestCard ───────────────────────────────────────────
// Widget card untuk permohonan surat:
// - Nomor (SRT-XXX berdasarkan urutan/createdAt), tipe surat, tanggal
// - Status badge, progress bar (LinearProgressIndicator)
// - Tombol "Detail" jika admin sudah isi admin_notes

// ── _ComplaintCard ─────────────────────────────────────────
// Widget card pengaduan: title, kategori chip, status badge, tanggal

// ── _StatusBadge ───────────────────────────────────────────
// Widget badge warna berdasarkan status string

// ── _NewRequestGrid ────────────────────────────────────────
// GridView 2 kolom, 4 item: Domisili, Pengantar, KTP/KK, Lainnya
// Tap → context.push('/resident/layanan/permohonan') dengan extra type

// ── _HelpBanner ────────────────────────────────────────────
// Container warna AppColors.primary, teks putih, tombol "Chat Admin"
// Tap → launchUrl wa.me/<adminPhone>
// adminPhone diambil dari communities (perlu provider kecil atau embed di layananProvider)
```

> **Catatan implementasi:** Untuk nomor surat (SRT-001), gunakan index dari list yang disorting by createdAt ascending: `'SRT-${(index + 1).toString().padLeft(3, '0')}'`.
> Untuk `adminPhone`, tambahkan satu query kecil di `layananServiceProvider` atau buat `FutureProvider` tersendiri yang fetch `communities.admin_phone` berdasarkan `community_id` warga.

- [ ] **Step 2: `flutter analyze lib/features/layanan/screens/layanan_screen.dart`**

Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/layanan/screens/layanan_screen.dart
git commit -m "feat: add LayananScreen with Surat and Pengaduan tabs"
```

---

## Task 5: Form Permohonan Surat Baru

**Files:**
- Create: `lib/features/layanan/screens/request_letter_screen.dart`

- [ ] **Step 1: Implement screen**

```dart
// lib/features/layanan/screens/request_letter_screen.dart
// Parameter (via constructor): String? initialType (dari shortcut grid)
// Form fields:
//   - Dropdown jenis surat (letterRequestTypeLabels) — pre-selected jika initialType != null
//   - TextFormField "Tujuan/Keperluan" (wajib)
//   - TextFormField "Catatan Tambahan" (opsional, multiline)
// Submit: LayananService.createLetterRequest(...)
// Setelah sukses: Navigator.pop(context), invalidate provider, tampilkan snackbar

// Pola submit:
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _loading = true);
  try {
    final service = ref.read(layananServiceProvider);
    // Fetch communityId dan residentId dari currentUser
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser!.id;
    final profile = await client.from('profiles')
        .select('community_id').eq('id', userId).single();
    await service.createLetterRequest(
      communityId: profile['community_id'],
      residentId: userId,
      letterType: _selectedType!,
      purpose: _purposeCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permohonan berhasil dikirim!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
      );
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/layanan/screens/request_letter_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/layanan/screens/request_letter_screen.dart
git commit -m "feat: add RequestLetterScreen form for resident"
```

---

## Task 6: Form Pengaduan Baru

**Files:**
- Create: `lib/features/layanan/screens/complaint_form_screen.dart`

- [ ] **Step 1: Implement screen**

```dart
// lib/features/layanan/screens/complaint_form_screen.dart
// Form fields:
//   - TextFormField "Judul Pengaduan" (wajib, max 100 char)
//   - DropdownButtonFormField "Kategori" dari complaintCategoryLabels (wajib)
//   - TextFormField "Deskripsi" (wajib, multiline, min 20 char)
// Submit: LayananService.createComplaint(...)
// Note: photo_url diabaikan dulu di fase ini (Phase 5 dapat ditambah)
```

- [ ] **Step 2: Analyze + Commit**

```bash
flutter analyze lib/features/layanan/screens/complaint_form_screen.dart
git add lib/features/layanan/screens/complaint_form_screen.dart
git commit -m "feat: add ComplaintFormScreen for resident"
```

---

## Task 7: Navigation — Tambah Tab Layanan

**Files:**
- Modify: `lib/shell/resident_shell.dart`
- Modify: `lib/app/router.dart`

ResidentShell saat ini: 5 tab (Beranda, Info RT, Pasar, Tagihan, Akun).
Tambah tab ke-6 "Layanan" di posisi 2 (setelah Info RT).

- [ ] **Step 1: Update `resident_shell.dart`**

Tambah index mapping:
```dart
} else if (location.startsWith('/resident/layanan')) {
  currentIndex = 2;
} else if (location.startsWith('/resident/marketplace')) {
  currentIndex = 3;  // geser dari 2 ke 3
} else if (location.startsWith('/resident/tagihan')) {
  currentIndex = 4;  // geser dari 3 ke 4
} else if (location.startsWith('/resident/akun')) {
  currentIndex = 5;  // geser dari 4 ke 5
}
```

Tambah `_NavItem` baru:
```dart
_NavItem(
  icon: Icons.article_outlined,
  label: 'Layanan',
  isSelected: currentIndex == 2,
  onTap: () => context.go('/resident/layanan'),
),
```

- [ ] **Step 2: Update `router.dart`**

Import dan tambah route di dalam ResidentShell:
```dart
import '../features/layanan/screens/layanan_screen.dart';
import '../features/layanan/screens/request_letter_screen.dart';
import '../features/layanan/screens/complaint_form_screen.dart';
import '../features/layanan/screens/admin_requests_screen.dart';
import '../features/layanan/screens/admin_complaints_screen.dart';
```

Di dalam `ResidentShell` ShellRoute, tambah:
```dart
GoRoute(
  path: '/resident/layanan',
  builder: (context, state) => const LayananScreen(),
),
```

Di luar ShellRoute (full-screen), tambah:
```dart
GoRoute(
  path: '/resident/layanan/permohonan',
  builder: (context, state) {
    final type = state.uri.queryParameters['type'];
    return RequestLetterScreen(initialType: type);
  },
),
GoRoute(
  path: '/resident/layanan/pengaduan-baru',
  builder: (context, state) => const ComplaintFormScreen(),
),
GoRoute(
  path: '/admin/layanan-requests',
  builder: (context, state) => const AdminRequestsScreen(),
),
GoRoute(
  path: '/admin/pengaduan',
  builder: (context, state) => const AdminComplaintsScreen(),
),
// Route admin buat surat dengan pre-filled dari request warga
// Daftarkan di luar ShellRoute (full-screen, ada back button)
GoRoute(
  path: '/admin/surat/buat',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return CreateLetterScreen(
      prefilledResidentId: extra?['prefilledResidentId'] as String?,
      prefilledLetterType: extra?['prefilledLetterType'] as String?,
      prefilledPurpose: extra?['prefilledPurpose'] as String?,
      fromRequestId: extra?['fromRequestId'] as String?,
    );
  },
),
```

- [ ] **Step 3: `flutter analyze lib/shell/ lib/app/router.dart`**

Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/shell/resident_shell.dart lib/app/router.dart
git commit -m "feat: add Layanan tab to ResidentShell and register routes"
```

---

## Task 8: Modifikasi `CreateLetterScreen` — Tambah Parameter Pre-filled

**Files:**
- Modify: `lib/features/letters/screens/create_letter_screen.dart`

Tujuan: agar admin yang datang dari request warga tidak perlu isi ulang data yang sudah ada di request.

- [ ] **Step 1: Tambah 4 parameter opsional ke constructor**

```dart
class CreateLetterScreen extends ConsumerStatefulWidget {
  final String? prefilledResidentId;  // auto-pilih warga di dropdown
  final String? prefilledLetterType;  // auto-set _letterType
  final String? prefilledPurpose;     // auto-isi _purposeCtrl
  final String? fromRequestId;        // jika tidak null → link ke letter_request setelah selesai

  const CreateLetterScreen({
    super.key,
    this.prefilledResidentId,
    this.prefilledLetterType,
    this.prefilledPurpose,
    this.fromRequestId,
  });
  // ...
}
```

- [ ] **Step 2: Apply pre-filled data di `initState`**

Di `_CreateLetterScreenState.initState()`, setelah inisialisasi biasa:
```dart
@override
void initState() {
  super.initState();
  if (widget.prefilledLetterType != null) {
    _letterType = widget.prefilledLetterType!;
  }
  if (widget.prefilledPurpose != null) {
    _purposeCtrl.text = widget.prefilledPurpose!;
  }
  // prefilledResidentId digunakan saat dropdown warga dimuat:
  // set _selectedResidentId = widget.prefilledResidentId setelah data warga loaded
}
```

- [ ] **Step 3: Setelah surat berhasil dibuat — link ke `letter_request` jika ada `fromRequestId`**

Cari tempat di `_CreateLetterScreenState` di mana surat berhasil disimpan ke DB (setelah insert ke `letters`). Tambahkan:

```dart
// Setelah insert letter berhasil dan dapat letter id:
if (widget.fromRequestId != null) {
  final service = ref.read(layananServiceProvider);
  await service.updateLetterRequestStatus(
    requestId: widget.fromRequestId!,
    residentId: <resident_id dari letter yang baru dibuat>,
    communityId: <community_id>,
    newStatus: 'ready',
    letterId: <id surat baru>,
  );
}
```

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/features/letters/screens/create_letter_screen.dart
```
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/features/letters/screens/create_letter_screen.dart
git commit -m "feat: add prefilled params to CreateLetterScreen for integration with letter requests"
```

---

## Task 9: Admin — Permohonan Surat Screen

**Files:**
- Create: `lib/features/layanan/screens/admin_requests_screen.dart`

Layout:
- AppBar "Permohonan Surat Warga"
- Filter chip row: Semua | Menunggu | Diproses | Siap | Selesai
- List card per request:
  - Nama warga, unit, tipe surat, tanggal masuk
  - Status badge (warna sama dengan resident side)
  - **Tombol "Buat Surat"** (primary, kuning) → navigate ke `CreateLetterScreen` dengan pre-filled data
  - Tombol "Update Status" (secondary) → bottom sheet untuk update status manual + admin_notes

- [ ] **Step 1: Implement screen**

```dart
// lib/features/layanan/screens/admin_requests_screen.dart
// ref.watch(adminLetterRequestsProvider)
// Filter by status menggunakan local state String _filter = 'semua'

// Tombol "Buat Surat" pada card request:
ElevatedButton.icon(
  onPressed: () => context.push(
    '/admin/surat/buat',
    extra: {
      'prefilledResidentId': request.residentId,
      'prefilledLetterType': request.letterType,
      'prefilledPurpose': request.purpose,
      'fromRequestId': request.id,
    },
  ),
  icon: const Icon(Icons.edit_document),
  label: const Text('Buat Surat'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
  ),
),

// Tombol "Update Status" → bottom sheet:
//   - DropdownButton status (in_progress, ready, completed, rejected)
//   - TextField admin_notes
//   - Button Simpan → service.updateLetterRequestStatus(...)
```

**Route `/admin/surat/buat` perlu ditambahkan di `router.dart` (Task 10) untuk terima `extra` Map.**

- [ ] **Step 2: Tambah akses dari admin — di `AdminDashboardScreen`**

Buka `lib/features/dashboard/screens/admin_dashboard_screen.dart`.

Tambahkan section baru di bawah stat cards (sebelum section tagihan/laporan), berisi dua card "Layanan Warga":

```dart
// Tambahkan di dalam ListView di AdminDashboardScreen.build()
// Setelah stat cards yang sudah ada:

const SizedBox(height: 20),
Text(
  'Layanan Warga',
  style: GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w700, color: _C.textMuted),
),
const SizedBox(height: 10),
Row(
  children: [
    Expanded(
      child: _QuickActionCard(
        icon: Icons.article_outlined,
        label: 'Permohonan\nSurat',
        onTap: () => context.push('/admin/layanan-requests'),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _QuickActionCard(
        icon: Icons.report_problem_outlined,
        label: 'Pengaduan\nWarga',
        onTap: () => context.push('/admin/pengaduan'),
      ),
    ),
  ],
),

// Widget _QuickActionCard (tambahkan di bawah file, konsisten dengan _C colors):
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.yellow2.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _C.yellow2, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.dark)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze + Commit**

```bash
flutter analyze lib/features/layanan/screens/admin_requests_screen.dart
git add lib/features/layanan/screens/admin_requests_screen.dart
git commit -m "feat: add AdminRequestsScreen for managing letter requests"
```

---

## Task 10: Admin — Pengaduan Screen

**Files:**
- Create: `lib/features/layanan/screens/admin_complaints_screen.dart`

Layout identik dengan AdminRequestsScreen, tapi untuk complaints:
- Filter chip: Semua | Menunggu | Ditindaklanjuti | Selesai
- Card: judul, kategori chip, nama warga, tanggal, status badge
- Jika ada `photo_url` → tampilkan thumbnail
- Bottom sheet update status: dropdown + admin_notes

- [ ] **Step 1: Implement screen**

```dart
// ref.watch(adminComplaintsProvider)
// Pola update identik dengan admin_requests_screen.dart
```

- [ ] **Step 2: Akses admin sudah tersedia**

Kedua card ("Permohonan Surat" dan "Pengaduan Warga") sudah ditambahkan di AdminDashboardScreen pada Task 8 Step 2. Tidak ada perubahan tambahan di Task ini untuk entry point.

- [ ] **Step 3: Analyze + Commit**

```bash
flutter analyze lib/features/layanan/screens/admin_complaints_screen.dart
git add lib/features/layanan/screens/admin_complaints_screen.dart
git commit -m "feat: add AdminComplaintsScreen for managing complaints"
```

---

## Task 11: End-to-End Smoke Test

- [ ] **Step 1: Jalankan app**

```bash
flutter run
```

- [ ] **Step 2: Test sebagai warga**
  - Login sebagai warga → cek tab "Layanan" muncul di bottom nav
  - Masuk tab Layanan → Surat → tap shortcut "Domisili"
  - Isi form permohonan → Submit → cek permohonan muncul di list dengan status "Menunggu"
  - Tab Pengaduan → Buat Pengaduan Baru → isi form → Submit → cek muncul di list

- [ ] **Step 3: Test sebagai admin — flow ideal end-to-end**
  - Login sebagai admin → dashboard → tap card "Permohonan Surat"
  - Cek permohonan dari warga muncul dengan data warga + jenis surat + keperluan
  - Tap **"Buat Surat"** pada card request → cek `CreateLetterScreen` terbuka dengan:
    - Nama warga sudah terpilih di dropdown
    - Jenis surat sudah terisi
    - Field keperluan sudah terisi dari request
  - Buat surat → selesai → cek `letter_request` status berubah jadi `ready`
  - Cek warga menerima notifikasi (lihat di bell icon beranda warga)
  - Dashboard → tap card "Pengaduan Warga" → update status pengaduan → cek notif warga

- [ ] **Step 4: Commit final**

```bash
git add .
git commit -m "feat: complete layanan & pengaduan feature - resident forms + admin management"
```

---

## Catatan Penting

1. **`url_launcher`** sudah ada di pubspec karena dipakai di marketplace. Tidak perlu tambah dependency baru.
2. **`intl`** sudah ada. Gunakan `DateFormat('d MMM y', 'id')` untuk format tanggal.
3. **Nomor permohonan** (SRT-001) adalah display-only, bukan kolom DB. Generate dari index list.
4. **Admin phone** untuk banner "Butuh bantuan?" — fetch dari `communities.admin_phone` via query kecil, atau sematkan di `currentProfileProvider` yang sudah ada.
5. **Photo upload pengaduan** — fase ini tidak wajib. `photo_url` kolom sudah ada di DB, bisa ditambahkan di iterasi berikutnya.
6. **Notifikasi ke admin** saat warga submit request/pengaduan baru — opsional, bisa ditambahkan di `createLetterRequest` dan `createComplaint` dengan target `user_id` = admin community.
