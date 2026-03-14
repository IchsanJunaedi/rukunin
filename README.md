# Rukunin

**Aplikasi manajemen RT/RW digital berbasis Flutter + Supabase.**

Rukunin membantu pengurus RT/RW mengelola warga, tagihan iuran, kas, laporan keuangan, dan surat digital — semuanya dalam satu aplikasi. Warga juga mendapat portal sendiri untuk cek tagihan, upload bukti bayar, dan berinteraksi lewat marketplace & pengumuman.

---

## Fitur Utama

### Admin (Pengurus RT/RW)
| Fitur | Deskripsi |
|---|---|
| **Dashboard** | Ringkasan kas, tagihan lunas/belum, kode komunitas |
| **Manajemen Warga** | Tambah, edit, detail warga + anggota keluarga |
| **Tagihan & Iuran** | Terbitkan tagihan bulanan massal, verifikasi bukti bayar |
| **Pengeluaran** | Catat & kategorikan pengeluaran kas |
| **Laporan** | Laporan keuangan bulanan/tahunan, export PDF & Excel |
| **Surat Digital** | Buat 8 jenis surat (domisili, SKTM, SKCK, dll) + PDF |
| **Pengumuman** | Buat & hapus pengumuman (info / penting / urgent) |
| **AI Assistant** | Tanya jawab keuangan komunitas via Groq LLM |
| **Pengaturan** | Profil komunitas, rekening/QRIS, konfigurasi jenis iuran |

### Warga (Resident)
| Fitur | Deskripsi |
|---|---|
| **Beranda** | Ringkasan tagihan, pengumuman terbaru |
| **Tagihan** | Lihat status tagihan, upload bukti bayar |
| **Kas RT** | Transparansi saldo & riwayat transaksi kas |
| **Marketplace** | Jual-beli barang/jasa antar warga |
| **Pengumuman** | Baca pengumuman dari pengurus RT |

---

## Tech Stack

| Layer | Teknologi |
|---|---|
| Framework | Flutter (Dart SDK ^3.11) |
| State Management | Riverpod 3.x (`flutter_riverpod`) |
| Navigation | GoRouter |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| Edge Functions | Deno (TypeScript) |
| AI | Groq API — `llama-3.3-70b-versatile` |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| PDF | `pdf` + `printing` |

---

## Prasyarat

Sebelum mulai, pastikan sudah terinstall:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.11)
- [Dart SDK](https://dart.dev/get-dart) (>= 3.11, biasanya sudah bundled dengan Flutter)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (opsional, untuk deploy edge functions)
- Android Studio / Xcode (untuk emulator/device)
- Akun [Supabase](https://supabase.com) (untuk backend)
- Akun [Groq](https://console.groq.com) (untuk AI assistant)

---

## Clone & Setup

### 1. Clone repository

```bash
git clone https://github.com/your-username/rukunin.git
cd rukunin
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Buat file `.env`

Buat file `.env` di root project (sejajar dengan `pubspec.yaml`):

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

> Nilai `SUPABASE_URL` dan `SUPABASE_ANON_KEY` bisa ditemukan di Supabase Dashboard → Project Settings → API.

### 4. Setup database Supabase

Jalankan semua migration SQL di Supabase SQL Editor **secara berurutan**:

```
supabase/migrations/20260311_initial_schema.sql
supabase/migrations/20260311_rls_policies.sql
supabase/migrations/20260311_add_location_fields.sql
supabase/migrations/20260312_family_members.sql
supabase/migrations/20260312_add_announcement_and_marketplace.sql
supabase/migrations/20260312_add_marketplace_ratings.sql
supabase/migrations/20260313_create_storage_buckets.sql
supabase/migrations/20260313_phase2_payment_verification.sql
supabase/migrations/20260314_create_payment_proofs_bucket.sql
supabase/migrations/20260314_self_service_onboarding.sql
```

### 5. Setup Firebase (Push Notifications)

1. Buat project di [Firebase Console](https://console.firebase.google.com)
2. Tambahkan Android app dengan package name `com.rukunin.app`
3. Download `google-services.json` → letakkan di `android/app/google-services.json`
4. Untuk iOS: download `GoogleService-Info.plist` → letakkan di `ios/Runner/`

> `google-services.json` **tidak dicommit** ke repo karena mengandung credentials. Buat sendiri dari Firebase Console.

### 6. Deploy Edge Functions (opsional)

```bash
# Login ke Supabase CLI
supabase login

# Link ke project
supabase link --project-ref your-project-ref

# Set secrets
supabase secrets set GROQ_API_KEY=your-groq-api-key

# Deploy semua functions
supabase functions deploy ai-assistant
supabase functions deploy generate-letter
supabase functions deploy auto-generate-invoices
supabase functions deploy send-reminders
supabase functions deploy send-whatsapp
```

### 7. Jalankan aplikasi

```bash
# Lihat device yang tersedia
flutter devices

# Jalankan di device tertentu
flutter run -d <device-id>

# Atau langsung (pilih device interaktif)
flutter run
```

---

## Struktur Folder

```
lib/
├── main.dart                    # Entry point — init Supabase, dotenv, Riverpod
├── app/
│   ├── router.dart              # Semua route + auth redirect
│   └── theme.dart               # Design tokens (AppColors, AppTextStyles)
├── core/
│   ├── supabase/
│   │   └── supabase_client.dart # supabaseClientProvider — entry point tunggal
│   ├── services/
│   │   └── location_service.dart
│   └── utils/
│       ├── currency_formatter.dart
│       ├── pdf_generator.dart
│       └── letter_pdf_generator.dart
├── shell/
│   ├── admin_shell.dart         # Bottom nav admin — 6 tab, glass navbar
│   └── resident_shell.dart      # Bottom nav warga — 5 tab
└── features/
    ├── auth/                    # Login, register, pending approval
    ├── dashboard/               # Admin dashboard
    ├── residents/               # Manajemen warga
    ├── invoices/                # Tagihan & billing types
    ├── expenses/                # Pengeluaran kas
    ├── reports/                 # Laporan keuangan
    ├── letters/                 # Surat digital
    ├── announcements/           # Pengumuman
    ├── marketplace/             # Jual-beli warga
    ├── ai_assistant/            # Chat AI
    ├── community/               # Pengaturan komunitas
    ├── settings/                # Profil admin, rekening
    └── resident_portal/         # Portal khusus warga

supabase/
├── migrations/                  # SQL schema & RLS policies
└── functions/                   # Deno Edge Functions
```

---

## Commands Berguna

```bash
# Build APK release
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Code generation (Riverpod generators)
dart run build_runner build --delete-conflicting-outputs

# Lint
flutter analyze

# Test
flutter test
```

---

## Desain

- **Primary:** `#FFC107` (kuning emas)
- **Surface:** `#0D0D0D` (hitam)
- **Font headline:** Playfair Display
- **Font body:** Plus Jakarta Sans

---

## Kontribusi

1. Fork repository ini
2. Buat branch baru: `git checkout -b feat/nama-fitur`
3. Commit perubahan
4. Buat Pull Request

---

## Lisensi

MIT License — lihat file `LICENSE` untuk detail.
