# ARCHITECTURE.md — Rukunin

Dokumen ini adalah referensi arsitektur teknis project Rukunin. Dibuat berdasarkan analisis menyeluruh codebase. **Baca sebelum mengerjakan task apapun.**

---

## Stack Teknologi

| Layer | Teknologi |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod (`flutter_riverpod ^3`) |
| Navigation | GoRouter (`go_router`) |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| AI | Groq API (`llama-3.3-70b-versatile`) via Edge Function |
| PDF | `pdf` + `printing` packages |
| Fonts | Playfair Display (headline) + Plus Jakarta Sans (body) |

---

## Struktur Folder

```
lib/
├── main.dart                    ← Init Supabase, dotenv, Riverpod ProviderScope
├── app/
│   ├── router.dart              ← SEMUA route + auth redirect logic
│   └── theme.dart               ← Design tokens (AppColors, AppTextStyles, buildAppTheme)
├── core/
│   ├── supabase/
│   │   └── supabase_client.dart ← supabaseClientProvider (entry point tunggal)
│   ├── services/
│   │   └── location_service.dart ← API wilayah Indonesia (provinsi/kabupaten/kecamatan/kelurahan)
│   └── utils/
│       ├── currency_formatter.dart   ← formatRupiah() — locale id_ID
│       ├── pdf_generator.dart        ← PdfGenerator (laporan keuangan)
│       └── letter_pdf_generator.dart ← LetterPdfGenerator (8 jenis surat)
├── shell/
│   ├── admin_shell.dart         ← Bottom nav admin (6 tab)
│   └── resident_shell.dart      ← Bottom nav warga (5 tab, custom widget)
└── features/
    ├── auth/
    ├── dashboard/
    ├── residents/
    ├── invoices/
    ├── expenses/
    ├── reports/
    ├── letters/
    ├── announcements/
    ├── marketplace/
    ├── ai_assistant/
    ├── community/
    ├── settings/
    ├── resident_portal/
    └── payments/
```

Setiap feature folder mengikuti pola: `models/` → `providers/` → `screens/`

---

## Pola State Management

### Aturan Utama
- **Semua akses Supabase** wajib melalui `supabaseClientProvider` dari `lib/core/supabase/supabase_client.dart`
- Jangan pernah panggil `Supabase.instance.client` langsung di dalam screen

### Pola Provider yang Dipakai

| Pola | Kapan Dipakai | Contoh |
|---|---|---|
| `Provider` | Dependency injection sederhana | `supabaseClientProvider`, `locationServiceProvider` |
| `FutureProvider.autoDispose` | Fetch data sekali, auto cleanup | `residentsProvider`, `announcementsProvider` |
| `FutureProvider.autoDispose.family` | Fetch data dengan parameter | `kabupatenProvider(provinsiId)`, `residentInvoicesProvider(id)` |
| `StreamProvider` | Listen perubahan real-time | `authStateProvider` |
| `AsyncNotifier` | Operasi async dengan mutations | `ResidentNotifier`, `PaymentSettingsNotifier` |
| `Notifier` | State kompleks + imperatif | `ReportNotifier`, `AiAssistantNotifier` |

### Pola Invalidasi
Setelah mutasi (add/update/delete), provider data di-refresh dengan:
```dart
ref.invalidate(residentsProvider);
```

---

## Navigasi & Routing

### Auth Redirect Flow
```
Buka app
    ↓
router redirect: cek currentSession
    ├── Belum login → /login
    └── Sudah login → query profiles.role
            ├── role = 'admin'    → /admin
            └── role = 'resident' → /resident
```

### Route Structure

**Admin (ShellRoute → AdminShell)**
```
/admin               Dashboard
/admin/warga         List Warga + detail
/admin/tagihan       List Tagihan
/admin/tagihan/buat  Form Terbitkan Tagihan
/admin/pengeluaran   List Pengeluaran
/admin/laporan       Laporan + PDF export
/admin/ai            AI Assistant (chat)
/admin/surat         List Surat
/admin/surat/buat    Form Buat Surat
/admin/pengumuman    List Pengumuman
/admin/pengumuman/buat  Form Buat Pengumuman
/admin/pengaturan    Pengaturan Komunitas (lokasi RW)
/admin/pengaturan-rek   Pengaturan Rekening/QRIS
/admin/pengaturan-iuran Konfigurasi Jenis Iuran
/admin/profil        Profil Admin  ← di LUAR ShellRoute
```

**Resident (ShellRoute → ResidentShell)**
```
/resident              Beranda Warga
/resident/tagihan      Tagihan + Upload Bukti
/resident/akun         Profil Warga
/resident/pengumuman   Pengumuman (shared screen)
/resident/marketplace  Marketplace Feed
/resident/marketplace/tambah   Form Tambah Listing  ← di LUAR ShellRoute
/resident/marketplace/detail   Detail Listing        ← di LUAR ShellRoute
```

> **Catatan:** Route yang dipush sebagai full-screen (tanpa bottom nav) dideklarasikan sebagai top-level `GoRoute` di luar kedua `ShellRoute`.

---

## Database Schema

### Tabel Utama

| Tabel | Fungsi | Key Columns |
|---|---|---|
| `communities` | Satu row per RW | `rw_number`, `bank_name`, `qris_url`, `rt_count` |
| `profiles` | Semua user | `role` (admin/resident), `community_id`, `nik`, `unit_number` |
| `family_members` | Anggota keluarga warga | `resident_id`, `full_name`, `relationship` |
| `billing_types` | Jenis iuran | `name`, `amount`, `billing_day`, `is_active`, `costPerMotorcycle`, `costPerCar` |
| `invoices` | Tagihan per warga per bulan | `status` (pending/paid/overdue/awaiting_verification), `month`, `year` |
| `payments` | Riwayat pembayaran | `invoice_id`, `amount`, `method` |
| `expenses` | Pengeluaran kas | `category`, `amount`, `expense_date` |
| `letters` | Surat digital | `letter_type`, `letter_number`, `resident_id` |
| `announcements` | Pengumuman | `type` (info/penting/urgent) |
| `marketplace_listings` | Listing jual-beli | `seller_id`, `category`, `status` (available/sold/inactive) |
| `ratings` | Rating penjual marketplace | `listing_id`, `seller_id`, `score` (1–5) |
| `ai_logs` | Log AI assistant | `question`, `answer`, `month`, `year` |

### Storage Buckets
- `payment_proofs` — bukti transfer dari warga
- `community_assets` — logo komunitas, QRIS image
- `letters` — file PDF surat digital

### RLS
Policy ada di `supabase/migrations/20260311_rls_policies.sql`. Prinsip utama:
- Admin bisa akses semua data di `community_id`-nya
- Resident hanya bisa akses data miliknya sendiri

---

## Supabase Edge Functions

Semua function ada di `supabase/functions/`. Runtime: **Deno**.

| Function | Trigger | Yang Dilakukan |
|---|---|---|
| `ai-assistant` | Dipanggil dari app | Ambil data keuangan → format context → panggil Groq API → log ke `ai_logs` |
| `generate-letter` | Dipanggil dari app | Generate nomor surat + isi konten → simpan ke tabel `letters` |
| `send-whatsapp` | Dipanggil dari function lain | POST ke Fonnte API untuk kirim WA |
| `auto-generate-invoices` | pg_cron tiap tgl 1 | Buat invoice baru untuk semua warga aktif |
| `send-reminders` | pg_cron tiap pagi | Kirim WA reminder untuk invoice overdue |

### Secrets yang dibutuhkan di Supabase
- `GROQ_API_KEY` — untuk ai-assistant
- Fonnte API key — untuk send-whatsapp

---

## Design System

File: `lib/app/theme.dart`

### Warna (`AppColors`)
```
primary     = #FFC107  (kuning emas — elemen aktif, aksen)
onPrimary   = #0D0D0D  (teks di atas kuning)
surface     = #0D0D0D  (hitam — bottom nav, dark card)
background  = #F5F5F5  (abu terang — scaffold background)
success     = #10B981
error       = #FF6B6B
warning     = #F59E0B
```

### Tipografi (`AppTextStyles`)
- `AppTextStyles.display(size)` — Playfair Display, bold 900, untuk headline
- `AppTextStyles.body(size)` — Plus Jakarta Sans, untuk body text
- `AppTextStyles.label(size)` — Plus Jakarta Sans SemiBold, untuk label

### Komponen Default (dari `buildAppTheme()`)
- **Button:** hitam, full-width, height 52, border radius 100 (pill)
- **Input:** fill abu, border radius 12, focus border kuning
- **Card:** putih, border radius 16, elevation 0

---

## Model Pattern

Model menggunakan **plain Dart class** (bukan Freezed), dengan:
- Constructor dengan `required` dan optional fields
- Factory constructor `fromMap()` atau `fromJson()` untuk deserialisasi dari Supabase
- Method `toMap()` untuk serialisasi ke Supabase
- Computed getter untuk logika tampilan (misal: `alamatLengkap`, `initials`, `formattedPrice`)

Contoh pattern:
```dart
class ResidentModel {
  final String id;
  // ...fields

  const ResidentModel({required this.id, ...});

  factory ResidentModel.fromMap(Map<String, dynamic> map) { ... }

  String get initials { ... }  // computed getter
}
```

---

## Fitur Khusus

### Upload Bukti Bayar (Resident)
Flow: `upload_proof_provider.dart`
1. Upload gambar ke bucket `payment_proofs`
2. Ambil public URL
3. Update `invoices.status` → `awaiting_verification` + simpan `proof_url`
4. Invalidate `residentInvoicesProvider`

### AI Assistant
- Chat interface di `AiAssistantScreen`
- State: list `ChatMessage` di `AiState` (Notifier pattern)
- Panggil Edge Function `ai-assistant` dengan `question`, `community_id`, `month`, `year`
- AI menggunakan Groq (`llama-3.3-70b-versatile`), bukan Anthropic/Claude

### Surat Digital (8 Jenis)
Template di `LetterPdfGenerator`:
`ktp_kk`, `domisili`, `sktm`, `skck`, `kematian`, `nikah`, `sku`, `custom`

### Location Picker (Komunitas)
Menggunakan API publik `emsifa.com`:
- 4 level: Provinsi → Kabupaten → Kecamatan → Kelurahan
- FutureProvider.family untuk tiap level
