# Rukunin Feature Batch Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementasi 10 fitur baru Rukunin — notifikasi in-app, stock marketplace, refactor registrasi warga 2-langkah, filter laporan, edit kendaraan, fix wilayah, pending detail, pusat bantuan, dan scaffolding FCM.

**Architecture:** Semua perubahan mengikuti pola Riverpod yang sudah ada (FutureProvider.autoDispose, AsyncNotifier, Notifier). DB migrations dijalankan manual di Supabase SQL Editor. Notifikasi menggunakan tabel baru `notifications` dengan RLS community-scoped.

**Tech Stack:** Flutter, Dart, Riverpod (flutter_riverpod ^3), GoRouter, Supabase (PostgreSQL + Auth), Deno Edge Functions.

**Spec:** `docs/superpowers/specs/2026-03-17-rukunin-feature-batch-design.md`

---

## Chunk 1: DB Migrations + Quick Fixes (Tasks 9, 11, 8)

### Task DB-1: Buat dan Jalankan DB Migrations

**Files:**
- Create: `supabase/migrations/20260317_add_marketplace_stock.sql`
- Create: `supabase/migrations/20260317_add_notifications_table.sql`

- [ ] **Step 1: Buat migration marketplace stock**

```sql
-- supabase/migrations/20260317_add_marketplace_stock.sql
ALTER TABLE public.marketplace_listings
  ADD COLUMN IF NOT EXISTS stock INTEGER NOT NULL DEFAULT 1;
```

- [ ] **Step 2: Buat migration tabel notifications**

```sql
-- supabase/migrations/20260317_add_notifications_table.sql
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('payment', 'announcement', 'join_request', 'join_approved', 'join_rejected')),
  title TEXT NOT NULL,
  body TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_read_own_notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_insert_community_notifications" ON public.notifications
  FOR INSERT WITH CHECK (
    community_id = (SELECT community_id FROM public.profiles WHERE id = auth.uid())
  );

CREATE POLICY "user_update_own_notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);
```

- [ ] **Step 3: Jalankan kedua SQL di Supabase SQL Editor** (manual)
  - Buka Supabase Dashboard → SQL Editor
  - Jalankan `20260317_add_marketplace_stock.sql`
  - Jalankan `20260317_add_notifications_table.sql`
  - Verifikasi: tabel `notifications` muncul di Table Editor, kolom `stock` muncul di `marketplace_listings`

- [ ] **Step 4: Commit migrations**

```bash
git add supabase/migrations/20260317_add_marketplace_stock.sql supabase/migrations/20260317_add_notifications_table.sql
git commit -m "feat(db): add marketplace stock column and notifications table"
```

---

### Task 9: Fix Lokasi Komunitas Tidak Tersimpan

**Files:**
- Modify: `lib/features/community/screens/community_settings_screen.dart`

Baca seluruh file `community_settings_screen.dart` dulu sebelum edit.

- [ ] **Step 1: Baca `community_settings_screen.dart` — verifikasi situasi aktual**

Baca file lengkap. Kamu akan menemukan:
- Method `_save()` sudah mengandung wilayah fields dengan conditional inclusion (`if (_provinsi != null) 'province': _provinsi!.name`, dst). **Step save SUDAH benar — tidak perlu diubah.**
- Method `_loadCommunity()` memiliki blok `if (c != null) { ... }` yang mengisi `_nameCtrl`, `_rwCtrl`, dan `_rtCount`, tapi **BELUM** mengisi `_provinsi`, `_kabupaten`, `_kecamatan`, `_kelurahan`. Inilah satu-satunya bug.

- [ ] **Step 2: Tambah populate wilayah di dalam blok `if (c != null)` di `_loadCommunity()`**

Temukan blok `if (c != null) {` (variabel bernama `c`, bukan `data`). Tepat setelah baris `_rtCount = (c['rt_count'] as int?) ?? 3;`, tambahkan:

```dart
// Tambahkan tepat di dalam if (c != null) { ... }, setelah _rtCount:
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
```

Ini membuat display nama wilayah muncul kembali saat halaman dibuka. Catatan: `WilayahModel(id: '', ...)` cukup untuk teks tampilan — `id` hanya dibutuhkan saat user memilih ulang lewat dropdown API.

- [ ] **Step 4: Verifikasi manual**
  - Jalankan `flutter run`
  - Login sebagai admin → Pengaturan Komunitas
  - Pilih provinsi, kabupaten, kecamatan, kelurahan → Simpan
  - Tutup screen, buka lagi → wilayah yang dipilih harus tampil kembali

- [ ] **Step 5: Commit**

```bash
git add lib/features/community/screens/community_settings_screen.dart
git commit -m "fix: save and reload wilayah in community settings"
```

---

### Task 11: Detail Pending Warga Bisa Diklik

**Files:**
- Modify: `lib/features/residents/screens/residents_screen.dart`

`_PendingCard` saat ini menampilkan nama + HP + tombol approve/reject tapi tidak ada detail lengkap. Kita tambahkan bottom sheet detail yang muncul saat tap card.

- [ ] **Step 1: Baca `_PendingCard` widget di residents_screen.dart**

Temukan class `_PendingCard` (sekitar baris 615). Pahami field yang tersedia dari `ResidentModel`.

- [ ] **Step 2: Bungkus `_PendingCard` content dengan `InkWell` dan tambah `onTap`**

Ganti `Container` terluar `_PendingCard` dengan `Material` + `InkWell`, atau tambahkan `onTap` ke GestureDetector yang sudah ada di parent. Saat tap → `_showDetailSheet(context, resident, onApprove, onReject)`.

- [ ] **Step 3: Tambahkan method `_showDetailSheet` ke `_PendingCard` atau sebagai fungsi top-level**

```dart
void _showPendingDetailSheet(
  BuildContext context,
  ResidentModel resident,
  VoidCallback onApprove,
  VoidCallback onReject,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Detail Warga Pending',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey800,
            )),
          const SizedBox(height: 20),
          _detailRow(Icons.person_rounded, 'Nama Lengkap', resident.fullName),
          _detailRow(Icons.phone_android_rounded, 'No. Handphone', resident.phone ?? '-'),
          _detailRow(Icons.badge_rounded, 'NIK', resident.nik ?? '-'),
          _detailRow(Icons.home_work_rounded, 'Blok / Unit', [
            if (resident.block != null) 'Blok ${resident.block}',
            if (resident.unitNumber != null) 'No. ${resident.unitNumber}',
          ].join(' ').trim().isEmpty ? '-' : [
            if (resident.block != null) 'Blok ${resident.block}',
            if (resident.unitNumber != null) 'No. ${resident.unitNumber}',
          ].join(' ')),
          _detailRow(Icons.numbers_rounded, 'RT', resident.rtNumber != null ? 'RT ${resident.rtNumber}' : '-'),
          _detailRow(Icons.calendar_today_rounded, 'Tanggal Daftar',
            DateFormat('d MMMM yyyy', 'id_ID').format(resident.createdAt)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () { Navigator.of(ctx).pop(); onReject(); },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Tolak', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () { Navigator.of(ctx).pop(); onApprove(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Setujui', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _detailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.grey500)),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey800)),
          ],
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Update `_PendingCard.build()` untuk panggil `_showPendingDetailSheet` saat tap**

Bungkus seluruh `Container` dalam `_PendingCard.build()` dengan:

```dart
return GestureDetector(
  onTap: () => _showPendingDetailSheet(context, resident, onApprove, onReject),
  child: Container( /* existing container content */ ),
);
```

- [ ] **Step 5: Verifikasi manual**
  - Jalankan `flutter run`
  - Login admin → Data Warga → tap banner pending
  - Tap salah satu card pending → bottom sheet detail muncul dengan semua info
  - Tombol Setujui/Tolak berfungsi

- [ ] **Step 6: Commit**

```bash
git add lib/features/residents/screens/residents_screen.dart
git commit -m "feat: add detail bottom sheet for pending resident approval"
```

---

### Task 8: Edit Kendaraan di Profil (Resident + Admin)

**Files:**
- Modify: `lib/features/resident_portal/screens/resident_profile_screen.dart`
- Modify: `lib/features/settings/screens/admin_profile_screen.dart`

- [ ] **Step 1: Baca seluruh `resident_profile_screen.dart` dan cari section "Kendaraan Terdaftar"**

Section ini ada sekitar baris 230. Saat ini read-only.

- [ ] **Step 2: Tambahkan icon edit di header section "Kendaraan Terdaftar" di ResidentProfileScreen**

Ubah Text widget section title menjadi Row dengan icon pensil:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Kendaraan Terdaftar', style: /* existing style */),
    GestureDetector(
      onTap: () => _showEditVehicleSheet(context, profile.motorcycleCount, profile.carCount, profile.id),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
      ),
    ),
  ],
),
```

- [ ] **Step 3: Tambahkan method `_showEditVehicleSheet` ke `_ResidentProfileScreenState`**

```dart
Future<void> _showEditVehicleSheet(
  BuildContext context,
  int initialMotorcycle,
  int initialCar,
  String userId,
) async {
  int motorcycle = initialMotorcycle;
  int car = initialCar;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit Kendaraan', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey800)),
            const SizedBox(height: 24),
            _vehicleStepper(
              icon: Icons.two_wheeler_rounded,
              label: 'Motor',
              value: motorcycle,
              onDecrement: () => setModalState(() { if (motorcycle > 0) motorcycle--; }),
              onIncrement: () => setModalState(() { if (motorcycle < 10) motorcycle++; }),
            ),
            const SizedBox(height: 16),
            _vehicleStepper(
              icon: Icons.directions_car_rounded,
              label: 'Mobil',
              value: car,
              onDecrement: () => setModalState(() { if (car > 0) car--; }),
              onIncrement: () => setModalState(() { if (car < 10) car++; }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _saveVehicle(userId, motorcycle, car);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Simpan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _vehicleStepper({
  required IconData icon,
  required String label,
  required int value,
  required VoidCallback onDecrement,
  required VoidCallback onIncrement,
}) {
  return Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600))),
      IconButton(
        onPressed: onDecrement,
        icon: const Icon(Icons.remove_circle_outline_rounded),
        color: AppColors.grey500,
      ),
      Text('$value', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
      IconButton(
        onPressed: onIncrement,
        icon: const Icon(Icons.add_circle_outline_rounded),
        color: AppColors.primary,
      ),
    ],
  );
}

Future<void> _saveVehicle(String userId, int motorcycle, int car) async {
  try {
    final client = ref.read(supabaseClientProvider);
    await client.from('profiles').update({
      'motorcycle_count': motorcycle,
      'car_count': car,
    }).eq('id', userId);
    ref.invalidate(currentResidentProfileProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data kendaraan berhasil diperbarui ✅'), backgroundColor: AppColors.success),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}
```

- [ ] **Step 4: Update `admin_profile_screen.dart`**

Setelah membaca file: `AdminProfileScreen` adalah `ConsumerWidget`, tidak ada fetch profil dari DB, dan tidak ada tampilan kendaraan sama sekali. Langkah-langkah:

**4a. Convert ke `ConsumerStatefulWidget`** karena kita butuh local state `_motorcycleCount` dan `_carCount`:

```dart
class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  int _motorcycleCount = 0;
  int _carCount = 0;
  bool _loadingVehicle = true;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) { setState(() => _loadingVehicle = false); return; }
    final profile = await client.from('profiles').select('motorcycle_count, car_count').eq('id', userId).maybeSingle();
    if (mounted) {
      setState(() {
        _motorcycleCount = (profile?['motorcycle_count'] as int?) ?? 0;
        _carCount = (profile?['car_count'] as int?) ?? 0;
        _loadingVehicle = false;
      });
    }
  }

  // Pindahkan _logout ke dalam state class (sama persis)
  Future<void> _logout(BuildContext context) async { /* pindahkan dari ConsumerWidget */ }

  Future<void> _saveVehicle(int motorcycle, int car) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('profiles').update({'motorcycle_count': motorcycle, 'car_count': car}).eq('id', userId);
      setState(() { _motorcycleCount = motorcycle; _carCount = car; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data kendaraan berhasil diperbarui ✅'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
```

**4b. Tambahkan section "Kendaraan Terdaftar"** di `build()` — sisipkan setelah section Pengaturan menu card, sebelum SizedBox(height: 48) sebelum logout:

```dart
// Di dalam ListView, setelah _buildMenuCard(...)
const SizedBox(height: 24),
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Kendaraan Terdaftar', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.grey800)),
    if (!_loadingVehicle)
      GestureDetector(
        onTap: () => _showEditVehicleSheet(context),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
        ),
      ),
  ],
),
const SizedBox(height: 12),
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
  ),
  child: _loadingVehicle
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          _buildProfileItem(Icons.two_wheeler_rounded, 'Motor', '$_motorcycleCount Unit'),
          const Divider(height: 24, color: AppColors.grey200),
          _buildProfileItem(Icons.directions_car_rounded, 'Mobil', '$_carCount Unit'),
        ],
      ),
),
```

**4c. Tambahkan `_showEditVehicleSheet` dan `_buildProfileItem`** — reuse pola yang sama dari ResidentProfileScreen (copy helper `_vehicleStepper` dan `_showEditVehicleSheet`, ganti `ref.invalidate(...)` dengan `setState`).

**4d. Update `build()` signature** dari `build(BuildContext context, WidgetRef ref)` ke `build(BuildContext context)` karena sekarang state class.

> **Catatan:** `ref` di state class diakses via `this.ref` (sudah tersedia di `ConsumerState`), tidak perlu parameter.

- [ ] **Step 5: Verifikasi manual**
  - Login warga → Akun → tap icon edit di Kendaraan → stepper muncul → simpan → nilai berubah
  - Login admin → Profil → edit kendaraan → simpan → nilai berubah

- [ ] **Step 6: Commit**

```bash
git add lib/features/resident_portal/screens/resident_profile_screen.dart lib/features/settings/screens/admin_profile_screen.dart
git commit -m "feat: add vehicle count edit in resident and admin profile"
```

---

## Chunk 2: Marketplace Stock (Task 7) + Filter Laporan (Task 6)

### Task 7: Marketplace Stock

**Files:**
- Modify: `lib/features/marketplace/models/marketplace_listing_model.dart`
- Modify: `lib/features/marketplace/providers/marketplace_provider.dart`
- Modify: `lib/features/marketplace/screens/add_listing_screen.dart`
- Modify: `lib/features/marketplace/screens/listing_detail_screen.dart`

#### 7a: Update Model

- [ ] **Step 1: Tambah field `stock` ke `MarketplaceListingModel`**

```dart
// Tambah di constructor fields:
final int stock;

// Tambah di constructor:
required this.stock,

// Tambah di fromMap():
stock: (map['stock'] as num?)?.toInt() ?? 1,

// Tambah computed getter:
bool get isAvailable => status == 'active' && stock > 0;
```

- [ ] **Step 2: Fix bug status enum — ganti `'available'` → `'active'` di provider**

Di `lib/features/marketplace/providers/marketplace_provider.dart`:
- Baris 41: `.eq('status', 'available')` → `.eq('status', 'active')`
- Baris 90 (dalam `createListing`): `'status': 'available'` → `'status': 'active'`

- [ ] **Step 3: Fix status enum di `listing_detail_screen.dart` — baris 587**

Di class `_StatusChip`, baris 587, ubah:
```dart
// SEBELUM:
final isAvailable = status == 'available';
// SESUDAH:
final isAvailable = status == 'active';
```

Juga cek file ini untuk query `.eq('status', 'available')` — ganti ke `'active'` jika ada.

- [ ] **Step 4: Update `createListing()` di `marketplace_provider.dart` untuk include `stock`**

```dart
Future<void> createListing({
  // ... parameter yang ada ...
  required int stock, // tambah parameter baru
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('marketplace_listings').insert({
    // ... field yang ada ...
    'status': 'active', // sudah difix di step 2
    'stock': stock,     // tambah ini
  });
  // ...
}
```

- [ ] **Step 5: Update `editListing()` — ganti seluruh method dengan versi lengkap ini**

```dart
Future<void> editListing({
  required String listingId,
  required String title,
  required String category,
  String? description,
  int? price,
  List<String>? imageUrls,
  int? stock,
}) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('marketplace_listings').update({
    'title': title,
    'category': category,
    'description': description,
    'price': price ?? 0,
    if (imageUrls != null) 'images': imageUrls,
    if (stock != null) 'stock': stock,
    if (stock != null && stock <= 0) 'status': 'sold',
  }).eq('id', listingId);
  ref.invalidate(marketplaceListingsProvider);
  ref.invalidate(myListingsProvider);
}
```

- [ ] **Step 6: Update `markAsSold()` untuk set stock = 0**

```dart
Future<void> markAsSold(String listingId) async {
  final client = ref.read(supabaseClientProvider);
  await client.from('marketplace_listings').update({
    'status': 'sold',
    'stock': 0,
  }).eq('id', listingId);
  // ...
}
```

#### 7b: Update AddListingScreen

- [ ] **Step 7: Baca `add_listing_screen.dart` dan tambahkan field stock**

Tambahkan controller dan state:
```dart
final _stockCtrl = TextEditingController(text: '1');
```

Dispose di `dispose()`:
```dart
_stockCtrl.dispose();
```

Saat load existing listing (edit mode):
```dart
_stockCtrl.text = existing.stock.toString();
```

- [ ] **Step 8: Tambahkan input field stock di form UI**

Di bagian bawah form (setelah harga, sebelum tombol simpan):
```dart
_textField(
  controller: _stockCtrl,
  hint: 'Jumlah stok tersedia',
  label: 'Stok',
  icon: Icons.inventory_2_rounded,
  keyboardType: TextInputType.number,
  validator: (v) {
    if (v == null || v.isEmpty) return 'Stok wajib diisi';
    final n = int.tryParse(v);
    if (n == null || n < 0) return 'Stok harus angka ≥ 0';
    return null;
  },
),
```

- [ ] **Step 9: Pass `stock` ke `createListing()` dan `editListing()` saat submit**

```dart
final stock = int.tryParse(_stockCtrl.text) ?? 1;
// Saat create: tambahkan stock: stock
// Saat edit: tambahkan stock: stock
```

#### 7c: Update ListingDetailScreen

- [ ] **Step 10: Baca `listing_detail_screen.dart` dan temukan tempat tampil harga/status**

- [ ] **Step 11: Tambahkan badge stock di bawah harga**

```dart
// Di bawah widget harga:
Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: listing.isAvailable
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        listing.isAvailable ? 'Stok: ${listing.stock}' : 'Habis',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: listing.isAvailable ? AppColors.success : AppColors.error,
        ),
      ),
    ),
  ],
),
```

- [ ] **Step 12: Sembunyikan tombol "Hubungi Penjual" jika `!listing.isAvailable`**

Tambahkan kondisi: `if (listing.isAvailable) ...` di sekitar tombol kontak.

- [ ] **Step 13: Verifikasi manual**
  - Buat listing baru dengan stok 2 → tampil di feed
  - Buka detail → badge "Stok: 2" muncul
  - Mark as sold → badge berubah ke "Habis", tombol hubungi hilang
  - Verifikasi `flutter analyze` tidak ada error

- [ ] **Step 14: Commit**

```bash
git add lib/features/marketplace/models/marketplace_listing_model.dart \
  lib/features/marketplace/providers/marketplace_provider.dart \
  lib/features/marketplace/screens/add_listing_screen.dart \
  lib/features/marketplace/screens/listing_detail_screen.dart
git commit -m "feat: add stock field to marketplace, fix status enum active vs available"
```

---

### Task 6: Filter Laporan Keuangan + Transparansi Kas Warga

**Files:**
- Modify: `lib/features/reports/providers/report_provider.dart`
- Modify: `lib/features/reports/screens/reports_screen.dart`
- Modify: `lib/features/resident_portal/providers/resident_kas_provider.dart`
- Modify: `lib/features/resident_portal/screens/resident_kas_screen.dart`

#### 6a: Filter Laporan Admin

- [ ] **Step 1: Baca `report_provider.dart` untuk memahami `ReportNotifier` state**

- [ ] **Step 2: Update `report_model.dart` dan `report_provider.dart`**

**2a. Tambah enum ke `lib/features/reports/models/report_model.dart`** (di atas class `MonthlyReport`):

```dart
enum ReportFilterMode { currentMonth, threeMonths, sixMonths, custom }
```

**2b. Tambah field `filterMode` ke `ReportState`** di `report_model.dart`:

```dart
class ReportState {
  final int selectedMonth;
  final int selectedYear;
  final MonthlyReport currentMonthReport;
  final List<MonthlyReport> lastSixMonths;
  final bool isLoading;
  final String? error;
  final ReportFilterMode filterMode;  // ← TAMBAH INI

  ReportState({
    required this.selectedMonth,
    required this.selectedYear,
    required this.currentMonthReport,
    required this.lastSixMonths,
    this.isLoading = false,
    this.error,
    this.filterMode = ReportFilterMode.currentMonth,  // ← TAMBAH INI
  });

  ReportState copyWith({
    int? selectedMonth,
    int? selectedYear,
    MonthlyReport? currentMonthReport,
    List<MonthlyReport>? lastSixMonths,
    bool? isLoading,
    String? error,
    ReportFilterMode? filterMode,  // ← TAMBAH INI
  }) {
    return ReportState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      currentMonthReport: currentMonthReport ?? this.currentMonthReport,
      lastSixMonths: lastSixMonths ?? this.lastSixMonths,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterMode: filterMode ?? this.filterMode,  // ← TAMBAH INI
    );
  }
}
```

**2c. Tambah method `setFilterMode` ke `ReportNotifier`** di `report_provider.dart`:

```dart
void setFilterMode(ReportFilterMode mode) {
  final now = DateTime.now();
  // Semua mode tetap load data bulan sekarang (loadReportData selalu fetch 6 bulan)
  // filterMode hanya mengontrol UI: berapa bar yang ditampilkan di grafik
  state = state.copyWith(
    filterMode: mode,
    // Untuk currentMonth: kembali ke bulan sekarang
    selectedMonth: mode == ReportFilterMode.currentMonth ? now.month : state.selectedMonth,
    selectedYear: mode == ReportFilterMode.currentMonth ? now.year : state.selectedYear,
  );
  if (mode == ReportFilterMode.currentMonth) {
    loadReportData(now.month, now.year);
  }
  // threeMonths, sixMonths, custom: data sudah ada dari loadReportData terakhir
  // UI di ReportsScreen akan membaca state.filterMode untuk memutuskan tampilan
}
```

> **Catatan:** `loadReportData` sudah selalu fetch 6 bulan terakhir. Mode "3 Bulan" cukup menampilkan 3 bar terakhir dari `lastSixMonths` — tidak butuh method baru. Mode "Pilih Bulan" (custom) mengekspos chevron navigation yang sudah ada (tidak memanggil load baru).

- [ ] **Step 3: Update `reports_screen.dart` untuk tampilkan chip filter**

Di bawah AppBar atau di atas konten laporan, tambahkan chip row:

```dart
// Filter chips row
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  child: Row(
    children: [
      _filterChip('Bulan Ini', ReportFilterMode.currentMonth, state.filterMode, notifier),
      const SizedBox(width: 8),
      _filterChip('3 Bulan', ReportFilterMode.threeMonths, state.filterMode, notifier),
      const SizedBox(width: 8),
      _filterChip('6 Bulan', ReportFilterMode.sixMonths, state.filterMode, notifier),
      const SizedBox(width: 8),
      _filterChip('Pilih Bulan', ReportFilterMode.custom, state.filterMode, notifier),
    ],
  ),
),
```

```dart
Widget _filterChip(String label, ReportFilterMode mode, ReportFilterMode current, ReportNotifier notifier) {
  final isSelected = current == mode;
  return GestureDetector(
    onTap: () => notifier.setFilterMode(mode),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey300),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.onPrimary : AppColors.grey600,
        ),
      ),
    ),
  );
}
```

"Pilih Bulan" chip hanya set `filterMode = custom` — tidak membuka dialog baru. Dalam `reports_screen.dart`, tambahkan kondisi: jika `state.filterMode == ReportFilterMode.custom`, tampilkan row chevron kiri/kanan yang sudah ada di screen (yang sebelumnya selalu visible). Untuk mode lain, sembunyikan chevron row. Dengan begitu, "Pilih Bulan" secara efektif mengekspos navigasi manual yang sudah ada.

Konkretnya, di `reports_screen.dart`:
```dart
// Tampilkan chevron navigation hanya saat mode custom:
if (state.filterMode == ReportFilterMode.custom)
  _MonthSelectorRow(state: state, notifier: notifier),
```

Di mana `_MonthSelectorRow` adalah widget yang mengandung chevron kiri/kanan yang sudah ada.

Untuk tampilan grafik, di bagian yang render bar chart:
```dart
// Tampilkan hanya N bar sesuai filterMode:
final barsToShow = state.filterMode == ReportFilterMode.threeMonths ? 3 : 6;
final visibleMonths = state.lastSixMonths.length > barsToShow
    ? state.lastSixMonths.sublist(state.lastSixMonths.length - barsToShow)
    : state.lastSixMonths;
```

#### 6b: Filter Transparansi Kas Warga

- [ ] **Step 4: Convert `residentKasProvider` ke family di `resident_kas_provider.dart`**

```dart
// Ganti:
final residentKasProvider = FutureProvider.autoDispose<ResidentKasData>((ref) async {
  // ...
  final now = DateTime.now();
  final month = now.month;
  final year = now.year;
  // ...
});

// Menjadi:
typedef KasFilter = ({int month, int year});

final residentKasProvider = FutureProvider.autoDispose.family<ResidentKasData, KasFilter>((ref, filter) async {
  // ...
  final month = filter.month;
  final year = filter.year;
  // Semua query yang pakai month/year sekarang pakai filter.month dan filter.year
  // ...
  return ResidentKasData(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    recentExpenses: recentExpenses,
    currentMonth: month,
    currentYear: year,
  );
});
```

- [ ] **Step 5: Update `resident_kas_screen.dart` untuk state filter dan dropdown**

Ubah ke `ConsumerStatefulWidget` jika belum, tambahkan:
```dart
int _selectedMonth = DateTime.now().month;
int _selectedYear = DateTime.now().year;
```

Watch dengan filter:
```dart
final kasAsync = ref.watch(residentKasProvider((month: _selectedMonth, year: _selectedYear)));
```

Tambahkan dropdown bulan/tahun di header (dalam `CustomScrollView` atau `AppBar` actions):
```dart
// Contoh sederhana — dua dropdown inline
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    DropdownButton<int>(
      value: _selectedMonth,
      items: List.generate(12, (i) => DropdownMenuItem(
        value: i + 1,
        child: Text(DateFormat('MMM', 'id_ID').format(DateTime(0, i + 1))),
      )),
      onChanged: (v) => setState(() => _selectedMonth = v!),
      underline: const SizedBox(),
    ),
    DropdownButton<int>(
      value: _selectedYear,
      items: [
        DateTime.now().year - 1,
        DateTime.now().year,
      ].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
      onChanged: (v) => setState(() => _selectedYear = v!),
      underline: const SizedBox(),
    ),
  ],
),
```

- [ ] **Step 6: Verifikasi manual**
  - Admin → Laporan → chip filter berfungsi
  - Warga → Kas RT → dropdown bulan/tahun berfungsi, data berubah

- [ ] **Step 7: Commit**

```bash
git add lib/features/reports/providers/report_provider.dart \
  lib/features/reports/screens/reports_screen.dart \
  lib/features/resident_portal/providers/resident_kas_provider.dart \
  lib/features/resident_portal/screens/resident_kas_screen.dart
git commit -m "feat: add period filter to reports and resident kas screen"
```

---

## Chunk 3: Registrasi 2 Langkah (Task 10) + Help Center (Task 13)

### Task 10: Refactor Registrasi Warga (2 Halaman)

**Files:**
- Modify: `lib/features/auth/screens/register_resident_screen.dart` → menjadi Step 1
- Create: `lib/features/auth/screens/register_resident_step2_screen.dart`
- Create: `lib/features/auth/models/register_step1_data.dart`
- Modify: `lib/features/auth/providers/register_provider.dart`
- Modify: `lib/app/router.dart`

#### 10a: Model Data

- [ ] **Step 1: Buat `RegisterStep1Data` plain Dart class**

```dart
// lib/features/auth/models/register_step1_data.dart
class RegisterStep1Data {
  final String communityId;
  final String communityCode;
  final String fullName;
  final String phone;
  final String email;
  final String password;

  const RegisterStep1Data({
    required this.communityId,
    required this.communityCode,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
  });
}
```

#### 10b: Update RegisterService

- [ ] **Step 2: Tambah `checkCommunityCode()` dan update `registerResident()` di `register_provider.dart`**

```dart
// Tambah method baru — validasi kode dan return communityId
Future<String> checkCommunityCode(String code) async {
  final community = await client
      .from('communities')
      .select('id')
      .eq('community_code', code.toUpperCase().trim())
      .maybeSingle();
  if (community == null) {
    throw Exception('Kode komunitas "$code" tidak ditemukan. Pastikan kode benar.');
  }
  return community['id'] as String;
}

// Update registerResident — ganti parameter communityCode → communityId
Future<void> registerResident({
  required String communityId,   // DIUBAH: dulu communityCode
  required String fullName,
  required String phone,
  required String email,
  required String password,
  String? nik,
  String? unitNumber,
  String? block,
  int? rtNumber,
}) async {
  // 1. Create auth user (tidak perlu lookup community lagi)
  final response = await client.auth.signUp(email: email, password: password);
  final userId = response.user?.id;
  if (userId == null) throw Exception('Gagal membuat akun. Coba lagi.');

  // 2. Insert resident profile with status=pending
  await client.from('profiles').insert({
    'id': userId,
    'community_id': communityId,  // langsung pakai communityId
    'full_name': fullName,
    'phone': phone,
    'email': email,
    'nik': (nik == null || nik.isEmpty) ? null : nik,
    'unit_number': (unitNumber == null || unitNumber.isEmpty) ? null : unitNumber,
    'block': (block == null || block.isEmpty) ? null : block.toUpperCase(),
    'rt_number': rtNumber ?? 1,
    'role': 'resident',
    'status': 'pending',
  });
}
```

#### 10c: Refactor Step 1 Screen

- [ ] **Step 3: Simplify `register_resident_screen.dart` menjadi Step 1 saja**

Hapus semua field opsional dari screen ini:
- Hapus `_nikCtrl`, `_unitCtrl`, `_blockCtrl`, `_rtCtrl` beserta `dispose()`-nya
- Hapus field form NIK, Blok, Unit, RT dari `build()`
- Pertahankan: `_codeCtrl`, `_nameCtrl`, `_phoneCtrl`, `_emailCtrl`, `_passCtrl`

**PENTING: Hapus seluruh body `_submit()` yang lama** (yang memanggil `service.registerResident(communityCode: ...)`), kemudian ganti dengan:

```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _loading = true);
  try {
    final service = ref.read(registerServiceProvider);
    final communityId = await service.checkCommunityCode(_codeCtrl.text.trim());
    final step1Data = RegisterStep1Data(
      communityId: communityId,
      communityCode: _codeCtrl.text.trim().toUpperCase(),
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (mounted) context.push('/register/resident/step2', extra: step1Data);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
```

Update tombol dari "Daftar" → "Lanjut →".

#### 10d: Buat Step 2 Screen

- [ ] **Step 4: Buat `register_resident_step2_screen.dart`**

Screen ini menerima `RegisterStep1Data` via constructor (dipass dari route `extra`).

```dart
// lib/features/auth/screens/register_resident_step2_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/register_step1_data.dart';
import '../providers/register_provider.dart';

const _kYellow = Color(0xFFFFC107);
const _kBlack = Color(0xFF0D0D0D);
const _kWhite = Color(0xFFFFFFFF);

class RegisterResidentStep2Screen extends ConsumerStatefulWidget {
  final RegisterStep1Data step1Data;
  const RegisterResidentStep2Screen({super.key, required this.step1Data});

  @override
  ConsumerState<RegisterResidentStep2Screen> createState() => _Step2State();
}

class _Step2State extends ConsumerState<RegisterResidentStep2Screen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nikCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();
  final _rtCtrl = TextEditingController();
  bool _loading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nikCtrl.dispose(); _unitCtrl.dispose(); _blockCtrl.dispose(); _rtCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(registerServiceProvider);
      await service.registerResident(
        communityId: widget.step1Data.communityId,
        fullName: widget.step1Data.fullName,
        phone: widget.step1Data.phone,
        email: widget.step1Data.email,
        password: widget.step1Data.password,
        nik: _nikCtrl.text.trim(),
        unitNumber: _unitCtrl.text.trim(),
        block: _blockCtrl.text.trim(),
        rtNumber: int.tryParse(_rtCtrl.text.trim()),
      );
      if (mounted) context.go('/pending-approval');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendaftar: $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _kYellow,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // TOP
            Expanded(
              flex: 3,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _kBlack.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: _kBlack, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Info\nTambahan\n(Opsional)',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: size.width * 0.115,
                          fontWeight: FontWeight.w900,
                          color: _kBlack,
                          height: 1.0,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Boleh dilewati, bisa diisi nanti.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _kBlack.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // BOTTOM
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _kBlack,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data ini membantu admin mengenal kamu.',
                        style: GoogleFonts.plusJakartaSans(color: _kWhite.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      _DarkTextField(controller: _nikCtrl, hint: 'NIK (16 digit)', icon: Icons.badge_rounded, keyboardType: TextInputType.number, textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      _DarkTextField(controller: _blockCtrl, hint: 'Blok (contoh: A)', icon: Icons.home_work_rounded, textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      _DarkTextField(controller: _unitCtrl, hint: 'No. Rumah / Unit', icon: Icons.numbers_rounded, keyboardType: TextInputType.number, textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      _DarkTextField(controller: _rtCtrl, hint: 'No. RT', icon: Icons.location_on_rounded, keyboardType: TextInputType.number, textInputAction: TextInputAction.done),
                      const Spacer(),
                      // Tombol Daftar
                      GestureDetector(
                        onTap: _loading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 56,
                          decoration: BoxDecoration(
                            color: _loading ? _kYellow.withValues(alpha: 0.6) : _kYellow,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: _kBlack))
                              : Text('Daftar →', style: GoogleFonts.plusJakartaSans(color: _kBlack, fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Lewati
                      GestureDetector(
                        onTap: _loading ? null : _submit, // submit dengan field kosong = skip
                        child: Center(
                          child: Text(
                            'Lewati, daftar tanpa info tambahan',
                            style: GoogleFonts.plusJakartaSans(
                              color: _kWhite.withValues(alpha: 0.4),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: _kWhite.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reuse _DarkTextField dari login_screen atau definisikan ulang (untuk menghindari dependency antar screen)
class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(color: _kWhite, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: _kWhite.withValues(alpha: 0.3), fontSize: 14),
        prefixIcon: Icon(icon, color: _kWhite.withValues(alpha: 0.35), size: 18),
        filled: true,
        fillColor: _kWhite.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _kWhite.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _kWhite.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kYellow, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF6B6B))),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
```

#### 10e: Update Router

- [ ] **Step 5: Tambahkan route Step 2 ke `router.dart`**

```dart
// Tambahkan import:
import '../features/auth/screens/register_resident_step2_screen.dart';
import '../features/auth/models/register_step1_data.dart';

// Tambahkan route (di luar ShellRoute, bersama route auth lainnya):
GoRoute(
  path: '/register/resident/step2',
  builder: (context, state) => RegisterResidentStep2Screen(
    step1Data: state.extra as RegisterStep1Data,
  ),
),
```

Juga tambahkan `/register/resident/step2` ke `authPages` list di redirect logic agar user yang belum login bisa akses screen ini:

```dart
const authPages = ['/login', '/register/admin', '/register/resident', '/register/resident/step2', '/forgot-password', '/reset-password'];
```

- [ ] **Step 6: Verifikasi manual**
  - Tap "Gabung sbg Warga" → form Step 1 muncul
  - Isi kode komunitas yang salah → error muncul di Step 1
  - Isi kode komunitas yang benar → pindah ke Step 2
  - Tap "Lewati" → redirect ke `/pending-approval`
  - Isi data opsional → tap "Daftar →" → redirect ke `/pending-approval`

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/models/register_step1_data.dart \
  lib/features/auth/screens/register_resident_screen.dart \
  lib/features/auth/screens/register_resident_step2_screen.dart \
  lib/features/auth/providers/register_provider.dart \
  lib/app/router.dart
git commit -m "feat: split resident registration into 2 steps with community code validation"
```

---

### Task 13: Pusat Bantuan (Static FAQ)

**Files:**
- Create: `lib/features/help/screens/help_center_screen.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/features/resident_portal/screens/resident_profile_screen.dart`
- Modify: `lib/features/settings/screens/admin_profile_screen.dart`

- [ ] **Step 1: Buat `help_center_screen.dart`**

```dart
// lib/features/help/screens/help_center_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('📋 Tagihan & Pembayaran', [
            ('Bagaimana cara membayar tagihan?', 'Buka menu Tagihan → pilih tagihan yang belum dibayar → tap "Upload Bukti Bayar" → upload foto bukti transfer. Admin akan memverifikasi dalam 1x24 jam.'),
            ('Tagihan saya sudah dibayar tapi masih "Pending"?', 'Tagihan dalam status "Menunggu Verifikasi" artinya bukti bayar sudah diterima dan sedang ditinjau admin. Tunggu konfirmasi dari admin.'),
            ('Kapan tagihan diterbitkan?', 'Tagihan diterbitkan otomatis setiap tanggal 1 oleh sistem. Kamu akan mendapat notifikasi saat tagihan baru tersedia.'),
            ('Saya tidak bisa upload bukti bayar?', 'Pastikan ukuran foto tidak melebihi 5MB. Coba gunakan foto dari kamera langsung atau compress foto terlebih dahulu.'),
          ]),
          const SizedBox(height: 16),
          _buildSection('👤 Registrasi & Akun', [
            ('Bagaimana cara bergabung ke komunitas?', 'Minta kode komunitas ke admin RT/RW kamu. Lalu tap "Gabung sbg Warga" di halaman login, masukkan kode tersebut dan lengkapi data diri.'),
            ('Akun saya sedang "Menunggu Persetujuan"?', 'Setelah mendaftar, admin perlu menyetujui akunmu. Hubungi admin RT/RW kamu agar segera diproses.'),
            ('Bagaimana cara mengganti password?', 'Di halaman login, tap "Lupa password?" → masukkan email → cek email untuk link reset password.'),
            ('Data profil saya salah, bagaimana mengubahnya?', 'Hubungi admin RT/RW untuk update data profil seperti nama, NIK, atau nomor unit.'),
          ]),
          const SizedBox(height: 16),
          _buildSection('🛍️ Marketplace', [
            ('Bagaimana cara menjual barang?', 'Buka menu Marketplace → tap tombol "+" → isi detail barang (judul, kategori, harga, stok, foto) → tap Simpan.'),
            ('Bagaimana menandai barang sudah terjual?', 'Buka listing barang kamu → tap "Tandai Terjual". Barang akan hilang dari feed marketplace.'),
            ('Bagaimana cara menghubungi penjual?', 'Buka detail listing → tap tombol "Hubungi Penjual via WA" untuk chat langsung di WhatsApp.'),
          ]),
          const SizedBox(height: 16),
          _buildSection('❓ Lainnya', [
            ('Aplikasi lambat atau error?', 'Coba tutup dan buka ulang aplikasi. Pastikan koneksi internet stabil. Jika masalah berlanjut, hubungi admin komunitasmu.'),
            ('Bagaimana cara melaporkan masalah?', 'Hubungi admin RT/RW kamu langsung melalui WhatsApp atau secara langsung.'),
          ]),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Rukunin v1.0 — Dikembangkan untuk kemudahan warga',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.grey400),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<(String, String)> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey800),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              final (question, answer) = entry.value;
              return Column(
                children: [
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    title: Text(question, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey800)),
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.grey400,
                    children: [
                      Text(answer, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.grey600, height: 1.5)),
                    ],
                  ),
                  if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.grey100),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Tambahkan route `/bantuan` ke `router.dart`**

```dart
// Import:
import '../features/help/screens/help_center_screen.dart';

// Route (di luar ShellRoute):
GoRoute(
  path: '/bantuan',
  builder: (context, state) => const HelpCenterScreen(),
),
```

Juga tambahkan `/bantuan` ke `authPages` list di redirect logic (baris sekitar 61), agar screen ini bisa diakses saat onboarding tanpa perlu login:

```dart
const authPages = ['/login', '/register/admin', '/register/resident', '/register/resident/step2', '/forgot-password', '/reset-password', '/bantuan'];
```

- [ ] **Step 3: Tambahkan menu "Pusat Bantuan" ke `resident_profile_screen.dart`**

Di ListView, sebelum tombol logout, tambahkan:

```dart
// Sebelum SizedBox(height: 48) sebelum logout button:
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/bantuan'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Pusat Bantuan', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey800)),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
          ],
        ),
      ),
    ),
  ),
),
const SizedBox(height: 16),
```

- [ ] **Step 4: Tambahkan hal yang sama ke `admin_profile_screen.dart`**

- [ ] **Step 5: Verifikasi manual**
  - Warga → Akun → Pusat Bantuan → screen muncul, FAQ expand/collapse
  - Admin → Profil → Pusat Bantuan → sama

- [ ] **Step 6: Commit**

```bash
git add lib/features/help/screens/help_center_screen.dart \
  lib/app/router.dart \
  lib/features/resident_portal/screens/resident_profile_screen.dart \
  lib/features/settings/screens/admin_profile_screen.dart
git commit -m "feat: add help center screen with static FAQ"
```

---

## Chunk 4: Notifikasi Log (Task 12) + FCM Scaffolding (Task 3)

### Task 12: Notifikasi Riwayat In-App

**Files:**
- Create: `lib/features/notifications/models/notification_model.dart`
- Create: `lib/features/notifications/providers/notifications_provider.dart`
- Create: `lib/features/notifications/screens/notifications_screen.dart`
- Create: `supabase/functions/send-announcement-notifications/index.ts`
- Modify: `lib/app/router.dart`
- Modify: `lib/features/resident_portal/screens/resident_profile_screen.dart`
- Modify: `lib/features/settings/screens/admin_profile_screen.dart`
- Modify: `lib/features/invoices/providers/invoice_provider.dart` (atau file tempat `markInvoiceAsPaid`)
- Modify: `lib/features/announcements/providers/announcement_provider.dart`
- Modify: `lib/features/residents/providers/resident_provider.dart`

#### 12a: Model

- [ ] **Step 1: Buat `NotificationModel`**

```dart
// lib/features/notifications/models/notification_model.dart
class NotificationModel {
  final String id;
  final String communityId;
  final String userId;
  final String type; // 'payment' | 'announcement' | 'join_request' | 'join_approved' | 'join_rejected'
  final String title;
  final String? body;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    required this.isRead,
    this.metadata,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  IconData get icon {
    return switch (type) {
      'payment' => Icons.receipt_long_rounded,
      'announcement' => Icons.campaign_rounded,
      'join_request' => Icons.person_add_rounded,
      'join_approved' => Icons.check_circle_rounded,
      'join_rejected' => Icons.cancel_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  // Tambah import Icons dari flutter/material.dart
}
```

> Tambahkan `import 'package:flutter/material.dart';` di file ini untuk `IconData`.

#### 12b: Providers

- [ ] **Step 2: Buat `notifications_provider.dart`**

```dart
// lib/features/notifications/providers/notifications_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/notification_model.dart';

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);

  return (data as List).map((e) => NotificationModel.fromMap(e)).toList();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return 0;

  final data = await client
      .from('notifications')
      .select('id')
      .eq('user_id', userId)
      .eq('is_read', false);

  return (data as List).length;
});

// Helper function untuk insert notifikasi (dipakai di berbagai provider)
Future<void> insertNotification({
  required dynamic client, // SupabaseClient
  required String communityId,
  required String userId,
  required String type,
  required String title,
  String? body,
  Map<String, dynamic>? metadata,
}) async {
  try {
    await client.from('notifications').insert({
      'community_id': communityId,
      'user_id': userId,
      'type': type,
      'title': title,
      if (body != null) 'body': body,
      if (metadata != null) 'metadata': metadata,
    });
  } catch (_) {
    // Notifikasi gagal tidak boleh break flow utama
  }
}
```

#### 12c: Notifications Screen

- [ ] **Step 3: Buat `notifications_screen.dart`**

```dart
// lib/features/notifications/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('notifications').update({'is_read': true}).eq('user_id', userId).eq('is_read', false);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  Future<void> _markRead(WidgetRef ref, String notifId) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('notifications').update({'is_read': true}).eq('id', notifId);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(ref),
            child: Text('Tandai Semua Dibaca', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_off_rounded, size: 64, color: AppColors.grey300),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (ctx, i) => _NotifCard(notif: notifs[i], onTap: () => _markRead(ref, notifs[i].id)),
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeAgo = DateFormat('d MMM, HH:mm', 'id_ID').format(notif.createdAt.toLocal());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead ? AppColors.grey200 : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(notif.icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700, color: AppColors.grey800)),
                  if (notif.body != null) ...[
                    const SizedBox(height: 4),
                    Text(notif.body!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.grey500)),
                  ],
                  const SizedBox(height: 6),
                  Text(timeAgo, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.grey400)),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
```

#### 12d: Bell Icon di Profile Screens

- [ ] **Step 4: Tambah bell icon ke `resident_profile_screen.dart` AppBar**

```dart
// Ubah AppBar:
appBar: AppBar(
  title: const Text('Akun Saya'),
  actions: [
    // Bell icon dengan badge
    Stack(
      children: [
        IconButton(
          onPressed: () => context.push('/resident/notifikasi'),
          icon: const Icon(Icons.notifications_outlined),
        ),
        ref.watch(unreadCountProvider).maybeWhen(
          data: (count) => count > 0
            ? Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              )
            : const SizedBox(),
          orElse: () => const SizedBox(),
        ),
      ],
    ),
    IconButton(
      onPressed: () => _logout(context, ref),
      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
      tooltip: 'Keluar',
    ),
  ],
),
```

- [ ] **Step 5: Tambah bell icon ke `admin_profile_screen.dart` AppBar** (pola sama, route `/admin/notifikasi`)

#### 12e: Routes

- [ ] **Step 6: Tambah 2 route notifikasi ke `router.dart`**

```dart
// Import:
import '../features/notifications/screens/notifications_screen.dart';

// Routes (di luar ShellRoute):
GoRoute(
  path: '/resident/notifikasi',
  builder: (context, state) => const NotificationsScreen(),
),
GoRoute(
  path: '/admin/notifikasi',
  builder: (context, state) => const NotificationsScreen(),
),
```

#### 12f: Insert Notifikasi di Provider-provider

- [ ] **Step 7: Cari dan baca file tempat `markInvoiceAsPaid` diimplementasikan**

Cari: `grep -r "markInvoiceAsPaid" lib/`

- [ ] **Step 8: Tambah insert notifikasi setelah `markInvoiceAsPaid` sukses**

Di dalam method `markInvoiceAsPaid`, setelah update invoice ke status paid, tambahkan:

```dart
// Setelah update invoice sukses:
await insertNotification(
  client: client,
  communityId: invoice.communityId, // atau ambil dari data yang ada
  userId: invoice.residentId,       // warga yang bayar
  type: 'payment',
  title: 'Pembayaran Dikonfirmasi',
  body: 'Tagihan bulan ${invoice.month}/${invoice.year} sudah lunas.',
  metadata: {'invoice_id': invoice.id},
);
```

> Import `insertNotification` dari `notifications_provider.dart`.

- [ ] **Step 9: Tambah insert notifikasi di `approveResident()` dan `rejectResident()`**

Di `resident_provider.dart`, dalam `approveResident()`:

```dart
// Setelah update status ke 'active':
// Fetch communityId dari profile dulu jika belum ada
await insertNotification(
  client: client,
  communityId: /* communityId dari profile */,
  userId: residentId,
  type: 'join_approved',
  title: 'Selamat Datang!',
  body: 'Akunmu sudah disetujui admin. Selamat bergabung!',
);
```

Dalam `rejectResident()`:

```dart
await insertNotification(
  client: client,
  communityId: /* communityId */,
  userId: residentId,
  type: 'join_rejected',
  title: 'Pendaftaran Ditolak',
  body: 'Maaf, pendaftaranmu tidak disetujui admin. Hubungi admin untuk info lebih lanjut.',
);
```

- [ ] **Step 10: Buat Edge Function `send-announcement-notifications` untuk batch insert**

```typescript
// supabase/functions/send-announcement-notifications/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { communityId, announcementTitle, announcementBody } = await req.json();

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Fetch semua warga aktif di komunitas ini
  const { data: residents } = await supabase
    .from("profiles")
    .select("id")
    .eq("community_id", communityId)
    .eq("status", "active")
    .eq("role", "resident");

  if (!residents || residents.length === 0) {
    return new Response(JSON.stringify({ inserted: 0 }), { status: 200 });
  }

  // Batch insert notifikasi
  const notifications = residents.map((r: { id: string }) => ({
    community_id: communityId,
    user_id: r.id,
    type: "announcement",
    title: announcementTitle,
    body: announcementBody,
  }));

  await supabase.from("notifications").insert(notifications);

  return new Response(JSON.stringify({ inserted: notifications.length }), { status: 200 });
});
```

- [ ] **Step 11: Panggil Edge Function dari `announcement_provider.dart` setelah create announcement sukses**

Baca file announcement provider. Setelah insert announcement berhasil, tambahkan:

```dart
// Panggil edge function (fire and forget, tidak await secara rigid)
try {
  final functionsClient = ref.read(supabaseClientProvider).functions;
  await functionsClient.invoke('send-announcement-notifications', body: {
    'communityId': communityId,
    'announcementTitle': title,
    'announcementBody': body,
  });
} catch (_) {
  // Jangan break main flow
}
```

- [ ] **Step 12: Deploy edge function**

```bash
supabase functions deploy send-announcement-notifications
```

- [ ] **Step 13: Verifikasi manual**
  - Admin approve warga → warga dapat notif "Selamat Datang"
  - Admin buat pengumuman → semua warga dapat notif
  - Warga bayar tagihan + admin konfirmasi → warga dapat notif lunas
  - Warga buka profil → bell icon muncul, badge merah kalau ada unread
  - Tap bell → list notif muncul
  - Tap notif → mark as read, badge berkurang

- [ ] **Step 14: Commit**

```bash
git add lib/features/notifications/ \
  lib/app/router.dart \
  lib/features/resident_portal/screens/resident_profile_screen.dart \
  lib/features/settings/screens/admin_profile_screen.dart \
  lib/features/residents/providers/resident_provider.dart \
  supabase/functions/send-announcement-notifications/
# Tambahkan file invoice provider dan announcement provider yang diubah
git commit -m "feat: add in-app notification system with bell icon and activity log"
```

---

### Task 3: FCM Push Notification Scaffolding

> **Status:** Hanya bisa dikerjakan setelah setup Firebase eksternal selesai.
>
> **Manual steps WAJIB lebih dulu:**
> 1. Buat Firebase project di [console.firebase.google.com](https://console.firebase.google.com)
> 2. Tambah Android app — package name ada di `android/app/build.gradle` (applicationId)
> 3. Download `google-services.json` → taruh di `android/app/`
> 4. Tambah iOS app → download `GoogleService-Info.plist` → taruh di `ios/Runner/`
> 5. Tambahkan ke `pubspec.yaml`:
>    ```yaml
>    firebase_core: ^3.0.0
>    firebase_messaging: ^15.0.0
>    ```
> 6. Jalankan `flutter pub get`
> 7. Jalankan SQL di Supabase: `ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;`

**Files (setelah setup selesai):**
- Modify: `lib/main.dart`
- Modify: `lib/features/auth/providers/auth_provider.dart`
- Modify: `supabase/functions/send-reminders/index.ts`

- [ ] **Step 1 (setelah setup): Inisialisasi Firebase di `main.dart`**

```dart
// Tambah import:
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Tambah background handler (top-level function, di luar main):
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notif sudah otomatis muncul dari OS
}

// Di dalam main():
await Firebase.initializeApp();
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
await FirebaseMessaging.instance.requestPermission();
```

- [ ] **Step 2: Simpan FCM token ke DB saat login di `auth_provider.dart`**

```dart
// Di signIn(), setelah sukses:
Future<void> _saveFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('profiles').update({'fcm_token': token}).eq('id', userId);
  } catch (_) {}
}
```

- [ ] **Step 3: Update Edge Function `send-reminders` untuk kirim FCM**

Tambahkan FCM HTTP v1 call setelah WA reminder:
```typescript
// Fetch fcm_token dari profile
// POST ke https://fcm.googleapis.com/v1/projects/{projectId}/messages:send
// Dengan Authorization: Bearer {service_account_token}
```

> Detail implementasi FCM HTTP v1 butuh service account key dari Firebase Console.

- [ ] **Step 4: Verifikasi** — build dan run di device fisik (emulator tidak support FCM)

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/features/auth/providers/auth_provider.dart \
  supabase/functions/send-reminders/
git commit -m "feat(fcm): initialize Firebase and save FCM token on login"
```

---

## Ringkasan Manual Steps untuk User

Setelah semua kode selesai, yang perlu dilakukan manual:

| # | Task | Aksi Manual |
|---|---|---|
| 1 | Email Konfirmasi | Supabase Dashboard → Authentication → Email → Enable "Confirm email" |
| DB | Migrations | Jalankan 2 file SQL di Supabase SQL Editor (marketplace_stock + notifications) |
| 12 | Notifikasi | Deploy edge function: `supabase functions deploy send-announcement-notifications` |
| 3 | FCM | Setup Firebase project + download config files + ALTER TABLE profiles ADD COLUMN fcm_token |

---

## Urutan Implementasi

1. ✅ Chunk 1: DB Migrations → Task 9 → Task 11 → Task 8
2. Chunk 2: Task 7 (Marketplace) → Task 6 (Filter)
3. Chunk 3: Task 10 (Registrasi) → Task 13 (Bantuan)
4. Chunk 4: Task 12 (Notifikasi) → Task 3 (FCM, jika Firebase sudah setup)
