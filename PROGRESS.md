# PROGRESS.md — Rukunin

Status pengerjaan berdasarkan roadmap di `roadmap.md`.
**Update file ini setiap kali menyelesaikan atau memulai sebuah task.**

---

## Status per Phase

| Phase | Nama | Status |
|---|---|---|
| Phase 0 | Setup & Fondasi | ✅ Selesai |
| Phase 1 | Core Admin | ✅ Selesai |
| Phase 2 | Payment & Otomasi WA | 🔄 Sebagian Selesai |
| Phase 3 | Laporan & AI | ✅ Selesai |
| Phase 4 | Warga App & Marketplace | 🔄 Sebagian Selesai |
| Phase 5 | Polish & Play Store | ⏳ Belum Dimulai |

---

## Phase 0 — Setup & Fondasi ✅

### Selesai / Eksisting
- [x] **0.1** Flutter SDK terinstall, emulator berjalan
- [x] **0.2** Project Flutter dibuat, Git repository aktif, di-push ke GitHub
- [x] **0.3** Semua dependencies terdaftar di `pubspec.yaml` dan berhasil di-install
- [x] **0.4** Struktur folder `lib/` rapi sesuai rencana
- [x] **0.5** Supabase project aktif, `.env` terkonfigurasi dengan URL & anon key
- [x] **0.6** Semua 9 tabel database dibuat via SQL migration (`supabase/migrations/20260311_initial_schema.sql`)
- [x] **0.7** RLS aktif di semua tabel (`supabase/migrations/20260311_rls_policies.sql`)
- [x] **0.8** Login screen berfungsi, redirect ke admin/resident berdasarkan `profiles.role`

### Sedang Dikerjakan
—

---

## Phase 1 — Core Admin ✅

### Selesai / Eksisting
- [x] **1.1** `admin_shell.dart` dengan 6-tab bottom nav (Beranda, Warga, Tagihan, Laporan, Surat, AI)
- [x] **1.1** `router.dart` dengan semua route admin terdaftar via GoRouter
- [x] **1.2** `admin_dashboard_screen.dart` — dashboard kas dengan data keuangan bulan ini
- [x] **1.3** `residents_screen.dart` — list warga dengan search bar dan filter status
- [x] **1.4** `add_edit_resident_screen.dart` — form tambah & edit warga lengkap dengan anggota keluarga
- [x] **1.5** Import CSV/Excel via `resident_provider.dart` (`importCsv()`)
- [x] **1.6** `resident_detail_screen.dart` — detail warga + riwayat tagihan 6 bulan terakhir
- [x] **1.7** `billing_types_screen.dart` + `add_edit_billing_type_screen.dart` — konfigurasi jenis iuran
- [x] **1.8** `create_invoice_screen.dart` — terbitkan tagihan massal ke warga
- [x] **1.9** `invoices_screen.dart` — list tagihan dengan filter status + tunggakan
- [x] **1.10** `expenses_screen.dart` + `add_expense_screen.dart` — catat pengeluaran kas dengan kategori
- [x] **Bonus** `community_settings_screen.dart` — pengaturan data komunitas + lokasi picker 4-level

### Sedang Dikerjakan
—

---

## Phase 2 — Payment & Otomasi WA 🔄

### Selesai / Eksisting
- [x] **2.1** `payment_settings_screen.dart` — pengaturan rekening bank + upload QRIS ke Supabase Storage
- [x] **2.3** Edge Function `send-whatsapp` dibuat dan di-deploy (`supabase/functions/send-whatsapp/`)
- [x] **2.5** Upload bukti bayar (`upload_proof_provider.dart`) — upload ke bucket `payment_proofs`, update status invoice ke `awaiting_verification`
- [x] **2.7** Edge Function `auto-generate-invoices` dibuat (`supabase/functions/auto-generate-invoices/`)
- [x] **2.7** Edge Function `send-reminders` dibuat (`supabase/functions/send-reminders/`)
- [x] **2.4** Tombol "Broadcast ke WA" di AppBar halaman tagihan admin (icon + dialog konfirmasi + progress hasil)
- [x] **2.6** Dialog verifikasi pembayaran admin: tampilkan gambar bukti bayar (full-screen zoomable), tombol "Konfirmasi Lunas" + "Tolak"
- [x] **2.6** `markInvoiceAsPaid` mencatat ke tabel `payments` + kirim WA konfirmasi ke warga otomatis
- [x] **Migration** `20260313_phase2_payment_verification.sql`: kolom `proof_url`/`updated_at` di invoices, fix status constraint, kolom rekening di communities, tarif kendaraan di billing_types, jumlah kendaraan di profiles, RLS policies baru

### Belum Selesai
- [ ] **2.2** Daftar akun Fonnte & verifikasi nomor WA (setup eksternal — bukan kode)
- [ ] **2.7** Setup pg_cron di Supabase untuk auto-run Edge Functions (konfigurasi Supabase eksternal — bukan kode)

### Sedang Dikerjakan
—

---

## Phase 3 — Laporan & AI ✅

### Selesai / Eksisting
- [x] **3.1** `reports_screen.dart` — laporan keuangan bulanan + grafik bar 6 bulan + period selector
- [x] **3.2** Export PDF laporan via `pdf_generator.dart` (PdfGenerator) + share via `share_plus`
- [x] **3.3** AI menggunakan **Groq API** (bukan Anthropic) — key disimpan di Supabase secrets sebagai `GROQ_API_KEY`
- [x] **3.4** Edge Function `ai-assistant` — fetch data keuangan, bangun context, panggil Groq `llama-3.3-70b-versatile`, log ke `ai_logs`
- [x] **3.5** `ai_assistant_screen.dart` — chat interface dengan AI, `AiState` (Notifier pattern)
- [x] **3.6** `letters_screen.dart` + `create_letter_screen.dart` — generate 8 jenis surat digital sebagai PDF
- [x] **3.6** `letter_pdf_generator.dart` — template 8 jenis surat (domisili, SKTM, SKCK, kematian, dll.)
- [x] **3.6** Edge Function `generate-letter` — generate nomor surat + isi konten

### Sedang Dikerjakan
—

---

## Phase 4 — Warga App & Marketplace 🔄

### Selesai / Eksisting
- [x] **4.1** `resident_shell.dart` — custom 5-tab bottom nav (Beranda, Info RT, Marketplace, Tagihan, Akun)
- [x] **4.1** Route warga terdaftar di `router.dart`, admin tidak bisa akses `/resident/*`
- [x] **4.2** `resident_home_screen.dart` — beranda warga dengan tagihan pending, quick menu
- [x] **4.3** `resident_invoices_screen.dart` — list tagihan warga + upload bukti bayar
- [x] **4.4** `marketplace_screen.dart` — feed listing grid + filter kategori
- [x] **4.5** `add_listing_screen.dart` — form tambah listing dengan upload foto
- [x] **4.6** `listing_detail_screen.dart` — detail listing + tombol WA ke penjual
- [x] **4.7** Sistem rating penjual — tabel `ratings`, `rating_provider.dart`, migrasi `20260312_add_marketplace_ratings.sql`
- [x] **4.8** `announcements_screen.dart` — list pengumuman (shared screen admin & resident)
- [x] **4.9** `create_announcement_screen.dart` + `announcement_provider.dart` — buat & hapus pengumuman
- [x] **Bonus** `resident_profile_screen.dart` — profil akun warga
- [x] **Bonus** `admin_profile_screen.dart` — profil akun admin

- [x] **4.9** Toggle "Kirim WA ke semua warga" di form buat pengumuman + `broadcastWa()` di `CreateAnnouncementService`
- [x] **4.10** `resident_kas_screen.dart` + `resident_kas_provider.dart` — transparansi kas (pemasukan, pengeluaran, saldo, 10 pengeluaran terbaru), route `/resident/kas`, card navigasi di resident home screen

### Belum Selesai (external dependency — bukan kode)
- [ ] **4.3** Payment via Midtrans WebView — manual transfer sudah dipilih sebagai metode pembayaran; Midtrans butuh merchant account & API key eksternal
- [ ] **4.8** Push notification FCM — butuh Firebase project, google-services.json (external setup, ada di Phase 5)

### Sedang Dikerjakan
—

---

## Phase 5 — Polish & Play Store ⏳

### Selesai / Eksisting
—

### Belum Dimulai
- [ ] **5.1** UAT dengan Pak RT & warga nyata
- [ ] **5.2** Polish UI: loading shimmer, empty states, error handling konsisten
- [ ] **5.3** Setup Firebase + FCM push notification
- [ ] **5.4** Siapkan aset Play Store (icon, screenshot, deskripsi, privacy policy)
- [ ] **5.5** Build release + keystore signing
- [ ] **5.6** Publish ke Google Play Store

### Sedang Dikerjakan
—

---

## Refactor: Self-Service Onboarding ✅

> Di luar phase roadmap — keputusan arsitektural penting untuk model SaaS.

### Selesai
- [x] **DB Migration** `20260314_self_service_onboarding.sql`: kolom `community_code` di communities (unique, 6-char), kolom `email` di profiles, status constraint + 'pending', RLS policies baru (community lookup by code, self-insert profile)
- [x] **`register_provider.dart`** — `RegisterService` dengan `registerAdmin()` (buat community + generate kode) dan `registerResident()` (lookup by code, insert profile status=pending)
- [x] **`register_admin_screen.dart`** — form daftar admin RT/RW, setelah sukses tampilkan dialog community_code dengan tombol salin
- [x] **`register_resident_screen.dart`** — form gabung komunitas dengan kode, NIK & nomor unit opsional
- [x] **`pending_approval_screen.dart`** — halaman menunggu persetujuan dengan tombol "Cek Status & Masuk" (re-fetch profil, auto-redirect jika sudah active)
- [x] **`login_screen.dart`** — ganti teks "Hubungi admin" dengan 2 tombol: "Daftar sbg Admin RT/RW" dan "Gabung sbg Warga"
- [x] **`router.dart`** — rute baru `/register/admin`, `/register/resident`, `/pending-approval`; redirect logic diperbarui (pending user dikunci ke /pending-approval)
- [x] **`resident_provider.dart`** — `residentsProvider` sekarang filter `status != 'pending'`; `pendingResidentsProvider` untuk warga pending; method `approveResident()` dan `rejectResident()` di `ResidentNotifier`
- [x] **`residents_screen.dart`** — banner kuning menampilkan jumlah pending warga, bottom sheet daftar pending dengan tombol "Setujui" / "Tolak" per warga

---

## Catatan Penting

- **Nama project di roadmap** masih tertulis "WargaOS" — di codebase sudah diganti menjadi **Rukunin**
- **AI Provider:** Roadmap menyebut Anthropic/Claude Haiku, tapi implementasi menggunakan **Groq** (`llama-3.3-70b-versatile`) — ini keputusan sadar
- **Invoice status tambahan:** Di luar yang dirancang di roadmap, sudah ada status `awaiting_verification` untuk alur upload bukti bayar manual
- **Tab admin:** Roadmap rencana 5 tab, implementasi sudah 6 tab (tambahan: Surat)
- **Kolom bonus billing_type:** Ada `costPerMotorcycle` dan `costPerCar` untuk iuran berbasis kendaraan
- **Onboarding SaaS:** Admin daftar mandiri → dapat kode komunitas → bagikan ke WA grup → warga daftar sendiri → admin approve via UI; tidak perlu input warga satu per satu

---

*Last updated: Self-service onboarding selesai — siap masuk Phase 5 (Polish & Play Store)*
