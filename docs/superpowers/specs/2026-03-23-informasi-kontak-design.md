# Spec: Informasi Kontak — Layanan & Pengaduan

**Tanggal:** 2026-03-23
**Status:** Final

---

## Ringkasan

Menambahkan fitur **Informasi Kontak** pada halaman Layanan & Pengaduan. Warga dapat melihat daftar kontak pengurus komunitas (nama, jabatan, foto, tombol chat WA). Admin dapat mengelola daftar kontak ini secara bebas tanpa harus terikat pada akun terdaftar di app.

---

## Database

### Tabel Baru: `community_contacts`

```sql
alter table public.community_contacts enable row level security;

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

-- Admin: full CRUD
create policy "Admin can manage community_contacts"
  on public.community_contacts for all
  using (is_admin_of(community_id))
  with check (is_admin_of(community_id));

-- Resident: read only
create policy "Resident can view community_contacts"
  on public.community_contacts for select
  using (community_id = my_community_id());
```

`is_admin_of()` dan `my_community_id()` adalah helper functions yang sudah ada di `20260311_rls_policies.sql`.

**Catatan `urutan`:** Dense integer (0, 1, 2, ...). Tidak ada UNIQUE constraint — sort by `urutan asc` saja. Swap dilakukan dengan dua UPDATE sequential (bukan transaksi), karena tidak ada constraint yang bisa dilanggar.

### Storage: Bucket Baru `contact_photos`

Bucket baru `contact_photos` (public) dibuat via migration terpisah `20260323_create_contact_photos_bucket.sql`. Admin upload ke path `{communityId}/{contactId}`. Policy: admin komunitas bisa insert/update/delete, semua user bisa view (public bucket).

---

## Data Model (Dart)

**File:** `lib/features/layanan/models/community_contact_model.dart`

```dart
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

  factory CommunityContactModel.fromMap(Map<String, dynamic> map) { ... }
  Map<String, dynamic> toMap() { ... }
}
```

---

## Admin Side

### Screen Baru: `AdminContactsScreen`

**File:** `lib/features/layanan/screens/admin_contacts_screen.dart`
**Route:** `/admin/layanan/kontak` — full-screen, di luar ShellRoute (tanpa bottom nav), sesuai pola codebase.

**Fitur:**
- `AppBar` dengan judul "Kelola Kontak"
- List kartu kontak (foto/initials CircleAvatar, nama bold, jabatan abu-abu, nomor WA)
- FAB "+" → bottom sheet tambah kontak baru
- Tap kartu → bottom sheet edit kontak
- Tombol hapus di dalam edit sheet (dengan konfirmasi dialog)
- Tombol ↑ / ↓ di setiap kartu untuk atur urutan

**Bottom sheet form** (tambah & edit): field nama (required), jabatan (required), nomor WA (required, format `628xxx`), tombol upload foto (opsional).

**Validasi nomor WA:** Field phone harus diisi format internasional tanpa `+`, contoh `628123456789`. Tampilkan hint text di form field. Tidak perlu auto-convert — cukup hint agar admin tahu formatnya.

### Entry Point dari Admin

Di `AdminRequestsScreen` (`lib/features/layanan/screens/admin_requests_screen.dart`), tambah card/banner **"Kelola Informasi Kontak"** di bagian atas konten (sebelum list permohonan), dengan icon dan teks, yang onTap navigate ke `/admin/layanan/kontak`.

### Provider & Service

Ditambahkan ke `lib/features/layanan/providers/layanan_provider.dart`:

```dart
// Provider
final adminContactsProvider = FutureProvider.autoDispose<List<CommunityContactModel>>((ref) async {
  // 1. fetch community_id dari profiles by auth.uid()
  // 2. query community_contacts where community_id = ... order by urutan asc
});

// Service — extend LayananService yang sudah ada (BUKAN class terpisah)
// Tambah method berikut ke class LayananService:
//   addContact({required String communityId, required String nama, required String jabatan, required String phone, String? photoUrl})
//   updateContact({required String id, required String nama, required String jabatan, required String phone, String? photoUrl})
//   deleteContact(String id)
//   swapUrutan(String idA, int urutanA, String idB, int urutanB)
//     → UPDATE id_A set urutan = urutanB, UPDATE id_B set urutan = urutanA (dua sequential UPDATE)
```

**Catatan duplikasi:** `adminContactsProvider` melakukan dua-step fetch (`community_id` dulu, baru query) — ini pola yang sama dengan `adminLetterRequestsProvider` dan `adminComplaintsProvider`. Ini disengaja dan konsisten, bukan refactoring peluang.

---

## Resident Side

### Perubahan: `LayananScreen`

**File:** `lib/features/layanan/screens/layanan_screen.dart`

TabBar dari 2 → 3 tab:

```
Surat  |  Pengaduan  |  Informasi Kontak
```

Perubahan:
- `_tabController = TabController(length: 3, vsync: this);`
- Tambah `Tab(text: 'Kontak')` di TabBar
- Tambah `_KontakTab()` di `TabBarView`

### Widget Baru: `_KontakTab`

Ditambahkan di file yang sama (`layanan_screen.dart`).

**Layout:**
```
ListView(
  padding: EdgeInsets.all(20),
  children: [
    Text('Hubungi pengurus komunitas'),  // header kecil
    SizedBox(height: 12),
    ...kontak.map((c) => _KontakCard(contact: c)),
  ]
)
```

**`_KontakCard`** per kontak:
- `CircleAvatar` — tampilkan foto dari `photoUrl` jika ada (via `Image.network`), fallback initials 2 huruf dari nama
- Nama (bold, `AppTextStyles` / `GoogleFonts.plusJakartaSans`)
- Jabatan (abu-abu, subtitle)
- Tombol "Chat WA" → `launchUrl(Uri.parse('https://wa.me/${contact.phone}'))` (reuse `_launchWhatsApp` helper yang sudah ada)

**Empty state** jika list kosong: `Icon(Icons.people_outline)` + teks "Belum ada informasi kontak"

**`_HelpBanner` di tab Surat tetap ada** — tidak diubah/dihapus.

### Provider

Ditambahkan ke `lib/features/layanan/providers/layanan_provider.dart`:

```dart
final communityContactsProvider = FutureProvider.autoDispose<List<CommunityContactModel>>((ref) async {
  // 1. fetch community_id dari profiles by auth.uid()
  // 2. query community_contacts where community_id = ... order by urutan asc
});
```

---

## File yang Diubah / Dibuat

| File | Aksi |
|---|---|
| `supabase/migrations/20260323_community_contacts.sql` | Baru — DDL tabel + RLS |
| `supabase/migrations/20260323_create_contact_photos_bucket.sql` | Baru — bucket contact_photos |
| `lib/features/layanan/models/community_contact_model.dart` | Baru |
| `lib/features/layanan/providers/layanan_provider.dart` | Edit — tambah 2 provider + 4 method di LayananService |
| `lib/features/layanan/screens/admin_contacts_screen.dart` | Baru |
| `lib/features/layanan/screens/admin_requests_screen.dart` | Edit — tambah entry point card ke AdminContactsScreen |
| `lib/features/layanan/screens/layanan_screen.dart` | Edit — TabBar 3 tab + `_KontakTab` + `_KontakCard` |
| `lib/app/router.dart` | Edit — tambah route `/admin/layanan/kontak` |

---

## Out of Scope

- Drag-and-drop reorder
- Notifikasi warga saat kontak diperbarui
- Multiple nomor WA per kontak
- Auto-konversi format nomor WA (admin input sendiri format `628xxx`)
