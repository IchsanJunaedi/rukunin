# Spec: Informasi Kontak — Layanan & Pengaduan

**Tanggal:** 2026-03-23
**Status:** Draft

---

## Ringkasan

Menambahkan fitur **Informasi Kontak** pada halaman Layanan & Pengaduan. Warga dapat melihat daftar kontak pengurus komunitas (nama, jabatan, foto, tombol chat WA). Admin dapat mengelola daftar kontak ini secara bebas tanpa harus terikat pada akun terdaftar.

---

## Database

### Tabel Baru: `community_contacts`

```sql
create table public.community_contacts (
  id           uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities(id) on delete cascade,
  nama         text not null,
  jabatan      text not null,
  phone        text not null,
  photo_url    text,
  urutan       int not null default 0,
  created_at   timestamptz not null default now()
);
```

**RLS Policies:**
- Admin komunitas: full CRUD (insert, update, delete, select) untuk `community_id` yang sesuai
- Resident komunitas: select only untuk `community_id` yang sesuai

**Storage:** Foto kontak disimpan di bucket `avatars` yang sudah ada.

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

  const CommunityContactModel({...});

  factory CommunityContactModel.fromMap(Map<String, dynamic> map) { ... }
  Map<String, dynamic> toMap() { ... }
}
```

---

## Admin Side

### Screen Baru: `AdminContactsScreen`

**File:** `lib/features/layanan/screens/admin_contacts_screen.dart`
**Route:** `/admin/layanan/kontak` — full-screen, di luar ShellRoute (tanpa bottom nav)

**Fitur:**
- List kartu kontak (foto/initials, nama, jabatan, nomor WA)
- FAB "+" untuk tambah kontak baru via bottom sheet
- Tap kartu → bottom sheet edit
- Tombol hapus di dalam edit sheet
- Urutan diatur dengan tombol ↑ / ↓ per kartu

**Entry Point:**
Dari screen admin yang mengelola Layanan Warga (misal `AdminRequestsScreen` atau dashboard Layanan), tambah tombol/card "Kelola Kontak" yang navigate ke `/admin/layanan/kontak`.

### Provider

Ditambahkan ke `lib/features/layanan/providers/layanan_provider.dart`:

```dart
final adminContactsProvider = FutureProvider.autoDispose<List<CommunityContactModel>>((ref) async {
  // query community_contacts by community_id admin
  // order by urutan asc
});
```

### Service

Class `ContactService` ditambahkan ke `layanan_provider.dart`:
- `addContact({nama, jabatan, phone, photoUrl?})`
- `updateContact({id, nama, jabatan, phone, photoUrl?})`
- `deleteContact(id)`
- `reorderContact(id, newUrutan)` — swap urutan dengan kontak di atas/bawah
- Upload foto ke bucket `avatars` jika ada

---

## Resident Side

### Perubahan: `LayananScreen`

**File:** `lib/features/layanan/screens/layanan_screen.dart`

TabBar dari 2 → 3 tab:

| Sebelum | Sesudah |
|---|---|
| Surat \| Pengaduan | Surat \| Pengaduan \| Informasi Kontak |

`_tabController = TabController(length: 3, vsync: this);`

### Tab Baru: `_KontakTab`

Widget `_KontakTab` ditambahkan di file yang sama.

**Layout:**
- Header teks kecil: "Hubungi pengurus komunitas"
- `ListView` kartu per kontak, diurutkan by `urutan asc`
- Setiap kartu:
  - `CircleAvatar` — tampilkan foto jika `photoUrl` ada, fallback initials dari nama
  - Nama (bold)
  - Jabatan (abu-abu, subtitle)
  - Tombol "Chat WA" → `launchUrl(Uri.parse('https://wa.me/$phone'))`
- Empty state jika list kosong: ikon + teks "Belum ada informasi kontak"

**`_HelpBanner` di tab Surat tetap ada** — tidak dihapus, berfungsi sebagai shortcut cepat. Tab Informasi Kontak adalah tampilan lengkap.

### Provider

Ditambahkan ke `lib/features/layanan/providers/layanan_provider.dart`:

```dart
final communityContactsProvider = FutureProvider.autoDispose<List<CommunityContactModel>>((ref) async {
  // query community_contacts by community_id warga
  // order by urutan asc
});
```

---

## Migration File

**File:** `supabase/migrations/20260323_community_contacts.sql`

Berisi:
1. `CREATE TABLE community_contacts`
2. RLS policies untuk admin (CRUD) dan resident (read-only)

---

## File yang Diubah / Dibuat

| File | Aksi |
|---|---|
| `supabase/migrations/20260323_community_contacts.sql` | Baru |
| `lib/features/layanan/models/community_contact_model.dart` | Baru |
| `lib/features/layanan/providers/layanan_provider.dart` | Edit — tambah 2 provider + ContactService |
| `lib/features/layanan/screens/admin_contacts_screen.dart` | Baru |
| `lib/features/layanan/screens/layanan_screen.dart` | Edit — TabBar 3 tab + `_KontakTab` |
| `lib/app/router.dart` | Edit — tambah route `/admin/layanan/kontak` |
| Admin Layanan screen (existing) | Edit — tambah entry point ke AdminContactsScreen |

---

## Out of Scope

- Drag-and-drop reorder (pakai up/down button saja)
- Notifikasi ke warga saat kontak diperbarui
- Multiple WhatsApp numbers per kontak
