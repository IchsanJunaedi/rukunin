# Informasi Kontak Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tambah fitur Informasi Kontak — admin kelola daftar kontak pengurus, warga lihat di tab ketiga Layanan & Pengaduan lengkap dengan tombol chat WA.

**Architecture:** Tabel `community_contacts` baru di Supabase (tidak terikat akun). Providers baru di `layanan_provider.dart`, service methods extend `LayananService`. Admin punya screen baru `/admin/layanan/kontak`. Resident lihat di tab ketiga `LayananScreen`.

**Tech Stack:** Flutter, Supabase (PostgreSQL + Storage), flutter_riverpod ^3, GoRouter, image_picker, cached_network_image, google_fonts.

---

## File Map

| File | Aksi |
|---|---|
| `supabase/migrations/20260323_community_contacts.sql` | Baru |
| `supabase/migrations/20260323_create_contact_photos_bucket.sql` | Baru |
| `lib/features/layanan/models/community_contact_model.dart` | Baru |
| `test/features/layanan/models_test.dart` | Edit — tambah group CommunityContactModel |
| `lib/features/layanan/providers/layanan_provider.dart` | Edit — 2 provider + 4 method di LayananService |
| `lib/features/layanan/screens/admin_contacts_screen.dart` | Baru |
| `lib/features/layanan/screens/admin_requests_screen.dart` | Edit — tambah entry point card |
| `lib/features/layanan/screens/layanan_screen.dart` | Edit — TabBar 3 tab + `_KontakTab` + `_KontakCard` |
| `lib/app/router.dart` | Edit — route `/admin/layanan/kontak` |

---

## Task 1: DB Migration — Tabel `community_contacts`

**Files:**
- Create: `supabase/migrations/20260323_community_contacts.sql`

- [ ] **Step 1: Buat file migration**

```sql
-- supabase/migrations/20260323_community_contacts.sql

create table public.community_contacts (
  id           uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete cascade,
  nama         text not null,
  jabatan      text not null,
  phone        text not null,
  photo_url    text,
  urutan       int not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.community_contacts enable row level security;

-- Admin komunitas: full CRUD
create policy "Admin can manage community_contacts"
  on public.community_contacts for all
  using (is_admin_of(community_id))
  with check (is_admin_of(community_id));

-- Warga komunitas: read only
create policy "Resident can view community_contacts"
  on public.community_contacts for select
  using (community_id = my_community_id());
```

> Jalankan manual di Supabase SQL Editor — tidak dijalankan otomatis.

- [ ] **Step 2: Commit**

```bash
rtk git add supabase/migrations/20260323_community_contacts.sql
rtk git commit -m "feat: add community_contacts table migration"
```

---

## Task 2: DB Migration — Bucket `contact_photos`

**Files:**
- Create: `supabase/migrations/20260323_create_contact_photos_bucket.sql`

- [ ] **Step 1: Buat file migration**

```sql
-- supabase/migrations/20260323_create_contact_photos_bucket.sql

-- Buat bucket contact_photos (public — URL bisa diakses langsung)
insert into storage.buckets (id, name, public)
values ('contact_photos', 'contact_photos', true)
on conflict (id) do nothing;

-- Policy: Semua orang bisa lihat (public bucket)
create policy "Anyone can view contact photos"
  on storage.objects for select
  using ( bucket_id = 'contact_photos' );

-- Policy: Admin bisa upload foto kontak
-- NOTE: Policy ini mengizinkan semua authenticated user — scoping per community_id
-- di level storage tidak praktis tanpa fungsi helper khusus. Data integrity
-- sudah dijaga oleh RLS di tabel community_contacts. Ini adalah known trade-off.
create policy "Admin can upload contact photos"
  on storage.objects for insert
  with check (
    bucket_id = 'contact_photos'
    and auth.role() = 'authenticated'
  );

-- Policy: Admin bisa update foto kontak
create policy "Admin can update contact photos"
  on storage.objects for update
  using (
    bucket_id = 'contact_photos'
    and auth.role() = 'authenticated'
  );

-- Policy: Admin bisa hapus foto kontak
create policy "Admin can delete contact photos"
  on storage.objects for delete
  using (
    bucket_id = 'contact_photos'
    and auth.role() = 'authenticated'
  );
```

> Jalankan manual di Supabase SQL Editor.

- [ ] **Step 2: Commit**

```bash
rtk git add supabase/migrations/20260323_create_contact_photos_bucket.sql
rtk git commit -m "feat: add contact_photos storage bucket migration"
```

---

## Task 3: Model `CommunityContactModel` + Unit Test

**Files:**
- Create: `lib/features/layanan/models/community_contact_model.dart`
- Modify: `test/features/layanan/models_test.dart`

- [ ] **Step 1: Tulis failing test terlebih dahulu**

Tambahkan group baru di akhir `test/features/layanan/models_test.dart` (sebelum closing `}`):

```dart
  group('CommunityContactModel', () {
    final map = {
      'id': 'con-1',
      'community_id': 'com-1',
      'nama': 'Pak Budi',
      'jabatan': 'Ketua RW',
      'phone': '628123456789',
      'photo_url': null,
      'urutan': 0,
      'created_at': '2026-03-23T08:00:00.000Z',
      'updated_at': '2026-03-23T08:00:00.000Z',
    };

    test('fromMap parses correctly', () {
      final model = CommunityContactModel.fromMap(map);
      expect(model.id, 'con-1');
      expect(model.communityId, 'com-1');
      expect(model.nama, 'Pak Budi');
      expect(model.jabatan, 'Ketua RW');
      expect(model.phone, '628123456789');
      expect(model.photoUrl, isNull);
      expect(model.urutan, 0);
    });

    test('fromMap handles photo_url', () {
      final model = CommunityContactModel.fromMap({
        ...map,
        'photo_url': 'https://example.com/photo.jpg',
      });
      expect(model.photoUrl, 'https://example.com/photo.jpg');
    });

    test('initials returns first two letters of name', () {
      expect(CommunityContactModel.fromMap(map).initials, 'PB');
      expect(
        CommunityContactModel.fromMap({...map, 'nama': 'Budi'}).initials,
        'BU',
      );
    });
  });
```

Tambahkan import di atas file:
```dart
import 'package:rukunin/features/layanan/models/community_contact_model.dart';
```

- [ ] **Step 2: Jalankan test — pastikan GAGAL**

```bash
flutter test test/features/layanan/models_test.dart
```

Expected: error "community_contact_model.dart not found" atau kompilasi gagal.

- [ ] **Step 3: Buat model**

```dart
// lib/features/layanan/models/community_contact_model.dart

class CommunityContactModel {
  final String id;
  final String communityId;
  final String nama;
  final String jabatan;
  final String phone;
  final String? photoUrl;
  final int urutan;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityContactModel({
    required this.id,
    required this.communityId,
    required this.nama,
    required this.jabatan,
    required this.phone,
    this.photoUrl,
    required this.urutan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityContactModel.fromMap(Map<String, dynamic> map) {
    return CommunityContactModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      nama: map['nama'] as String,
      jabatan: map['jabatan'] as String,
      phone: map['phone'] as String,
      photoUrl: map['photo_url'] as String?,
      urutan: map['urutan'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'community_id': communityId,
        'nama': nama,
        'jabatan': jabatan,
        'phone': phone,
        if (photoUrl != null) 'photo_url': photoUrl,
        'urutan': urutan,
      };

  /// Dua huruf kapital dari kata pertama + kedua nama (fallback: dua huruf pertama)
  String get initials {
    final words = nama.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return nama.substring(0, nama.length >= 2 ? 2 : 1).toUpperCase();
  }
}
```

- [ ] **Step 4: Jalankan test — pastikan LULUS**

```bash
flutter test test/features/layanan/models_test.dart
```

Expected: semua test PASS.

- [ ] **Step 5: Commit**

```bash
rtk git add lib/features/layanan/models/community_contact_model.dart test/features/layanan/models_test.dart
rtk git commit -m "feat: add CommunityContactModel with unit tests"
```

---

## Task 4: Providers + LayananService Methods

**Files:**
- Modify: `lib/features/layanan/providers/layanan_provider.dart`

- [ ] **Step 1: Tambah import di atas file**

Di `layanan_provider.dart`, tambahkan import:
```dart
import '../models/community_contact_model.dart';
```

- [ ] **Step 2: Tambah `adminContactsProvider` dan `communityContactsProvider`**

Tambahkan di bagian bawah file, sebelum class `LayananService`:

```dart
// ── Admin: daftar kontak komunitas ────────────────────────────
final adminContactsProvider =
    FutureProvider.autoDispose<List<CommunityContactModel>>((ref) async {
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
      .from('community_contacts')
      .select()
      .eq('community_id', communityId)
      .order('urutan', ascending: true);

  return (res as List).map((e) => CommunityContactModel.fromMap(e)).toList();
});

// ── Resident: daftar kontak komunitas ─────────────────────────
final communityContactsProvider =
    FutureProvider.autoDispose<List<CommunityContactModel>>((ref) async {
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
      .from('community_contacts')
      .select()
      .eq('community_id', communityId)
      .order('urutan', ascending: true);

  return (res as List).map((e) => CommunityContactModel.fromMap(e)).toList();
});
```

- [ ] **Step 3: Tambah 4 method ke `LayananService`**

Di dalam class `LayananService` (yang sudah ada), tambahkan method-method berikut di bagian bawah class:

```dart
  // ── Kontak ────────────────────────────────────────────────────

  Future<void> addContact({
    required String communityId,
    required String nama,
    required String jabatan,
    required String phone,
    String? photoUrl,
  }) async {
    final client = ref.read(supabaseClientProvider);

    // Hitung urutan berikutnya
    final existing = await client
        .from('community_contacts')
        .select('urutan')
        .eq('community_id', communityId)
        .order('urutan', ascending: false)
        .limit(1);
    final nextUrutan = existing.isEmpty
        ? 0
        : ((existing.first['urutan'] as int?) ?? 0) + 1;

    await client.from('community_contacts').insert({
      'community_id': communityId,
      'nama': nama,
      'jabatan': jabatan,
      'phone': phone,
      if (photoUrl != null) 'photo_url': photoUrl,
      'urutan': nextUrutan,
      'updated_at': DateTime.now().toIso8601String(),
    });
    ref.invalidate(adminContactsProvider);
  }

  Future<void> updateContact({
    required String id,
    required String nama,
    required String jabatan,
    required String phone,
    String? photoUrl,
  }) async {
    final client = ref.read(supabaseClientProvider);
    // PENTING: photo_url hanya diupdate jika ada nilai baru (tidak null).
    // Ini mencegah foto lama terhapus saat admin tidak mengganti foto.
    await client.from('community_contacts').update({
      'nama': nama,
      'jabatan': jabatan,
      'phone': phone,
      if (photoUrl != null) 'photo_url': photoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    ref.invalidate(adminContactsProvider);
  }

  Future<void> deleteContact(String id) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('community_contacts').delete().eq('id', id);
    ref.invalidate(adminContactsProvider);
  }

  /// Swap urutan dua kontak — dua UPDATE sequential.
  Future<void> swapUrutan(
    String idA,
    int urutanA,
    String idB,
    int urutanB,
  ) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('community_contacts')
        .update({'urutan': urutanB, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', idA);
    await client
        .from('community_contacts')
        .update({'urutan': urutanA, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', idB);
    ref.invalidate(adminContactsProvider);
  }

  /// Upload foto kontak ke bucket contact_photos, return public URL.
  Future<String> uploadContactPhoto({
    required String communityId,
    required String contactId,
    required List<int> fileBytes,
    required String fileExt,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final path = '$communityId/$contactId.$fileExt';
    await client.storage.from('contact_photos').uploadBinary(
          path,
          Uint8List.fromList(fileBytes),
          fileOptions: FileOptions(upsert: true),
        );
    return client.storage.from('contact_photos').getPublicUrl(path);
  }
```

- [ ] **Step 4: Tambah import `dart:typed_data` dan Supabase `FileOptions`**

Kedua import ini **BELUM ADA** di `layanan_provider.dart` saat ini — tambahkan keduanya:
```dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
```

- [ ] **Step 5: Jalankan analyze**

```bash
flutter analyze lib/features/layanan/providers/layanan_provider.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
rtk git add lib/features/layanan/providers/layanan_provider.dart
rtk git commit -m "feat: add contact providers and LayananService contact methods"
```

---

## Task 5: `AdminContactsScreen`

**Files:**
- Create: `lib/features/layanan/screens/admin_contacts_screen.dart`

- [ ] **Step 1: Buat screen**

```dart
// lib/features/layanan/screens/admin_contacts_screen.dart

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/community_contact_model.dart';
import '../providers/layanan_provider.dart';

class AdminContactsScreen extends ConsumerWidget {
  const AdminContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(adminContactsProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Kelola Kontak'),
      ),
      body: contactsAsync.when(
        data: (contacts) => contacts.isEmpty
            ? _buildEmpty(context, ref)
            : _buildList(context, ref, contacts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: GoogleFonts.plusJakartaSans(color: AppColors.error)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _showForm(context, ref, null, []),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 56, color: AppColors.grey300),
          const SizedBox(height: 12),
          Text(
            'Belum ada kontak',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + untuk tambah kontak pengurus',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<CommunityContactModel> contacts) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _ContactAdminCard(
          contact: contact,
          canMoveUp: index > 0,
          canMoveDown: index < contacts.length - 1,
          onMoveUp: () {
            final above = contacts[index - 1];
            ref.read(layananServiceProvider).swapUrutan(
                  contact.id, contact.urutan,
                  above.id, above.urutan,
                );
          },
          onMoveDown: () {
            final below = contacts[index + 1];
            ref.read(layananServiceProvider).swapUrutan(
                  contact.id, contact.urutan,
                  below.id, below.urutan,
                );
          },
          onEdit: () => _showForm(context, ref, contact, contacts),
        );
      },
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref,
    CommunityContactModel? existing,
    List<CommunityContactModel> allContacts,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ContactFormSheet(
        existing: existing,
        onSave: (nama, jabatan, phone, photoBytes, photoExt) async {
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

          final service = ref.read(layananServiceProvider);

          if (existing == null) {
            // Tambah baru — upload foto dulu jika ada
            String? photoUrl;
            if (photoBytes != null && photoExt != null) {
              final tempId = DateTime.now().millisecondsSinceEpoch.toString();
              photoUrl = await service.uploadContactPhoto(
                communityId: communityId,
                contactId: tempId,
                fileBytes: photoBytes,
                fileExt: photoExt,
              );
            }
            await service.addContact(
              communityId: communityId,
              nama: nama,
              jabatan: jabatan,
              phone: phone,
              photoUrl: photoUrl,
            );
          } else {
            // Edit — upload foto baru jika diganti
            String? photoUrl = existing.photoUrl;
            if (photoBytes != null && photoExt != null) {
              photoUrl = await service.uploadContactPhoto(
                communityId: communityId,
                contactId: existing.id,
                fileBytes: photoBytes,
                fileExt: photoExt,
              );
            }
            await service.updateContact(
              id: existing.id,
              nama: nama,
              jabatan: jabatan,
              phone: phone,
              photoUrl: photoUrl,
            );
          }
        },
        onDelete: existing == null
            ? null
            : () async {
                final confirm = await showDialog<bool>(
                  context: ctx,
                  builder: (d) => AlertDialog(
                    title: const Text('Hapus Kontak'),
                    content: Text('Hapus kontak "${existing.nama}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('Hapus',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(layananServiceProvider)
                      .deleteContact(existing.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
      ),
    );
  }
}

// ── Card admin ────────────────────────────────────────────────
class _ContactAdminCard extends StatelessWidget {
  final CommunityContactModel contact;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;

  const _ContactAdminCard({
    required this.contact,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(contact: contact, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                Text(
                  contact.jabatan,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
                Text(
                  contact.phone,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: canMoveUp ? onMoveUp : null,
                color: canMoveUp ? AppColors.grey600 : AppColors.grey300,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                onPressed: canMoveDown ? onMoveDown : null,
                color: canMoveDown ? AppColors.grey600 : AppColors.grey300,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            color: AppColors.grey600,
          ),
        ],
      ),
    );
  }
}

// ── Avatar helper ─────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final CommunityContactModel contact;
  final double radius;

  const _Avatar({required this.contact, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (contact.photoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.grey200,
        backgroundImage: CachedNetworkImageProvider(contact.photoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        contact.initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Form bottom sheet ─────────────────────────────────────────
class _ContactFormSheet extends ConsumerStatefulWidget {
  final CommunityContactModel? existing;
  final Future<void> Function(
    String nama,
    String jabatan,
    String phone,
    List<int>? photoBytes,
    String? photoExt,
  ) onSave;
  final Future<void> Function()? onDelete;

  const _ContactFormSheet({
    required this.existing,
    required this.onSave,
    this.onDelete,
  });

  @override
  ConsumerState<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends ConsumerState<_ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _jabatanCtrl;
  late final TextEditingController _phoneCtrl;
  List<int>? _photoBytes;
  String? _photoExt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.existing?.nama ?? '');
    _jabatanCtrl = TextEditingController(text: widget.existing?.jabatan ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _jabatanCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final ext = image.name.split('.').last.toLowerCase();
    setState(() {
      _photoBytes = bytes;
      _photoExt = ext;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _namaCtrl.text.trim(),
        _jabatanCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _photoBytes,
        _photoExt,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Kontak' : 'Tambah Kontak',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 20),

            // Foto
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.grey200,
                      backgroundImage: _photoBytes != null
                          ? MemoryImage(Uint8List.fromList(_photoBytes!))
                          : (widget.existing?.photoUrl != null
                              ? CachedNetworkImageProvider(
                                  widget.existing!.photoUrl!) as ImageProvider
                              : null),
                      child: (_photoBytes == null &&
                              widget.existing?.photoUrl == null)
                          ? Icon(Icons.camera_alt_outlined,
                              color: AppColors.grey500, size: 28)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 12, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nama
            TextFormField(
              controller: _namaCtrl,
              decoration: InputDecoration(
                labelText: 'Nama',
                hintText: 'Contoh: Pak Budi Santoso',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            // Jabatan
            TextFormField(
              controller: _jabatanCtrl,
              decoration: InputDecoration(
                labelText: 'Jabatan',
                hintText: 'Contoh: Ketua RW, Sekretaris, Bendahara',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Jabatan wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            // Nomor WA
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor WhatsApp',
                hintText: '628123456789 (format internasional tanpa +)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nomor WA wajib diisi';
                if (!RegExp(r'^\d{10,15}$').hasMatch(v.trim())) {
                  return 'Format: 628xxx (angka saja, 10-15 digit)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  elevation: 0,
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Simpan'),
              ),
            ),

            // Tombol hapus (hanya saat edit)
            if (isEdit && widget.onDelete != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: widget.onDelete,
                  child: const Text('Hapus Kontak'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Jalankan analyze**

```bash
flutter analyze lib/features/layanan/screens/admin_contacts_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
rtk git add lib/features/layanan/screens/admin_contacts_screen.dart
rtk git commit -m "feat: add AdminContactsScreen with CRUD and reorder"
```

---

## Task 6: Entry Point di `AdminRequestsScreen`

**Files:**
- Modify: `lib/features/layanan/screens/admin_requests_screen.dart`

- [ ] **Step 1: Baca file saat ini**

Baca `lib/features/layanan/screens/admin_requests_screen.dart` untuk konfirmasi struktur body.

- [ ] **Step 2: Tambah import**

Tambahkan di bagian import file:
```dart
import 'package:go_router/go_router.dart';
```
(Cek apakah sudah ada — jangan duplikat.)

- [ ] **Step 3: Tambah banner "Kelola Informasi Kontak"**

Di method `build`, di dalam `Column` yang menjadi body Scaffold, **sebelum** filter chips, sisipkan widget berikut:

```dart
// Banner Kelola Kontak — di atas filter chips
GestureDetector(
  onTap: () => context.push('/admin/layanan/kontak'),
  child: Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.3),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.contacts_outlined,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Informasi Kontak',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
              Text(
                'Atur kontak pengurus yang tampil ke warga',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.grey400),
      ],
    ),
  ),
),
```

- [ ] **Step 4: Jalankan analyze**

```bash
flutter analyze lib/features/layanan/screens/admin_requests_screen.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
rtk git add lib/features/layanan/screens/admin_requests_screen.dart
rtk git commit -m "feat: add Kelola Kontak entry point to AdminRequestsScreen"
```

---

## Task 7: Tab Ketiga di `LayananScreen` (Resident)

**Files:**
- Modify: `lib/features/layanan/screens/layanan_screen.dart`

- [ ] **Step 1: Ubah TabController length dari 2 ke 3**

Di `_LayananScreenState.initState`:
```dart
// sebelum:
_tabController = TabController(length: 2, vsync: this);

// sesudah:
_tabController = TabController(length: 3, vsync: this);
```

- [ ] **Step 2: Tambah tab "Kontak" di TabBar**

Di widget `TabBar`, tambahkan tab ketiga:
```dart
tabs: const [
  Tab(text: 'Surat'),
  Tab(text: 'Pengaduan'),
  Tab(text: 'Kontak'),      // ← tambah ini
],
```

- [ ] **Step 3: Tambah `_KontakTab()` di TabBarView**

```dart
body: TabBarView(
  controller: _tabController,
  children: const [
    _SuratTab(),
    _PengaduanTab(),
    _KontakTab(),         // ← tambah ini
  ],
),
```

- [ ] **Step 4: (Dihandle di Step 6)** Import model akan ditambahkan di Step 6. Lanjutkan ke Step 5.

- [ ] **Step 5: Tambah widget `_KontakTab` dan `_KontakCard`**

Tambahkan di bagian bawah file, setelah `_HelpBanner`:

```dart
// ── Tab Kontak ────────────────────────────────────────────────
class _KontakTab extends ConsumerWidget {
  const _KontakTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(communityContactsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(communityContactsProvider),
      child: contactsAsync.when(
        data: (contacts) => contacts.isEmpty
            ? _buildEmpty()
            : _buildList(contacts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: GoogleFonts.plusJakartaSans(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: AppColors.grey300),
              const SizedBox(height: 12),
              Text(
                'Belum ada informasi kontak',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<CommunityContactModel> contacts) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hubungi pengurus komunitas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
          ),
        ),
        const SizedBox(height: 12),
        ...contacts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _KontakCard(contact: c),
            )),
      ],
    );
  }
}

// ── Kartu kontak untuk resident ───────────────────────────────
class _KontakCard extends StatelessWidget {
  final CommunityContactModel contact;

  const _KontakCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.jabatan,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), // WhatsApp green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 0,
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => _launchWhatsApp(contact.phone),
            icon: const Icon(Icons.chat_outlined, size: 14),
            label: const Text('Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (contact.photoUrl != null) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.grey200,
        backgroundImage: CachedNetworkImageProvider(contact.photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        contact.initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Tambah import `CachedNetworkImageProvider`**

Di atas `layanan_screen.dart`, tambahkan:
```dart
import 'package:cached_network_image/cached_network_image.dart';
import '../models/community_contact_model.dart';
```

- [ ] **Step 7: Jalankan analyze**

```bash
flutter analyze lib/features/layanan/screens/layanan_screen.dart
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
rtk git add lib/features/layanan/screens/layanan_screen.dart
rtk git commit -m "feat: add Informasi Kontak tab to LayananScreen"
```

---

## Task 8: Router + Final Verify

**Files:**
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Tambah import `AdminContactsScreen`**

Di bagian import `router.dart`:
```dart
import '../features/layanan/screens/admin_contacts_screen.dart';
```

- [ ] **Step 2: Tambah route `/admin/layanan/kontak`**

Di antara route-route admin yang sudah ada (setelah route `/admin/pengaduan`):

```dart
GoRoute(
  path: '/admin/layanan/kontak',
  builder: (context, state) => const AdminContactsScreen(),
),
```

- [ ] **Step 3: Jalankan analyze seluruh project**

```bash
flutter analyze
```

Expected: no errors (hanya warnings yang sudah ada sebelumnya — OK).

- [ ] **Step 4: Jalankan seluruh test**

```bash
flutter test
```

Expected: semua test PASS.

- [ ] **Step 5: Commit final**

```bash
rtk git add lib/app/router.dart
rtk git commit -m "feat: register /admin/layanan/kontak route"
```

---

## Catatan Deployment

Sebelum testing di device, jalankan kedua migration di **Supabase SQL Editor**:
1. `supabase/migrations/20260323_community_contacts.sql`
2. `supabase/migrations/20260323_create_contact_photos_bucket.sql`

Urutan penting: tabel dulu, baru bucket.
