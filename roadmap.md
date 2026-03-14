# WargaOS — Development Roadmap
## Phase 0 → Production

> **Stack:** Flutter + Supabase + Supabase Edge Functions  
> **Target:** 300 unit, 1 RW, 1 developer  
> **Budget:** ~Rp 116.000/bulan  
> **Timeline:** 12 minggu aktif + post-launch  

---

## Overview Semua Phase

| Phase | Nama | Minggu | Output Utama |
|-------|------|--------|--------------|
| Phase 0 | Setup & Fondasi | 1–2 | Project jalan, auth berfungsi |
| Phase 1 | Core Admin | 3–5 | Pak RT bisa kelola warga & tagihan |
| Phase 2 | Payment & Otomasi | 6–7 | Warga bisa bayar, sistem otomatis |
| Phase 3 | Laporan & AI | 8–9 | Laporan PDF & AI assistant aktif |
| Phase 4 | Warga App & Marketplace | 10–11 | Warga punya akses penuh |
| Phase 5 | Polish & Play Store | 12 | App live di Play Store |
| Production | Post-Launch | Bulan 4–5 | Stabil, monitoring, ekspansi |

---

## Phase 0 — Setup & Fondasi
> **Minggu 1–2**  
> **Tujuan:** Semua tools siap, project bisa jalan di emulator, login sudah berfungsi. Jangan mulai fitur apapun sebelum phase ini selesai 100%.

---

### 0.1 — Install & Konfigurasi Flutter

**Apa yang dikerjakan:**  
Pasang semua tools yang dibutuhkan untuk development Flutter di laptop kamu.

**Detail task:**
- [ ] Download & install Flutter SDK dari flutter.dev
- [ ] Tambahkan path Flutter ke environment variable sistem
- [ ] Install Android Studio (untuk emulator & Android SDK)
- [ ] Install plugin Flutter & Dart di Android Studio
- [ ] Install VS Code sebagai editor utama
- [ ] Install ekstensi Flutter, Dart, dan Pubspec Assist di VS Code
- [ ] Jalankan `flutter doctor` di terminal — semua item harus centang hijau
- [ ] Buat emulator Android di Android Studio (minimal Android 10 / API 29)
- [ ] Pastikan emulator bisa jalan dengan lancar

**Selesai jika:** `flutter doctor` menampilkan semua centang hijau, emulator bisa dibuka.

---

### 0.2 — Buat Project Flutter

**Apa yang dikerjakan:**  
Inisiasi project Flutter baru dengan nama dan konfigurasi yang benar dari awal.

**Detail task:**
- [ ] Buat project baru: `flutter create wargaos`
- [ ] Buka project di VS Code
- [ ] Jalankan `flutter run` — pastikan app default Flutter bisa jalan di emulator
- [ ] Ganti nama app di `pubspec.yaml` jadi "WargaOS"
- [ ] Ganti app ID (bundle ID) di `android/app/build.gradle` jadi `com.wargaos.app`
- [ ] Init Git repository: `git init`
- [ ] Buat file `.gitignore` yang benar (Flutter sudah ada default-nya)
- [ ] Commit pertama: "Initial Flutter project"
- [ ] Buat repository di GitHub & push

**Selesai jika:** Project Flutter kosong bisa dijalankan di emulator tanpa error.

---

### 0.3 — Tambah Semua Dependencies

**Apa yang dikerjakan:**  
Daftarkan semua package Flutter yang akan dipakai ke `pubspec.yaml` sekaligus sebelum mulai coding, supaya tidak perlu tambah-tambah lagi nanti.

**Package yang ditambahkan:**

| Kategori | Package |
|----------|---------|
| Backend | supabase_flutter |
| State management | flutter_riverpod, riverpod_annotation |
| Navigasi | go_router |
| HTTP request | dio |
| Local storage | shared_preferences, flutter_secure_storage |
| Environment | flutter_dotenv |
| Push notif | firebase_core, firebase_messaging, flutter_local_notifications |
| Chart | fl_chart |
| Gambar | image_picker, cached_network_image |
| PDF | pdf, flutter_pdfview |
| Payment | webview_flutter |
| QR Code | qr_flutter, mobile_scanner |
| Format angka | intl |
| Model | freezed_annotation, json_annotation |
| File | csv, excel, share_plus |
| UI | shimmer, table_calendar |
| Dev tools | build_runner, freezed, json_serializable, riverpod_generator |

**Detail task:**
- [ ] Tambahkan semua package di atas ke `pubspec.yaml`
- [ ] Jalankan `flutter pub get` — pastikan tidak ada error
- [ ] Pastikan tidak ada package yang konflik versi

**Selesai jika:** `flutter pub get` sukses tanpa error, project masih bisa dijalankan.

---

### 0.4 — Setup Struktur Folder

**Apa yang dikerjakan:**  
Buat struktur folder yang rapi dari awal sebelum mulai nulis kode apapun. Ini penting agar project tidak berantakan di tengah jalan.

**Struktur yang dibuat:**
```
lib/
├── main.dart
├── app/
│   ├── router.dart          ← semua route navigasi
│   └── theme.dart           ← warna & style global
├── core/
│   ├── supabase/            ← konfigurasi Supabase client
│   ├── models/              ← semua model data (Resident, Invoice, dll)
│   ├── widgets/             ← widget UI yang dipakai di banyak tempat
│   └── utils/               ← helper (format rupiah, format tanggal)
├── features/
│   ├── auth/                ← login & register
│   ├── dashboard/           ← dashboard admin & beranda warga
│   ├── residents/           ← manajemen warga
│   ├── invoices/            ← tagihan & tunggakan
│   ├── payments/            ← riwayat pembayaran
│   ├── expenses/            ← pengeluaran kas
│   ├── reports/             ← laporan keuangan
│   ├── announcements/       ← pengumuman
│   ├── marketplace/         ← jual beli warga
│   └── ai_assistant/        ← fitur AI
└── shell/
    ├── admin_shell.dart     ← bottom nav admin
    └── resident_shell.dart  ← bottom nav warga
```

**Detail task:**
- [ ] Buat semua folder sesuai struktur di atas
- [ ] Buat file `.dart` kosong sebagai placeholder di tiap folder
- [ ] Pastikan tidak ada file yang masih di root `lib/` selain `main.dart`

**Selesai jika:** Struktur folder sudah terbuat rapi, tidak ada file berantakan.

---

### 0.5 — Setup Supabase

**Apa yang dikerjakan:**  
Buat project Supabase yang akan menjadi backend utama WargaOS.

**Detail task:**
- [ ] Daftar akun di supabase.com (gratis, pakai email kampus/pribadi)
- [ ] Buat project baru di Supabase dashboard
  - Nama project: `wargaos`
  - Database password: buat yang kuat, simpan di password manager
  - Region: pilih Singapore (paling dekat ke Indonesia)
- [ ] Tunggu project selesai dibuat (~2 menit)
- [ ] Buka Settings → API
- [ ] Salin `Project URL` dan `anon public key`
- [ ] Buat file `.env` di root project Flutter
- [ ] Isi `.env` dengan URL & anon key tadi
- [ ] Pastikan `.env` sudah masuk ke `.gitignore`
- [ ] Konfirmasi dengan `git status` — file `.env` tidak boleh muncul sebagai untracked

**Selesai jika:** File `.env` ada, berisi URL & key Supabase, dan tidak ter-track oleh Git.

---

### 0.6 — Buat Database Schema

**Apa yang dikerjakan:**  
Buat semua tabel database di Supabase yang akan dipakai sepanjang project. Lakukan ini sekali di awal, lebih baik dari pada tambah tabel satu-satu nanti.

**Tabel yang dibuat:**

| Tabel | Fungsi |
|-------|--------|
| `communities` | Data RW (satu RW = satu row) |
| `profiles` | Semua user: admin RT dan warga |
| `billing_types` | Jenis iuran (IPL, keamanan, kebersihan, dll.) |
| `invoices` | Tagihan per warga per bulan |
| `payments` | Rekam setiap pembayaran yang berhasil |
| `expenses` | Pengeluaran kas lingkungan |
| `announcements` | Pengumuman dari admin ke warga |
| `marketplace_listings` | Listing jual beli antar warga |
| `ai_logs` | Log semua interaksi dengan AI — ini data skripsi kamu! |

**Detail task:**
- [ ] Buka Supabase dashboard → SQL Editor
- [ ] Buat tabel `communities` dengan kolom: id, name, address, rw_number, admin_phone, subscription_tier, unit_limit, created_at
- [ ] Buat tabel `profiles` dengan kolom: id (referensi ke auth.users), community_id, full_name, phone, nik, unit_number, role, status, photo_url
- [ ] Buat tabel `billing_types` dengan kolom: id, community_id, name, amount, billing_day, is_active
- [ ] Buat tabel `invoices` dengan kolom: id, community_id, resident_id, billing_type_id, amount, month, year, due_date, status, payment_link, payment_token
- [ ] Buat tabel `payments` dengan kolom: id, invoice_id, community_id, amount, method, gateway_ref, paid_at
- [ ] Buat tabel `expenses` dengan kolom: id, community_id, amount, category, description, receipt_url, expense_date, created_by
- [ ] Buat tabel `announcements` dengan kolom: id, community_id, title, body, type, wa_broadcast_sent, created_by
- [ ] Buat tabel `marketplace_listings` dengan kolom: id, community_id, seller_id, title, description, price, category, images, status
- [ ] Buat tabel `ai_logs` dengan kolom: id, community_id, user_id, query_type, prompt_summary, response_summary, tokens_used, response_time_ms, created_at
- [ ] Buat index untuk kolom yang sering di-query (community_id di semua tabel, status di invoices, month+year di invoices)

**Selesai jika:** Semua 9 tabel sudah terbuat dan terlihat di Supabase Table Editor.

---

### 0.7 — Aktifkan Row Level Security (RLS)

**Apa yang dikerjakan:**  
Aktifkan keamanan data di level database. Ini memastikan data antar RW tidak bisa saling bocor, dan warga hanya bisa lihat data miliknya sendiri.

**Detail task:**
- [ ] Aktifkan RLS di tabel `profiles`
- [ ] Aktifkan RLS di tabel `invoices`
- [ ] Aktifkan RLS di tabel `payments`
- [ ] Aktifkan RLS di tabel `expenses`
- [ ] Aktifkan RLS di tabel `announcements`
- [ ] Aktifkan RLS di tabel `marketplace_listings`
- [ ] Aktifkan RLS di tabel `ai_logs`
- [ ] Buat policy: admin bisa akses semua data di community-nya
- [ ] Buat policy: warga hanya bisa lihat invoice miliknya sendiri
- [ ] Buat policy: warga bisa lihat semua listing marketplace di community-nya
- [ ] Test policy dengan login sebagai admin → pastikan data terbaca
- [ ] Test policy dengan login sebagai warga → pastikan hanya data sendiri yang muncul

**Selesai jika:** RLS aktif di semua tabel, policy berjalan sesuai yang diharapkan.

---

### 0.8 — Hubungkan Flutter ke Supabase & Buat Login Screen

**Apa yang dikerjakan:**  
Hubungkan app Flutter ke Supabase, lalu buat halaman login yang benar-benar berfungsi.

**Detail task:**
- [ ] Inisialisasi Supabase di `main.dart` menggunakan URL & key dari `.env`
- [ ] Wrap seluruh app dengan `ProviderScope` (untuk Riverpod)
- [ ] Buat `login_screen.dart` di `features/auth/screens/`
- [ ] Tambahkan field input email dan password
- [ ] Tambahkan tombol "Masuk"
- [ ] Hubungkan tombol ke `supabase.auth.signInWithPassword()`
- [ ] Setelah login berhasil, ambil data role dari tabel `profiles`
- [ ] Jika role = `admin` → arahkan ke halaman admin dashboard
- [ ] Jika role = `resident` → arahkan ke halaman warga
- [ ] Tampilkan pesan error jika login gagal (salah password, dll.)
- [ ] Buat akun admin pertama manual via Supabase dashboard Authentication
- [ ] Insert row di tabel `profiles` untuk admin tersebut dengan role = `admin`
- [ ] Test login dengan akun admin tadi → pastikan berhasil masuk

**Selesai jika:** Admin bisa login, diarahkan ke halaman yang benar, warga juga bisa login dan diarahkan ke halaman yang berbeda.

---

### ✅ Checklist Akhir Phase 0

```
[ ] flutter doctor — semua hijau
[ ] Emulator Android bisa jalan
[ ] flutter pub get — tidak ada error
[ ] Struktur folder sudah rapi
[ ] .env ada & tidak ter-track Git
[ ] Semua 9 tabel database sudah terbuat
[ ] RLS aktif di semua tabel
[ ] Login admin berfungsi & redirect ke halaman benar
[ ] Login warga berfungsi & redirect ke halaman berbeda
```

---

## Phase 1 — Core Admin
> **Minggu 3–5**  
> **Tujuan:** Pak RT bisa melakukan semua pekerjaan administrasi utamanya secara digital — mulai dari input warga, buat tagihan, catat pengeluaran, hingga lihat kondisi kas.

---

### 1.1 — Setup Navigasi Admin

**Apa yang dikerjakan:**  
Buat kerangka navigasi untuk halaman-halaman admin. Ini fondasi sebelum buat halaman apapun.

**Detail task:**
- [ ] Buat `admin_shell.dart` di folder `shell/`
- [ ] Pasang Bottom Navigation Bar dengan 5 tab: Dashboard, Warga, Tagihan, Laporan, AI
- [ ] Buat `router.dart` di folder `app/`
- [ ] Daftarkan semua route admin menggunakan `go_router`
- [ ] Buat halaman placeholder kosong untuk masing-masing tab (bisa cuma tulisan nama halaman dulu)
- [ ] Pastikan navigasi antar tab berjalan tanpa error
- [ ] Pastikan tombol back di Android tidak keluar dari app saat di halaman utama

**Selesai jika:** 5 tab di bottom nav bisa diklik dan berpindah halaman tanpa error.

---

### 1.2 — Halaman Dashboard Kas

**Apa yang dikerjakan:**  
Buat halaman pertama yang dilihat admin setelah login — ringkasan kondisi keuangan bulan ini.

**Detail task:**
- [ ] Buat `admin_dashboard_screen.dart` di `features/dashboard/screens/`
- [ ] Buat provider Riverpod untuk fetch data dashboard dari Supabase
- [ ] Tampilkan 4 kartu ringkasan:
  - Total tagihan bulan ini (Rp)
  - Total terkumpul (Rp)
  - Jumlah unit sudah bayar
  - Jumlah unit belum bayar
- [ ] Tampilkan grafik pie pembayaran menggunakan package `fl_chart`
- [ ] Format semua angka uang dalam format Rupiah (Rp 150.000 bukan 150000)
- [ ] Tampilkan nama bulan & tahun di bagian atas (contoh: "Maret 2026")
- [ ] Tambahkan loading indicator saat data sedang diambil
- [ ] Tambahkan pesan error jika gagal fetch data
- [ ] Dashboard terupdate otomatis saat ada pembayaran masuk (Supabase Realtime)

**Selesai jika:** Dashboard menampilkan data keuangan bulan ini yang akurat dengan grafik.

---

### 1.3 — Halaman List Warga

**Apa yang dikerjakan:**  
Buat halaman untuk melihat semua warga yang terdaftar di RW.

**Detail task:**
- [ ] Buat `residents_screen.dart` di `features/residents/screens/`
- [ ] Buat provider untuk fetch semua warga dari tabel `profiles`
- [ ] Tampilkan list warga dalam bentuk card (nama, nomor unit, nomor HP, status)
- [ ] Tambahkan badge warna untuk status: hijau = aktif, merah = tidak aktif
- [ ] Tambahkan search bar untuk cari warga berdasarkan nama atau nomor unit
- [ ] Tambahkan filter berdasarkan status (semua / aktif / tidak aktif)
- [ ] Tambahkan loading shimmer saat data sedang diambil
- [ ] Tampilkan jumlah total warga di bagian atas
- [ ] Tambahkan tombol "+" (FAB) untuk tambah warga baru

**Selesai jika:** List warga tampil, bisa dicari, bisa difilter.

---

### 1.4 — Form Tambah & Edit Warga

**Apa yang dikerjakan:**  
Buat form untuk input data warga baru dan edit data warga yang sudah ada.

**Detail task:**
- [ ] Buat `add_resident_screen.dart` di `features/residents/screens/`
- [ ] Buat field input: nama lengkap, NIK, nomor unit, nomor HP, status
- [ ] Semua field wajib diisi (validasi sebelum submit)
- [ ] NIK harus 16 digit (validasi format)
- [ ] Nomor HP harus diawali 08 atau +62 (validasi format)
- [ ] Tombol simpan → insert ke tabel `profiles` di Supabase
- [ ] Setelah berhasil simpan → kembali ke list warga & refresh data
- [ ] Tampilkan pesan sukses (SnackBar) setelah berhasil tambah
- [ ] Buat `edit_resident_screen.dart` — form yang sama tapi pre-filled data warga yang dipilih
- [ ] Tombol nonaktifkan warga (ubah status jadi `inactive`)
- [ ] Konfirmasi dialog sebelum nonaktifkan ("Yakin nonaktifkan warga ini?")

**Selesai jika:** Warga baru bisa ditambah, data warga bisa diedit, warga bisa dinonaktifkan.

---

### 1.5 — Import Warga dari CSV

**Apa yang dikerjakan:**  
Fitur import massal warga dari file CSV/Excel — penting agar Pak RT tidak perlu input 300 warga satu-satu.

**Detail task:**
- [ ] Buat tombol "Import CSV" di halaman list warga
- [ ] Buat template CSV yang bisa didownload (nama kolom: nama, nik, nomor_unit, nomor_hp)
- [ ] Saat tombol ditekan → buka file picker untuk pilih file .csv atau .xlsx
- [ ] Parse isi file menggunakan package `csv` atau `excel`
- [ ] Validasi setiap baris: cek kolom wajib ada semua
- [ ] Tampilkan preview data yang akan diimport (tabel sederhana)
- [ ] Konfirmasi "Import X warga?" sebelum proses
- [ ] Insert semua data valid ke tabel `profiles` sekaligus (batch insert)
- [ ] Tampilkan hasil: "X warga berhasil diimport, Y baris gagal (alasan)"
- [ ] Baris yang gagal bisa didownload sebagai file error log

**Selesai jika:** File CSV berisi 300 warga bisa diimport dalam satu proses tanpa error.

---

### 1.6 — Halaman Detail Warga

**Apa yang dikerjakan:**  
Halaman untuk melihat informasi lengkap satu warga beserta riwayat tagihannya.

**Detail task:**
- [ ] Buat `resident_detail_screen.dart` di `features/residents/screens/`
- [ ] Tampilkan foto profil warga (atau inisial nama jika tidak ada foto)
- [ ] Tampilkan semua data warga: nama, NIK, unit, HP, status, tanggal daftar
- [ ] Tampilkan riwayat tagihan warga 6 bulan terakhir
- [ ] Setiap tagihan ditampilkan dengan status (sudah bayar / belum / terlambat)
- [ ] Hitung & tampilkan total tunggakan jika ada
- [ ] Tombol "Edit" di pojok kanan atas → buka halaman edit warga
- [ ] Tombol "Kirim WA" → buka WhatsApp langsung ke nomor warga tersebut

**Selesai jika:** Detail warga tampil lengkap beserta riwayat tagihannya.

---

### 1.7 — Konfigurasi Jenis Iuran

**Apa yang dikerjakan:**  
Buat halaman untuk admin mengatur jenis-jenis iuran yang berlaku di RW.

**Detail task:**
- [ ] Buat `billing_types_screen.dart` di `features/invoices/screens/`
- [ ] Tampilkan list semua jenis iuran yang aktif (contoh: IPL, Keamanan, Kebersihan)
- [ ] Setiap item tampilkan: nama iuran, nominal, tanggal tagih tiap bulan, status aktif/nonaktif
- [ ] Tombol tambah jenis iuran baru
- [ ] Form tambah: nama iuran, nominal (Rp), tanggal tagih (1–28), aktif/nonaktif
- [ ] Edit jenis iuran yang sudah ada
- [ ] Toggle aktif/nonaktif jenis iuran
- [ ] Nonaktifkan jenis iuran tidak menghapus data historis tagihan

**Selesai jika:** Admin bisa tambah, edit, dan nonaktifkan jenis iuran.

---

### 1.8 — Terbitkan Tagihan

**Apa yang dikerjakan:**  
Buat fitur untuk admin menerbitkan tagihan ke warga — baik satu per satu maupun massal ke semua warga.

**Detail task:**
- [ ] Buat `create_invoice_screen.dart` di `features/invoices/screens/`
- [ ] Pilih jenis iuran yang akan ditagihkan
- [ ] Pilih bulan & tahun tagihan
- [ ] Pilih target: semua warga aktif atau warga tertentu saja
- [ ] Preview: "Akan menerbitkan X tagihan senilai Rp Y masing-masing"
- [ ] Tombol konfirmasi → insert semua invoice ke tabel `invoices`
- [ ] Setiap invoice otomatis dapat due_date (sesuai tanggal tagih di billing_type)
- [ ] Validasi: tidak bisa terbitkan tagihan yang sama (bulan+jenis iuran) dua kali
- [ ] Setelah terbit → tawarkan "Broadcast ke WA sekarang?" (akan diimplementasi di Phase 2)
- [ ] Tampilkan loading progress saat proses insert banyak data

**Selesai jika:** Tagihan bisa diterbitkan ke semua warga dalam satu aksi.

---

### 1.9 — Halaman List Tagihan & Tunggakan

**Apa yang dikerjakan:**  
Buat halaman untuk admin memonitor status pembayaran semua warga.

**Detail task:**
- [ ] Buat `invoices_screen.dart` di `features/invoices/screens/`
- [ ] Tampilkan list semua tagihan bulan ini
- [ ] Filter cepat: Semua / Belum Bayar / Sudah Bayar / Terlambat
- [ ] Setiap item tampilkan: nama warga, unit, jenis iuran, nominal, status, jatuh tempo
- [ ] Warnai status: abu = pending, hijau = paid, merah = overdue
- [ ] Bagian terpisah "Tunggakan" → list warga yang punya tagihan lebih dari 1 bulan
- [ ] Di tunggakan, tampilkan total nominal tunggakan & berapa bulan menunggak
- [ ] Sort tunggakan dari yang terlama
- [ ] Tap warga tunggakan → buka detail warga

**Selesai jika:** Admin bisa melihat siapa saja yang belum bayar dan berapa lama menunggaknya.

---

### 1.10 — Catat Pengeluaran Kas

**Apa yang dikerjakan:**  
Buat fitur untuk admin mencatat pengeluaran kas lingkungan beserta bukti fisik.

**Detail task:**
- [ ] Buat `add_expense_screen.dart` di `features/expenses/screens/`
- [ ] Field input: nominal, kategori, keterangan, tanggal, foto bukti (opsional)
- [ ] Kategori yang tersedia: Kebersihan, Keamanan, Infrastruktur, Sosial, Operasional, Lain-lain
- [ ] Upload foto bukti ke Supabase Storage
- [ ] Validasi nominal harus lebih dari 0
- [ ] Setelah simpan → update saldo kas otomatis
- [ ] Buat halaman `expenses_screen.dart` untuk list semua pengeluaran bulan ini
- [ ] Tampilkan total pengeluaran bulan ini di bagian atas
- [ ] List pengeluaran urutkan dari terbaru
- [ ] Tap item → lihat detail + foto bukti

**Selesai jika:** Admin bisa catat pengeluaran dengan foto bukti, dan total pengeluaran terupdate di dashboard.

---

### ✅ Checklist Akhir Phase 1

```
[ ] Bottom nav admin 5 tab berfungsi
[ ] Dashboard kas tampil data real dengan grafik
[ ] List warga tampil dengan search & filter
[ ] Tambah & edit warga berfungsi
[ ] Import CSV 300 warga berhasil
[ ] Detail warga tampil dengan riwayat tagihan
[ ] Konfigurasi jenis iuran bisa ditambah & diedit
[ ] Tagihan bisa diterbitkan massal ke semua warga
[ ] List tagihan tampil dengan filter status
[ ] Daftar tunggakan tampil dengan sorting
[ ] Catat pengeluaran + foto berfungsi
```

---

## Phase 2 — Pembayaran Manual & Otomasi WA
> **Minggu 6–7**  
> **Tujuan:** RW bisa mengatur rekening tujuan, warga bisa bayar via transfer/scan QRIS mandiri lalu upload bukti, dan admin bisa memverifikasi. Serta alur notifikasi WA berjalan otomatis.

---

### 2.1 — Pengaturan Rekening & Kas RW

**Apa yang dikerjakan:**  
Buat pengaturan agar Pak RT bisa menambahkan informasi rekening bank atau QRIS resmi milik RW.

**Detail task:**
- [ ] Buat `payment_settings_screen.dart` di `features/settings/screens/`
- [ ] Tambahkan kolom `bank_name`, `account_number`, `account_name`, dan `qris_url` di tabel `communities` 
- [ ] Form input informasi nama bank, nomor rekening, dan nama pemilik
- [ ] Fitur upload foto QRIS kas RW (simpan ke Supabase Storage)
- [ ] Tombol simpan untuk update tabel `communities`
- [ ] Amankan RLS agar hanya admin yang bisa update 

**Selesai jika:** Admin bisa melihat dan mengubah informasi rekening dan QRIS untuk pembayaran warga.

---

### 2.2 — Daftar & Konfigurasi Fonnte (WhatsApp)

**Apa yang dikerjakan:**  
Setup layanan WhatsApp yang akan dipakai untuk broadcast tagihan dan notifikasi bukti bayar.

**Detail task:**
- [ ] Daftar akun di fonnte.com
- [ ] Pilih paket Basic atau Free trial
- [ ] Verifikasi nomor WhatsApp yang akan dipakai (nomor khusus WA RT/RW)
- [ ] Catat API key dari dashboard Fonnte
- [ ] Simpan API key di Supabase Edge Function secrets
- [ ] Test kirim pesan pertama via dashboard Fonnte

**Selesai jika:** Pesan WA bisa terkirim dari dashboard Fonnte ke nomor test.

---

### 2.3 — Edge Function: Send WhatsApp

**Apa yang dikerjakan:**  
Buat function yang mengirim pesan WhatsApp ke warga — dipakai untuk blast tagihan, reminder, dan konfirmasi.

**Detail task:**
- [ ] Buat folder `supabase/functions/send-whatsapp/`
- [ ] Function menerima: nomor tujuan, isi pesan
- [ ] Kirim request POST ke Fonnte API
- [ ] Handle error jika nomor tidak valid atau WA tidak aktif
- [ ] Log hasil pengiriman (berhasil / gagal)
- [ ] Deploy function ke Supabase
- [ ] Test kirim WA ke nomor sendiri via function

**Selesai jika:** Function dipanggil → pesan WA terkirim ke nomor tujuan.

---

### 2.4 — Fitur Broadcast Tagihan ke WA

**Apa yang dikerjakan:**  
Tambahkan tombol di halaman tagihan untuk blast semua tagihan ke WA warga sekaligus, berisi nominal dan info rekening.

**Detail task:**
- [ ] Tambahkan tombol "Broadcast ke WA" di halaman list tagihan admin
- [ ] Saat ditekan → tampilkan konfirmasi "Kirim WA ke X warga?"
- [ ] Proses broadcast: loop semua invoice pending bulan ini
- [ ] Panggil `send-whatsapp` dengan template pesan detail tagihan (Nominal, Jenis Iuran, No. Rek Tujuan)
- [ ] Tampilkan progress dan hasil akhir (berhasil/gagal)
- [ ] (Opsional) Tambahkan tanda bahwa invoice sudah pernah dibroadcast

**Selesai jika:** Klik broadcast → semua warga yang belum bayar menerima WA tagihan.

---

### 2.5 — Halaman Pembayaran Warga & Upload Bukti

**Apa yang dikerjakan:**  
Berhubung aplikasi Warga belum dilaunching, kita bisa asumsikan ini akan dikerjakan di bagian Warga App (Phase 4). Namun, untuk MVP, kita siapkan UI "Terima Pembayaran" (Review) di sisi Admin terlebih dahulu.

**Detail task:**
- [ ] Buat fitur warga mengirimkan gambar (akan dikerjakan saat masuk pengembangan shell Warga)
- [ ] Simpan gambar bukti transfer ke folder Supabase Storage `payment_proofs`
- [ ] Update status invoice menjadi `awaiting_verification` 
- [ ] Catat URL bukti di tabel `invoices` pada kolom `payment_token` (sementara dipakai untuk link gambar) atau buat kolom baru `proof_url`

**Selesai jika:** Gambar bukti transfer dapat diupload dan status berubah jadi menunggu konfirmasi.

---

### 2.6 — Verifikasi Pembayaran (Admin)

**Apa yang dikerjakan:**  
Halaman atau Bottom Sheet untuk Admin memverifikasi bukti transfer yang diunggah warga.

**Detail task:**
- [ ] Update list Tagihan di admin untuk mendeteksi status `awaiting_verification` (warna kuning/orange)
- [ ] Jika di-tap, munculkan Dialog form berisi gambar bukti transfer membesar (zoomable)
- [ ] Tombol "Tolak (Tidak Valid)" -> status kembali `pending`
- [ ] Tombol "Verifikasi Lunas" -> status berubah `paid`, catat riwayat ke tabel `payments`
- [ ] Memicu pesan WA ke warga: "Pembayaran Anda sebesar Rp X telah dikonfirmasi dan lunas."

**Selesai jika:** Admin bisa melihat bukti gambar dan menandai Lunas.

---

### 2.7 — Otomasi dengan pg_cron

**Apa yang dikerjakan:**  
Setup penjadwalan otomatis agar sistem bisa bekerja rutin tiap bulan.

**Task 1 — Auto Generate Invoice (tanggal 1 tiap bulan):**
- [ ] Buat Edge Function `auto-generate-invoices`
- [ ] Function membuat invoice baru untuk semua warga aktif & jenis iuran aktif
- [ ] Setup pg_cron di Supabase: jalankan setiap tanggal 1 jam 07.00 pagi

**Task 2 — Reminder Harian (setiap pagi):**
- [ ] Buat Edge Function `send-reminders`
- [ ] Cari invoice status `pending` yang lewat jatuh tempo
- [ ] Kirim WA reminder (H+3, H+7)
- [ ] Update status ke `overdue` jika lebih dari 7 hari
- [ ] Setup pg_cron waktu 08.00 pagi

**Selesai jika:** Tanggal 1 → invoice otomatis terbit. Setiap pagi → pengingat otomatis berjalan.

---

### ✅ Checklist Akhir Phase 2

```
[ ] Pengaturan Rekening Kas dan QRIS berfungsi
[ ] Fonnte aktif & terverifikasi
[ ] Edge Function send-whatsapp berjalan lancar
[ ] Broadcast tagihan ke semua warga via WA berfungsi
[ ] Warga (nanti saat app Warga dibuat) bisa upload bukti bayar
[ ] Admin bisa mengecek foto bukti bayar dan verifikasi jadi Lunas
[ ] WA Konfirmasi Otomatis lunas terkirim ke Warga
[ ] pg_cron auto-generate invoice (Tiap tgl 1) berjalan
[ ] pg_cron reminder tunggakan WA berjalan
```

---

## Phase 3 — Laporan & AI
> **Minggu 8–9**  
> **Tujuan:** Admin punya laporan keuangan yang bisa dibagikan ke warga, dan AI assistant sudah bisa membantu pekerjaan rutin admin.

---

### 3.1 — Halaman Laporan Keuangan

**Apa yang dikerjakan:**  
Buat halaman laporan keuangan bulanan yang informatif dan mudah dipahami Pak RT.

**Detail task:**
- [ ] Buat `reports_screen.dart` di `features/reports/screens/`
- [ ] Pilihan bulan & tahun yang bisa diganti
- [ ] Tampilkan ringkasan keuangan:
  - Total tagihan yang seharusnya masuk
  - Total yang sudah terkumpul
  - Total pengeluaran bulan ini
  - Saldo bersih (pemasukan - pengeluaran)
  - Persentase collection rate (% warga yang bayar)
- [ ] Grafik bar: perbandingan pemasukan vs pengeluaran per bulan (6 bulan terakhir)
- [ ] List detail pemasukan: semua pembayaran yang masuk bulan ini
- [ ] List detail pengeluaran: semua pengeluaran bulan ini dengan kategori
- [ ] Filter laporan per kategori pengeluaran

**Selesai jika:** Laporan keuangan bulanan tampil lengkap dengan grafik dan rincian.

---

### 3.2 — Export & Share Laporan PDF

**Apa yang dikerjakan:**  
Buat fitur untuk export laporan keuangan sebagai file PDF yang bisa dibagikan ke warga via WhatsApp.

**Detail task:**
- [ ] Tambahkan tombol "Export PDF" di halaman laporan
- [ ] Generate PDF menggunakan package `pdf`
- [ ] Konten PDF: header RW, periode laporan, ringkasan keuangan, tabel pemasukan, tabel pengeluaran, tanda tangan admin
- [ ] Tampilkan preview PDF di dalam app menggunakan `flutter_pdfview`
- [ ] Tombol share → buka share sheet Android
- [ ] Pilihan share: simpan ke galeri, kirim via WA, kirim via email
- [ ] Nama file PDF: `Laporan_Keuangan_[RW]_[Bulan]_[Tahun].pdf`

**Selesai jika:** Laporan bisa di-export jadi PDF dan di-share via WhatsApp dalam beberapa tap.

---

### 3.3 — Setup Claude AI (Anthropic)

**Apa yang dikerjakan:**  
Daftarkan akun Anthropic dan siapkan semua konfigurasi sebelum buat fitur AI.

**Detail task:**
- [ ] Daftar akun di console.anthropic.com
- [ ] Top up saldo minimum $5 (sekitar Rp 80.000) — pakai kartu debit Visa Jenius/Jago/DANA
- [ ] Buat API key baru
- [ ] Simpan API key di Supabase Edge Function secrets dengan nama `ANTHROPIC_API_KEY`
- [ ] Verifikasi key aktif dengan test sederhana via curl atau Postman
- [ ] Catat model yang dipakai: `claude-haiku-4-5-20251001` (paling murah, cukup untuk use case ini)

**Selesai jika:** API key aktif, tersimpan aman di Supabase secrets, bisa dipanggil dari Edge Function.

---

### 3.4 — Edge Function: AI Assistant

**Apa yang dikerjakan:**  
Buat serverless function yang menjadi jembatan antara app Flutter dan Claude API, sekaligus menyertakan konteks data keuangan lingkungan.

**Detail task:**
- [ ] Buat folder `supabase/functions/ai-assistant/`
- [ ] Function menerima: `community_id`, `user_id`, `query_type`
- [ ] Ambil data keuangan bulan ini dari database (invoice, payment, expense)
- [ ] Hitung ringkasan: total tagihan, terkumpul, tunggakan, pengeluaran, saldo
- [ ] Bangun system prompt yang berisi data keuangan sebagai konteks
- [ ] Kirim ke Claude API model Haiku dengan prompt yang sesuai `query_type`
- [ ] Terima response dari Claude
- [ ] Simpan log ke tabel `ai_logs`: query_type, ringkasan prompt, ringkasan response, jumlah token, waktu response
- [ ] Return teks response ke Flutter
- [ ] Deploy function ke Supabase

**Selesai jika:** Function dipanggil → mengembalikan respons AI yang relevan dengan data keuangan RW.

---

### 3.5 — Halaman AI Assistant di App

**Apa yang dikerjakan:**  
Buat halaman di app Flutter untuk admin berinteraksi dengan AI assistant.

**Detail task:**
- [ ] Buat `ai_assistant_screen.dart` di `features/ai_assistant/screens/`
- [ ] Tampilkan 3 tombol quick action:
  - "Ringkasan Keuangan Bulan Ini"
  - "Analisis Tunggakan"
  - "Prediksi Kas Bulan Depan"
- [ ] Saat tombol ditekan → panggil Edge Function `ai-assistant`
- [ ] Tampilkan loading animation saat menunggu respons AI
- [ ] Tampilkan respons AI dalam card yang rapi dan mudah dibaca
- [ ] Tombol "Salin" untuk copy teks respons
- [ ] Tombol "Share ke WA" untuk kirim langsung ke grup WA RT
- [ ] Simpan riwayat 5 percakapan terakhir (bisa dilihat lagi)
- [ ] Tampilkan disclaimer kecil: "Respons AI berdasarkan data yang tersedia"

**Selesai jika:** Admin bisa tap 1 tombol dan dalam beberapa detik mendapat ringkasan keuangan dari AI.

---

### 3.6 — Fitur Surat Digital

**Apa yang dikerjakan:**  
Buat fitur untuk generate surat pengantar RT secara digital dengan data warga yang otomatis ter-isi.

**Detail task:**
- [ ] Buat halaman `create_letter_screen.dart` di `features/reports/screens/`
- [ ] Pilihan jenis surat: Domisili, Usaha, Tidak Mampu, Keterangan Umum
- [ ] Pilih warga penerima surat → data otomatis terisi (nama, NIK, alamat)
- [ ] Field tambahan sesuai jenis surat (contoh: nama usaha untuk surat usaha)
- [ ] Nama & jabatan penandatangan (nama Pak RT)
- [ ] Tanggal surat (default hari ini, bisa diubah)
- [ ] Preview surat sebelum generate
- [ ] Generate sebagai PDF menggunakan template yang sudah ditentukan
- [ ] Simpan arsip surat digital di Supabase Storage
- [ ] List semua surat yang pernah dibuat per warga

**Selesai jika:** Surat pengantar bisa dibuat dalam < 1 menit dan di-export sebagai PDF.

---

### ✅ Checklist Akhir Phase 3

```
[ ] Laporan keuangan bulanan tampil dengan grafik
[ ] Export PDF laporan berfungsi
[ ] Share PDF via WhatsApp berfungsi
[ ] Akun Anthropic aktif, API key tersimpan
[ ] Edge Function ai-assistant berjalan
[ ] Semua interaksi AI tersimpan di ai_logs
[ ] Halaman AI assistant di app berfungsi
[ ] 3 quick action AI menghasilkan respons akurat
[ ] Fitur share respons AI ke WA berfungsi
[ ] Generate surat digital berfungsi
```

---

## Phase 4 — Warga App & Marketplace
> **Minggu 10–11**  
> **Tujuan:** Warga memiliki pengalaman app yang lengkap — bukan hanya bisa bayar tagihan, tapi juga aktif menggunakan app setiap hari lewat marketplace dan pengumuman.

---

### 4.1 — Setup Navigasi Warga

**Apa yang dikerjakan:**  
Buat kerangka navigasi khusus untuk halaman-halaman warga.

**Detail task:**
- [ ] Buat `resident_shell.dart` di folder `shell/`
- [ ] Pasang Bottom Navigation Bar dengan 4 tab: Beranda, Tagihan, Marketplace, Pengumuman
- [ ] Daftarkan semua route warga di `router.dart`
- [ ] Pastikan warga yang login tidak bisa mengakses halaman admin

**Selesai jika:** Warga login → masuk ke shell warga, tidak bisa akses halaman admin sama sekali.

---

### 4.2 — Halaman Beranda Warga

**Apa yang dikerjakan:**  
Buat halaman pertama yang dilihat warga setelah login — ringkasan tagihan dan menu navigasi cepat.

**Detail task:**
- [ ] Buat `resident_home_screen.dart` di `features/dashboard/screens/`
- [ ] Tampilkan sapaan: "Halo, [Nama Warga]!"
- [ ] Jika ada tagihan pending → tampilkan banner notifikasi merah/oranye
  - Tuliskan berapa tagihan yang belum dibayar
  - Tombol "Bayar Sekarang" langsung di banner
- [ ] Tampilkan 4 menu cepat dalam grid: Tagihan Saya, Marketplace, Pengumuman, Riwayat Bayar
- [ ] Tampilkan pengumuman terbaru (1–2 item) sebagai preview
- [ ] Tampilkan listing marketplace terbaru (3–4 item) sebagai preview

**Selesai jika:** Beranda warga tampil informatif, tagihan pending langsung terlihat.

---

### 4.3 — Halaman Tagihan Warga

**Apa yang dikerjakan:**  
Buat halaman khusus warga untuk melihat dan membayar tagihan mereka sendiri.

**Detail task:**
- [ ] Buat `resident_invoices_screen.dart` di `features/invoices/screens/`
- [ ] Tampilkan semua tagihan warga bulan ini
- [ ] Filter: Belum Bayar / Sudah Bayar / Semua
- [ ] Setiap tagihan tampilkan: jenis iuran, nominal, jatuh tempo, status
- [ ] Tombol "Bayar" di setiap tagihan yang belum dibayar
- [ ] Tap tombol "Bayar" → buka `PaymentWebViewScreen` dengan payment_link invoice itu
- [ ] Setelah bayar → status berubah dan halaman refresh otomatis
- [ ] Bagian "Riwayat Pembayaran": list semua pembayaran yang sudah pernah dilakukan
- [ ] Setiap riwayat tampilkan: tanggal bayar, metode, nominal, nomor referensi

**Selesai jika:** Warga bisa lihat tagihan, klik bayar, bayar via Midtrans, dan status langsung terupdate.

---

### 4.4 — Halaman Feed Marketplace

**Apa yang dikerjakan:**  
Buat halaman feed marketplace yang menampilkan semua listing dari warga satu RW.

**Detail task:**
- [ ] Buat `marketplace_screen.dart` di `features/marketplace/screens/`
- [ ] Tampilkan listing dalam grid 2 kolom
- [ ] Setiap card tampilkan: foto, judul, harga, nama penjual, nomor unit
- [ ] Tab filter kategori di bagian atas: Semua, Makanan, Jasa, Barang Bekas, Tanaman
- [ ] Search bar untuk cari listing berdasarkan judul
- [ ] Scroll infinite (load lebih banyak saat scroll ke bawah)
- [ ] Loading shimmer saat data sedang diambil
- [ ] Empty state jika belum ada listing: "Belum ada yang jualan nih, jadilah yang pertama!"
- [ ] FAB tombol "+" untuk tambah listing baru
- [ ] Real-time update jika ada listing baru dari warga lain

**Selesai jika:** Feed marketplace tampil dengan grid listing, bisa difilter dan dicari.

---

### 4.5 — Form Tambah Listing Marketplace

**Apa yang dikerjakan:**  
Buat form untuk warga memposting produk atau jasa yang ingin dijual.

**Detail task:**
- [ ] Buat `add_listing_screen.dart` di `features/marketplace/screens/`
- [ ] Field: judul listing, kategori, deskripsi, harga (boleh kosong = gratis/nego)
- [ ] Upload foto: bisa pilih dari galeri, maksimal 3 foto
- [ ] Foto diupload ke Supabase Storage
- [ ] Preview foto sebelum submit
- [ ] Hapus foto yang tidak diinginkan sebelum submit
- [ ] Validasi: judul dan kategori wajib diisi
- [ ] Setelah submit → listing muncul di feed dengan status `active`
- [ ] Warga bisa lihat listing miliknya sendiri di profil atau halaman "Listing Saya"
- [ ] Warga bisa tandai listing sebagai "Terjual" atau hapus listing

**Selesai jika:** Warga bisa posting listing dengan foto dalam < 2 menit.

---

### 4.6 — Halaman Detail Listing

**Apa yang dikerjakan:**  
Buat halaman detail untuk melihat informasi lengkap satu listing marketplace.

**Detail task:**
- [ ] Buat `listing_detail_screen.dart` di `features/marketplace/screens/`
- [ ] Tampilkan foto (bisa swipe jika lebih dari 1)
- [ ] Tampilkan: judul, harga, kategori, deskripsi lengkap
- [ ] Tampilkan info penjual: nama, nomor unit, rating (jika ada)
- [ ] Tombol "Hubungi via WhatsApp" → buka WA ke nomor penjual langsung
- [ ] Tombol "Bagikan" → share link listing atau screenshot
- [ ] Tampilkan listing lain dari penjual yang sama di bagian bawah
- [ ] Tombol laporan jika ada konten tidak pantas

**Selesai jika:** Detail listing tampil lengkap, tombol WA berhasil buka WhatsApp penjual.

---

### 4.7 — Sistem Rating Penjual

**Apa yang dikerjakan:**  
Buat fitur rating sederhana agar warga bisa menilai penjual setelah transaksi.

**Detail task:**
- [ ] Tambahkan tabel `ratings` di database: id, listing_id, rater_id, seller_id, score (1–5), comment
- [ ] Setelah listing ditandai "Terjual" → pembeli dapat notifikasi untuk memberi rating
- [ ] Form rating: bintang 1–5 + komentar opsional
- [ ] Tampilkan rata-rata rating penjual di halaman profil & detail listing
- [ ] Badge "Terpercaya" untuk penjual dengan rating ≥ 4.5 dan minimal 5 transaksi

**Selesai jika:** Warga bisa memberi rating, rata-rata rating tampil di profil penjual.

---

### 4.8 — Halaman Pengumuman

**Apa yang dikerjakan:**  
Buat halaman di sisi warga untuk membaca pengumuman dari admin RT.

**Detail task:**
- [ ] Buat `announcements_screen.dart` di `features/announcements/screens/`
- [ ] Tampilkan list pengumuman dari terbaru ke terlama
- [ ] Setiap item tampilkan: judul, tanggal, preview isi, badge tipe (info/penting/urgent)
- [ ] Warna badge berbeda: biru = info, oranye = penting, merah = urgent
- [ ] Tap pengumuman → tampilkan isi lengkap
- [ ] Push notification saat admin posting pengumuman baru
- [ ] Tandai pengumuman yang sudah dibaca (abu-abu) vs belum (bold)

**Selesai jika:** Warga menerima push notif saat ada pengumuman baru, bisa baca isi lengkapnya.

---

### 4.9 — Form Kirim Pengumuman (Sisi Admin)

**Apa yang dikerjakan:**  
Buat fitur untuk admin membuat dan mengirim pengumuman ke seluruh warga.

**Detail task:**
- [ ] Buat `create_announcement_screen.dart` di `features/announcements/screens/`
- [ ] Field: judul, isi pengumuman, tipe (info/penting/urgent)
- [ ] Toggle: kirim WA blast juga? (opsional)
- [ ] Preview pengumuman sebelum dikirim
- [ ] Setelah submit → simpan ke database & kirim push notification ke semua warga
- [ ] Jika toggle WA aktif → panggil Edge Function `send-whatsapp` ke semua warga
- [ ] List pengumuman yang pernah dibuat di sisi admin

**Selesai jika:** Admin bisa buat pengumuman, warga terima push notif & WA jika dipilih.

---

### 4.10 — Transparansi Kas untuk Warga

**Apa yang dikerjakan:**  
Buat halaman khusus di sisi warga untuk melihat kondisi kas lingkungan secara transparan.

**Detail task:**
- [ ] Tambahkan tab atau menu "Kas Lingkungan" di app warga
- [ ] Tampilkan saldo kas saat ini
- [ ] Tampilkan ringkasan bulan ini: total pemasukan, total pengeluaran
- [ ] List 10 pengeluaran terakhir (lengkap dengan kategori dan keterangan)
- [ ] Grafik sederhana: pemasukan vs pengeluaran 3 bulan terakhir
- [ ] Warga hanya bisa lihat — tidak bisa edit apapun

**Selesai jika:** Warga bisa melihat kondisi kas lingkungan kapan saja secara transparan.

---

### ✅ Checklist Akhir Phase 4

```
[ ] Shell warga dengan 4 tab berfungsi
[ ] Beranda warga tampil tagihan pending & menu
[ ] Tagihan warga tampil, bisa dibayar via WebView
[ ] Status tagihan update otomatis setelah bayar
[ ] Feed marketplace tampil dengan grid & filter
[ ] Warga bisa posting listing dengan foto
[ ] Detail listing tampil, tombol WA penjual berfungsi
[ ] Rating penjual bisa diberikan & tampil
[ ] Pengumuman tampil, push notif berfungsi
[ ] Admin bisa buat pengumuman + WA blast
[ ] Transparansi kas tampil untuk warga
```

---

## Phase 5 — Polish & Play Store
> **Minggu 12**  
> **Tujuan:** App sudah diuji dengan user nyata, bebas bug kritis, tampilan rapi, dan berhasil masuk Google Play Store.

---

### 5.1 — User Acceptance Testing (UAT)

**Apa yang dikerjakan:**  
Uji coba app dengan pengguna nyata sebelum dipublish. Ini paling penting — jangan skip!

**Detail task:**

**Session 1 — Test dengan Pak RT (Admin):**
- [ ] Minta Pak RT coba login sendiri tanpa dibantu
- [ ] Minta tambah 1 warga baru dari awal
- [ ] Minta terbitkan tagihan bulan ini
- [ ] Minta lihat dashboard kas
- [ ] Minta generate ringkasan AI
- [ ] Catat semua kebingungan & pertanyaan yang muncul
- [ ] Catat semua error atau crash yang terjadi

**Session 2 — Test dengan 5 Warga:**
- [ ] Pilih warga yang berbeda: 1 muda, 2 paruh baya, 1 yang tidak familiar teknologi
- [ ] Minta login sendiri
- [ ] Minta lihat tagihan dan coba bayar (sandbox)
- [ ] Minta buka marketplace dan posting 1 listing
- [ ] Catat semua kebingungan & titik friction

**Perbaikan setelah UAT:**
- [ ] Buat daftar semua issue yang ditemukan
- [ ] Prioritaskan: bug kritis (harus diperbaiki) vs UX improvement (boleh nanti)
- [ ] Perbaiki semua bug kritis dalam 2 hari
- [ ] Re-test fitur yang diperbaiki

**Selesai jika:** Pak RT bisa menggunakan semua fitur admin tanpa dibantu, minimal 3 dari 5 warga bisa bayar tagihan sendiri.

---

### 5.2 — Polish UI & UX

**Apa yang dikerjakan:**  
Rapikan semua hal kecil di tampilan dan interaksi yang membuat app terasa profesional.

**Detail task:**

**Loading States:**
- [ ] Setiap halaman yang fetch data harus punya loading indicator
- [ ] Pakai shimmer effect (kotak abu-abu bergerak) bukan spinner biasa

**Empty States:**
- [ ] Jika data kosong jangan tampilkan halaman kosong — buat ilustrasi + teks informatif
- [ ] Contoh: "Belum ada tagihan bulan ini" dengan gambar ikon tagihan

**Error Handling:**
- [ ] Jangan tampilkan kode error mentah ke user
- [ ] Semua error tampilkan dalam bahasa Indonesia yang ramah
- [ ] Setiap error harus ada tombol "Coba Lagi"

**Konfirmasi Aksi Permanen:**
- [ ] Hapus data → selalu minta konfirmasi dialog
- [ ] Nonaktifkan warga → konfirmasi dulu
- [ ] Broadcast WA → konfirmasi jumlah penerima dulu

**Konsistensi Visual:**
- [ ] Semua tombol utama warna sama (navy #0F2D5E)
- [ ] Semua font size konsisten (judul 18, body 14, caption 12)
- [ ] Padding & margin konsisten di semua halaman
- [ ] Icon set konsisten (pakai Material Icons saja)

**Selesai jika:** Tidak ada halaman yang tampak "unfinished", semua error ditangani dengan baik.

---

### 5.3 — Setup Push Notification (Firebase)

**Apa yang dikerjakan:**  
Aktifkan push notification agar warga menerima notif di HP meskipun tidak sedang buka app.

**Detail task:**
- [ ] Buat project di Firebase Console (gratis)
- [ ] Aktifkan Firebase Cloud Messaging (FCM)
- [ ] Download file `google-services.json` dan tambahkan ke `android/app/`
- [ ] Tambahkan `google-services.json` ke `.gitignore`
- [ ] Konfigurasi FCM di Flutter menggunakan package `firebase_messaging`
- [ ] Minta izin notifikasi ke user saat pertama buka app
- [ ] Simpan FCM token warga ke tabel `profiles` kolom `fcm_token`
- [ ] Update Edge Function pengumuman untuk kirim push notif via FCM ke semua warga
- [ ] Test notifikasi: admin buat pengumuman → warga terima push notif
- [ ] Pastikan notif muncul bahkan saat app dalam mode background/killed

**Selesai jika:** Warga menerima push notif di HP meskipun app tidak dibuka.

---

### 5.4 — Siapkan Aset Play Store

**Apa yang dikerjakan:**  
Siapkan semua materi visual dan teks yang dibutuhkan untuk halaman WargaOS di Play Store.

**Detail task:**

**Visual:**
- [ ] App icon 512×512 PNG, latar belakang tidak transparan
- [ ] Feature graphic 1024×500 PNG (banner besar di halaman Play Store)
- [ ] Screenshot minimal 4, maksimal 8 — dalam format portrait
  - Screenshot 1: Login screen
  - Screenshot 2: Dashboard kas admin
  - Screenshot 3: Halaman tagihan + status pembayaran
  - Screenshot 4: Marketplace feed
  - Screenshot 5: Halaman AI assistant
  - Screenshot 6: Halaman warga (beranda + tagihan)

**Teks:**
- [ ] Nama app: WargaOS
- [ ] Nama developer: nama kamu atau nama tim
- [ ] Deskripsi singkat (80 karakter): "Sistem manajemen RT/RW dengan AI — iuran, kas, & marketplace warga"
- [ ] Deskripsi panjang (4000 karakter): jelaskan fitur utama, keunggulan, siapa yang cocok menggunakan
- [ ] Kategori: Business

**Legal:**
- [ ] Buat halaman Privacy Policy — bisa pakai Notion (gratis, bisa di-publish)
- [ ] Isi minimal: data apa yang dikumpulkan, bagaimana data digunakan, kontak

**Selesai jika:** Semua aset siap, privacy policy punya URL publik yang bisa diakses.

---

### 5.5 — Build Release & Setup Signing

**Apa yang dikerjakan:**  
Build versi release app yang siap diupload ke Play Store dengan tanda tangan digital yang benar.

**Detail task:**
- [ ] Generate keystore (file tanda tangan digital app)
  - Simpan file `.keystore` di tempat yang aman — di luar folder project
  - Simpan password keystore di password manager
  - **PERINGATAN: Jika file ini hilang, kamu tidak bisa update app selamanya**
- [ ] Konfigurasi signing di `android/app/build.gradle`
- [ ] Ganti nilai `applicationId` ke `com.wargaos.app`
- [ ] Set `versionCode` = 1 dan `versionName` = "1.0.0"
- [ ] Jalankan `flutter build appbundle --release`
- [ ] Cek ukuran file .aab yang dihasilkan (biasanya 20–50 MB)
- [ ] Install app dari file .aab ke HP fisik untuk test final
- [ ] Pastikan tidak ada warning saat install
- [ ] Test semua fitur utama di HP fisik (bukan emulator)

**Selesai jika:** File .aab berhasil dibuild, app berjalan normal di HP fisik.

---

### 5.6 — Publish ke Google Play Store

**Apa yang dikerjakan:**  
Upload app ke Play Store dan submit untuk review.

**Detail task:**
- [ ] Daftar Google Play Developer Account di play.google.com/console
- [ ] Bayar biaya pendaftaran $25 (sekitar Rp 400.000) — one-time, tidak perlu bayar lagi
- [ ] Lengkapi profil developer (nama, alamat email, nomor HP verifikasi)
- [ ] Buat app baru di Play Console → pilih "App" (bukan Game)
- [ ] Isi semua informasi di tab "Store Listing" (nama, deskripsi, screenshot, icon)
- [ ] Masukkan URL Privacy Policy
- [ ] Pilih kategori dan rating konten (isi kuesioner rating)
- [ ] Di tab "Production" → Create new release
- [ ] Upload file .aab
- [ ] Isi release notes: "Versi pertama WargaOS — sistem manajemen RT/RW"
- [ ] Review semua section → tidak boleh ada tanda seru merah
- [ ] Submit for review
- [ ] Tunggu 1–3 hari kerja untuk proses review Google

**Selesai jika:** Status app di Play Console berubah dari "In Review" menjadi "Published". Link Play Store bisa dibagikan.

---

### ✅ Checklist Akhir Phase 5

```
[ ] UAT selesai dengan Pak RT & 5 warga
[ ] Semua bug kritis dari UAT sudah diperbaiki
[ ] Semua halaman punya loading & empty state
[ ] Semua error ditangani dengan pesan ramah
[ ] Push notification berfungsi via FCM
[ ] App icon, screenshot, deskripsi Play Store siap
[ ] Privacy policy punya URL publik
[ ] Keystore tersimpan aman
[ ] flutter build appbundle --release berhasil
[ ] App berjalan normal di HP fisik
[ ] App berhasil dipublish di Play Store ✅
```

---

## Production — Post-Launch
> **Bulan 4–5**  
> **Tujuan:** Sistem berjalan stabil di RW pertama, feedback dikumpulkan secara rutin, dan mulai ekspansi ke RW lain secara bertahap.

---

### P.1 — Monitoring Harian

**Apa yang dikerjakan:**  
Rutin cek kondisi sistem setiap hari — tidak perlu lama, cukup 5–10 menit.

**Detail task:**
- [ ] Cek Sentry — ada error baru? Jika ada, seberapa parah?
- [ ] Cek Supabase dashboard — database & storage usage masih aman?
- [ ] Cek Fonnte dashboard — apakah ada WA yang gagal terkirim?
- [ ] Cek Play Store reviews — ada review negatif baru?
- [ ] Cek penggunaan Claude API — biaya masih sesuai estimasi?
- [ ] Cek Midtrans dashboard — semua transaksi terproses normal?

**Jadwal cek:** Setiap pagi sebelum mulai aktivitas lain, maksimal 10 menit.

---

### P.2 — Monitoring Mingguan

**Apa yang dikerjakan:**  
Evaluasi performa sistem dan engagement pengguna setiap minggu.

**Metrics yang dicek setiap minggu:**
- [ ] Collection rate bulan ini: berapa % warga sudah bayar via app?
- [ ] DAU (Daily Active User): rata-rata berapa warga buka app per hari?
- [ ] Marketplace activity: berapa listing baru ditambah minggu ini?
- [ ] AI usage: berapa kali AI dipakai, query type apa yang paling sering?
- [ ] Error rate: berapa % request yang error?
- [ ] App rating terkini di Play Store

**Target yang ingin dicapai bulan pertama:**
- Collection rate ≥ 60% (warga yang bayar via app)
- Minimal 10 warga aktif di marketplace
- AI dipakai minimal 10 kali oleh admin
- Rating Play Store ≥ 4.0

---

### P.3 — Proses Feedback & Iterasi

**Apa yang dikerjakan:**  
Kumpulkan masukan dari pengguna secara terstruktur dan ubah menjadi perbaikan nyata.

**Siklus 2 Minggu:**
- [ ] **Minggu 1 — Kumpulkan:** Chat langsung dengan Pak RT, tanya 3–5 warga secara informal, baca semua Play Store review
- [ ] **Minggu 1 — Kategorikan:** Bagi feedback ke 3 bucket: Bug (harus diperbaiki) / UX (perlu diperbaiki) / Fitur Baru (dicatat dulu)
- [ ] **Minggu 2 — Kerjakan:** Prioritaskan 1–3 hal paling impactful untuk dikerjakan minggu ini
- [ ] **Minggu 2 — Deploy:** Build .aab baru, upload ke Play Store sebagai update
- [ ] **Minggu 2 — Verifikasi:** Konfirmasi ke Pak RT bahwa issue-nya sudah teratasi

---

### P.4 — Ekspansi ke RW Lain

**Apa yang dikerjakan:**  
Mulai pendekatan ke RW-RW lain di sekitar perumahan untuk menjadi pelanggan berbayar.

**Syarat sebelum mulai ekspansi:**
- [ ] Sistem stabil minimal 1 bulan tanpa incident serius
- [ ] Collection rate ≥ 70% di RW pertama
- [ ] Tidak ada bug kritis dalam 2 minggu terakhir
- [ ] Pak RT bersedia jadi referensi ke RW lain

**Persiapan ekspansi:**
- [ ] Tentukan harga subscription: Rp 100.000–200.000/bulan per RW
- [ ] Siapkan cara terima pembayaran subscription: rekening bank / QRIS pribadi
- [ ] Buat MoU sederhana 1 halaman: ruang lingkup layanan, harga, cara pembayaran, ketentuan berhenti langganan
- [ ] Siapkan deck presentasi singkat (5–7 slide) untuk pitch ke Pak RW lain
- [ ] Kumpulkan testimoni dari Pak RT: "Sebelum pakai WargaOS vs sesudahnya"

**Proses onboarding RW baru:**
- [ ] Buat akun community baru di database
- [ ] Buat akun admin untuk pengurus RW/RT baru
- [ ] Dampingi proses import data warga (sesi 30–60 menit via video call atau langsung)
- [ ] Live bersama selama broadcast tagihan pertama

**Target ekspansi:**
- Bulan 4: 3 RW aktif total (2 berbayar)
- Bulan 5: 5 RW aktif total (4 berbayar)
- Bulan 6: MRR ≥ Rp 600.000 (4 RW × Rp 150.000)

---

### P.5 — Pengembangan Fitur Lanjutan (Backlog)

Fitur-fitur ini tidak masuk MVP tapi bisa dikerjakan setelah sistem stabil dan ada warga yang request:

| Prioritas | Fitur | Alasan |
|-----------|-------|--------|
| Tinggi | Multi-RT dalam 1 RW | Banyak RW punya lebih dari 1 RT |
| Tinggi | Struk pembayaran digital | Warga minta bukti resmi |
| Tinggi | Notifikasi in-app | Mengurangi ketergantungan WA |
| Sedang | Polling/voting warga | Meningkatkan partisipasi warga |
| Sedang | Laporan tahunan otomatis | Berguna untuk RAT (Rapat Akhir Tahun) |
| Sedang | Chat in-app antar warga | Mengurangi ketergantungan grup WA RT |
| Rendah | Integrasi QRIS statis | Alternatif pembayaran offline |
| Rendah | Mode offline | Untuk koneksi internet tidak stabil |
| Rendah | iOS version | Ekspansi platform setelah Android stabil |

---

### ✅ Checklist Production

```
[ ] Monitoring harian berjalan rutin
[ ] Tidak ada P1 bug dalam 1 bulan pertama
[ ] Collection rate ≥ 60% di bulan pertama
[ ] Feedback loop 2 minggu berjalan
[ ] Minimal 1 update app dirilis bulan pertama
[ ] Testimoni dari Pak RT sudah dikumpulkan
[ ] Harga subscription sudah ditetapkan
[ ] MoU sederhana sudah dibuat
[ ] RW kedua sudah onboarding
[ ] MRR pertama masuk ke rekening ✅
```

---

## Ringkasan Budget

| Layanan | Biaya/Bulan |
|---------|-------------|
| Supabase Free Tier | Rp 0 |
| Fonnte WhatsApp Basic | Rp 65.000 |
| Claude API Haiku | ~Rp 50.000 |
| Midtrans (no monthly fee) | Rp 0 |
| Firebase FCM | Rp 0 |
| Domain .my.id | ~Rp 1.200 |
| Sentry Free Tier | Rp 0 |
| **Total per Bulan** | **~Rp 116.200** |
| Google Play Developer (sekali bayar) | ~Rp 400.000 |

**Catatan:** Budget Rp 500–700K/bulan masih punya sisa ~Rp 380K sebagai buffer.

---

## Catatan Kritis

> ⚠️ **Keystore** — jika file keystore hilang, kamu tidak bisa update app di Play Store selamanya. Simpan di Google Drive + external hard drive + catat password-nya di tempat terpisah.

> ⚠️ **File `.env` & `google-services.json`** — jangan pernah di-commit ke GitHub. Cek `.gitignore` sebelum setiap commit.

> 📊 **Tabel `ai_logs`** — ini data primer skripsi kamu. Setiap interaksi AI tercatat: query type, jumlah token, waktu respons. Analisis data ini untuk bab Hasil & Pembahasan skripsi.

> 🎯 **Urutan prioritas:** Phase 0 → 1 → 2 harus selesai dulu dan benar-benar stabil sebelum mengerjakan Phase 3 dan seterusnya. Sistem yang bisa terima pembayaran > fitur AI yang keren tapi payment-nya belum jalan.

> 💡 **Untuk skripsi:** Tabel `ai_logs` + data collection rate + data marketplace activity = 3 sumber data kuantitatif yang kuat untuk bab analisis skripsi kamu.

---

*WargaOS — Neighborhood Operating System*  
*Flutter + Supabase | Android First | v1.0 | Maret 2026*