# Design Spec: Rukunin Feature Batch
**Date:** 2026-03-17
**Branch:** ican
**Status:** Approved by user

---

## Overview

Batch implementasi 10 fitur baru untuk aplikasi Rukunin (Flutter + Supabase + Riverpod). Fitur dikelompokkan berdasarkan area fungsional.

---

## Grup A — Auth & Onboarding

### Task 1: Email Konfirmasi Supabase
**Manual only — tidak ada perubahan kode.**
- Supabase Dashboard → Authentication → Email → Enable "Confirm email"
- Aksi manual setelah deploy

### Task 10: Refactor Registrasi Warga (2 Halaman)

**Motivasi:** Form registrasi saat ini terlalu panjang di satu halaman. UX buruk dan validasi kode komunitas tidak terjadi sebelum field opsional ditampilkan.

**Desain:**
- `RegisterResidentScreen` dipecah menjadi dua screen:
  - `RegisterResidentStep1Screen`: community_code, full_name, phone, email, password
  - `RegisterResidentStep2Screen`: NIK (opsional), blok (opsional), unit_number (opsional), rt_number (opsional)
- Step 1 → tombol "Lanjut" → call `checkCommunityCode(code)` ke Supabase → jika valid, simpan ke `RegisterStep1Data` (plain Dart class: `communityId, fullName, phone, email, password`) → navigate ke Step 2 via `context.push('/register/resident/step2', extra: step1Data)`
- Step 2 → tombol "Daftar" atau "Lewati" → submit semua data via `registerResident()` yang diupdate
- `registerResident()` signature diupdate: ganti parameter `communityCode` → `communityId` (pakai langsung dari Step1Data, tidak lookup ulang ke DB)
- Route: `/register/resident` tetap mengarah ke Step 1. Step 2 di route `/register/resident/step2`, terima `state.extra as RegisterStep1Data`

**Files yang diubah:**
- `lib/features/auth/screens/register_resident_screen.dart` → split
- `lib/features/auth/screens/register_resident_step2_screen.dart` → baru
- `lib/features/auth/providers/register_provider.dart` → tambah `checkCommunityCode()`
- `lib/app/router.dart` → tambah route `/register/resident/step2`

---

## Grup B — Residents & Admin UX

### Task 11: Detail Pending Warga Bisa Diklik

**Motivasi:** Admin tidak bisa melihat detail warga pending (nama, HP, blok, dll) sebelum approve/reject.

**Desain:**
- Di `residents_screen.dart`, list item pending warga (`pendingResidentsProvider`) dibungkus `InkWell`/`GestureDetector`
- Tap → `showModalBottomSheet` berisi:
  - Avatar/inisial, nama lengkap, email, no HP, NIK, blok, nomor unit, RT, tanggal daftar
  - Tombol "Setujui" (hijau) dan "Tolak" (merah) di bagian bawah
- Tombol approve/reject memanggil method yang sudah ada di `ResidentNotifier`

**Files yang diubah:**
- `lib/features/residents/screens/residents_screen.dart`

---

## Grup C — Marketplace

### Task 7: Stock Barang

**Motivasi:** Penjual tidak bisa menginformasikan ketersediaan stok. Pembeli tidak tahu apakah barang masih tersedia.

**Desain:**

**DB Migration:**
```sql
ALTER TABLE marketplace_listings ADD COLUMN stock INTEGER NOT NULL DEFAULT 1;
```

**Model:**
- Tambah `final int stock` ke `MarketplaceListingModel`
- `fromMap`: `stock: (map['stock'] as num?)?.toInt() ?? 1`
- Computed getter: `bool get isAvailable => status == 'active' && stock > 0`

**UI AddListingScreen:**
- Tambah input field "Jumlah Stok" (NumberTextField, min 1)
- Default: 1

**UI ListingDetailScreen:**
- Tampilkan badge "Stok: N" di bawah harga
- Kalau stock = 0 atau status = 'sold': badge "Habis" (merah), sembunyikan tombol hubungi

**Fix existing bug — status enum inconsistency:**
- DB schema (`marketplace_listings`) mendefinisikan status default `'active'`, bukan `'available'`
- `marketplace_provider.dart` baris 41 dan 90 keliru menggunakan `'available'` — ini harus difix menjadi `'active'`
- `listing_detail_screen.dart` juga mungkin membandingkan dengan `'available'` — harus dicek dan difix

**Logic auto-deactivate:**
- Di `marketplace_provider.dart`: saat seller update status ke 'sold' atau saat stock ≤ 0 → set `status = 'sold'`
- Computed getter model: `bool get isAvailable => status == 'active' && stock > 0`

**Files yang diubah/dibuat:**
- `supabase/migrations/20260317_add_marketplace_stock.sql`
- `lib/features/marketplace/models/marketplace_listing_model.dart`
- `lib/features/marketplace/screens/add_listing_screen.dart`
- `lib/features/marketplace/screens/listing_detail_screen.dart`
- `lib/features/marketplace/providers/marketplace_provider.dart`

---

## Grup D — Laporan & Transparansi

### Task 6: Filter Laporan Keuangan (Admin + Warga)

**Motivasi:** Laporan saat ini hanya bisa difilter per bulan. Admin butuh fleksibilitas lebih; warga butuh filter di transparansi kas.

**Desain Admin (ReportsScreen):**
- Sudah ada `selectedMonth` dan `selectedYear` di `ReportNotifier`
- Tambah filter "Range" di UI: chip row berisi "Bulan ini", "3 Bulan", "6 Bulan", "Pilih Bulan"
- "Pilih Bulan" = behavior existing (month/year picker) — ini tetap jadi default
- "3 Bulan" / "6 Bulan" → tampilkan grafik bar multi-bulan (sudah ada grafik 6 bulan, tinggal sesuaikan parameter)
- **Tidak** menambah filter "Hari ini"/"Minggu ini" karena tabel `invoices` hanya punya kolom `month`/`year` (integer), bukan `date` — range harian tidak praktis tanpa schema change

**Desain Warga (ResidentKasScreen):**
- Tambah dropdown filter bulan/tahun di header
- `residentKasProvider` menjadi `residentKasProvider.family({month, year})`
- Default: bulan & tahun sekarang
- **Perhatian:** Sebelum convert ke `.family`, cek semua consumer `residentKasProvider` (minimal `resident_kas_screen.dart` dan `resident_home_screen.dart`) — semua harus diupdate untuk pass parameter

**Files yang diubah:**
- `lib/features/reports/providers/report_provider.dart`
- `lib/features/reports/screens/reports_screen.dart`
- `lib/features/resident_portal/providers/resident_kas_provider.dart`
- `lib/features/resident_portal/screens/resident_kas_screen.dart`

---

## Grup E — Profile & Kendaraan

### Task 8: Edit Kendaraan di Profil

**Motivasi:** Jumlah kendaraan mempengaruhi perhitungan iuran. Warga dan admin harus bisa update sendiri tanpa minta admin edit lewat form warga.

**Desain:**
- Di `ResidentProfileScreen` dan `AdminProfileScreen`:
  - Section "Kendaraan Terdaftar" tambah icon pensil di pojok kanan
  - Tap icon → `showModalBottomSheet` dengan 2 stepper: Motor dan Mobil (min 0, max 10)
  - Konfirmasi → `UPDATE profiles SET motorcycle_count = ?, car_count = ? WHERE id = userId`
  - `ref.invalidate(currentResidentProfileProvider)` / `ref.invalidate(currentAdminProfileProvider)`

**Files yang diubah:**
- `lib/features/resident_portal/screens/resident_profile_screen.dart` — tambah edit bottom sheet + mutation inline (update profiles langsung di screen, invalidate `currentResidentProfileProvider`)
- `lib/features/settings/screens/admin_profile_screen.dart` — sama, invalidate provider profil admin yang relevan

---

## Grup F — API Wilayah

### Task 9: Fix Lokasi Tidak Tersimpan ke DB

**Root cause:** Di `community_settings_screen.dart`, saat save, data wilayah yang dipilih (`_provinsi`, `_kabupaten`, `_kecamatan`, `_kelurahan`) tidak diikutkan dalam query UPDATE ke tabel `communities`.

**Penting — Kolom sudah ada:** Migration `20260311_add_location_fields.sql` sudah menambah 4 kolom ke tabel `communities`: `province TEXT`, `kabupaten TEXT`, `kecamatan TEXT`, `kelurahan TEXT`. **Tidak perlu migration baru.**

**Desain:**
- Di `_saveCommunity()`: tambahkan `'province': _provinsi?.name`, `'kabupaten': _kabupaten?.name`, `'kecamatan': _kecamatan?.name`, `'kelurahan': _kelurahan?.name` ke map UPDATE
- Di `_loadCommunity()`: setelah fetch data komunitas, re-populate display values dari kolom `province`, `kabupaten`, `kecamatan`, `kelurahan` yang sudah tersimpan — buat `WilayahModel` dummy hanya untuk teks tampilan (karena API wilayah hanya dibutuhkan untuk dropdown, bukan untuk load ulang)

**Files yang diubah:**
- `lib/features/community/screens/community_settings_screen.dart`

---

## Grup G — Notifikasi Log

### Task 12: Notifikasi Riwayat (In-App, Persistent)

**Motivasi:** Warga tidak punya riwayat aktivitas (bayar, pengumuman baru, status gabung). Admin tidak punya log request masuk.

**DB Schema:**
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,  -- penerima
  type TEXT NOT NULL CHECK (type IN ('payment', 'announcement', 'join_request', 'join_approved', 'join_rejected')),
  title TEXT NOT NULL,
  body TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB,  -- { invoice_id, announcement_id, resident_id, dll }
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS: user hanya bisa baca notif miliknya
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_read_own_notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);
-- INSERT dibatasi: hanya bisa insert notif di komunitas sendiri (mencegah user insert notif untuk user lain di komunitas berbeda)
CREATE POLICY "user_insert_community_notifications" ON notifications
  FOR INSERT WITH CHECK (
    community_id = (SELECT community_id FROM profiles WHERE id = auth.uid())
  );
-- Batch insert announcement → pakai Edge Function dengan service_role key
```

**Trigger Insert Notifikasi:**
- `markInvoiceAsPaid()` di invoice provider → insert notif type=`payment` ke warga terkait (1 row, user_id = warga yang bayar)
- `createAnnouncement()` → panggil Edge Function `send-announcement-notifications` (service_role) yang batch insert notif ke semua warga komunitas
- `approveResident()` / `rejectResident()` → insert notif type=`join_approved`/`join_rejected` ke warga bersangkutan (community-scoped)
- Saat warga baru daftar (pending) → insert notif type=`join_request` ke admin komunitas

**Provider:**
```dart
final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>(...);
final unreadCountProvider = FutureProvider.autoDispose<int>(...);
```

**UI:**
- Icon bell di AppBar `ResidentProfileScreen` dan `AdminProfileScreen` (top-right)
- Badge merah (unread count) via `unreadCountProvider`
- Tap bell → push `/resident/notifikasi` atau `/admin/notifikasi` (full-screen, no bottom nav)
- `NotificationScreen`: ListView notif, tap → mark as read + navigate ke halaman terkait jika ada `metadata`
- "Tandai semua dibaca" button di AppBar

**Files yang dibuat/diubah:**
- `supabase/migrations/20260317_add_notifications_table.sql`
- `lib/features/notifications/models/notification_model.dart`
- `lib/features/notifications/providers/notifications_provider.dart`
- `lib/features/notifications/screens/notifications_screen.dart`
- `lib/app/router.dart` — tambah 2 route
- `lib/features/resident_portal/screens/resident_profile_screen.dart` — tambah bell icon
- `lib/features/settings/screens/admin_profile_screen.dart` — tambah bell icon
- Provider-provider yang mengirim notifikasi (invoices, announcements, residents)

---

## Grup H — Pusat Bantuan

### Task 13: Pusat Bantuan (Static FAQ)

**Motivasi:** Warga dan admin perlu panduan penggunaan app tanpa harus hubungi developer.

**Desain:**
- `HelpCenterScreen` — list `ExpansionTile` dikelompokkan:
  - 📋 Tagihan & Pembayaran (4–5 FAQ)
  - 👤 Registrasi & Akun (3–4 FAQ)
  - 🛍️ Marketplace (2–3 FAQ)
  - ❓ Lainnya (2–3 FAQ)
- Konten hardcoded di Dart (tidak butuh backend/Resend key)
- Diakses dari menu di `ResidentProfileScreen` dan `AdminProfileScreen` (item sebelum tombol logout)
- Route: `/bantuan` (di luar ShellRoute)

**Catatan Resend API Key (`re_3dLiEYeD_NcCV3Ma3QELkyjXRjFpU8x9o`):**
- Digunakan hanya di Supabase Dashboard (Auth → SMTP Settings) — sudah dikonfigurasi
- **Tidak perlu dimasukkan ke kode Flutter** — forgot password flow sudah berjalan via `client.auth.resetPasswordForEmail()`

**Files yang dibuat/diubah:**
- `lib/features/help/screens/help_center_screen.dart`
- `lib/app/router.dart` — tambah route `/bantuan`
- `lib/features/resident_portal/screens/resident_profile_screen.dart`
- `lib/features/settings/screens/admin_profile_screen.dart`

---

## Grup I — FCM Push Notification

### Task 3: FCM Push Notification

**Status: Memerlukan setup eksternal dulu (tidak bisa dikerjakan tanpa ini)**

**Manual steps WAJIB sebelum coding:**
1. Buat Firebase project di console.firebase.google.com
2. Tambah Android app (package name dari `android/app/build.gradle`)
3. Download `google-services.json` → taruh di `android/app/`
4. Tambah iOS app → download `GoogleService-Info.plist` → taruh di `ios/Runner/`
5. Tambah ke `pubspec.yaml`: `firebase_core`, `firebase_messaging`
6. Jalankan `dart run build_runner build`

**Kode setelah setup:**
- `main.dart`: init `Firebase.initializeApp()`, init `FirebaseMessaging`
- Simpan FCM token ke `profiles.fcm_token` (kolom baru) saat login
- Handler: foreground → `FirebaseMessaging.onMessage`, background → `onBackgroundMessage`
- Edge Function `send-reminders` diupdate untuk fetch `fcm_token` dari profiles dan kirim via FCM HTTP v1 API

**Rekomendasi:** Kerjakan setelah semua task lain selesai. Paling kompleks karena butuh native setup Android + iOS.

---

## DB Migrations Summary

| File | Tabel | Perubahan |
|---|---|---|
| `20260317_add_marketplace_stock.sql` | `marketplace_listings` | ADD COLUMN `stock INTEGER DEFAULT 1` |
| `20260317_add_notifications_table.sql` | `notifications` | CREATE TABLE baru + RLS |
| *(tidak ada)* | `communities` | Kolom wilayah sudah ada sejak `20260311_add_location_fields.sql` |
| *(jika FCM dikerjakan)* | `profiles` | ADD COLUMN `fcm_token TEXT` |

---

## Manual Steps untuk User (Setelah Deploy)

1. **Task 1**: Supabase Dashboard → Authentication → Email → Enable "Confirm email"
2. **Task 3 (FCM)**: Setup Firebase project + download config files (lihat detail di atas)
3. **Jalankan semua SQL migrations** di Supabase SQL Editor (3 file)

---

## Urutan Implementasi (Rekomendasi)

1. DB Migrations (semua sekaligus)
2. Task 9 — Fix wilayah (quick win, unblock data komunitas)
3. Task 11 — Pending detail (quick win)
4. Task 8 — Edit kendaraan (quick win)
5. Task 7 — Marketplace stock (medium)
6. Task 10 — Refactor registrasi (medium)
7. Task 6 — Filter laporan (medium)
8. Task 12 — Notifikasi log (besar)
9. Task 13 — Pusat bantuan (small, tapi terakhir karena dekoratif)
10. Task 3 — FCM (setelah semua selesai, butuh Firebase setup)
