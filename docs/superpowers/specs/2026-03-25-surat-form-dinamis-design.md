# Design: Form Dinamis Permohonan Surat & Auto-Generate

**Tanggal:** 2026-03-25
**Status:** Approved

---

## Latar Belakang

Flow permohonan surat saat ini mengharuskan admin mengisi ulang seluruh data warga (nama, NIK, TTL, agama, pekerjaan, dll.) setiap kali membuat surat. Warga hanya mengisi tujuan dan catatan singkat. Ini tidak efisien dan rawan kesalahan input.

Perubahan ini memindahkan tanggung jawab pengisian data ke warga — sesuai jenis suratnya — sehingga admin tinggal verifikasi dan ACC. Surat ter-generate otomatis, dan warga bisa lihat serta download dokumennya langsung dari app.

---

## Tujuan

- Warga mengisi form lengkap sesuai jenis surat yang dimohon
- Admin hanya verifikasi data, tidak input ulang
- Surat ter-generate otomatis saat admin ACC
- Warga dapat melihat dan mengunduh dokumen setelah di-ACC

---

## Pendekatan

**Approach yang dipilih: `form_data` JSONB di `letter_requests`**

Menyimpan semua field dinamis per jenis surat dalam satu kolom JSONB. Fleksibel untuk field unik per jenis surat (SKU punya `nama_usaha`/`alamat_usaha`, kematian punya `nama_almarhum`, dll.) tanpa perlu migration besar.

---

## 1. Database Schema

### Migration baru

```sql
ALTER TABLE letter_requests
  ADD COLUMN form_data JSONB,
  ADD COLUMN applicant_name TEXT;
```

- `form_data` — menyimpan semua field yang warga isi, format JSON per jenis surat
- `applicant_name` — nama pemohon yang diisi warga (untuk kasus surat kematian, nama almarhum berbeda dari pemohon)

### Status flow baru

| Status | Keterangan |
|---|---|
| `pending` | Warga baru submit, admin belum verifikasi |
| `verified` | Admin ACC, surat sudah ter-generate |
| `rejected` | Admin tolak, ada alasan penolakan |
| `completed` | Warga sudah melihat/mengambil dokumen |

Status `in_progress` dan `ready` dihapus karena tidak relevan dengan flow baru.

### Contoh `form_data` per jenis surat

```json
// domisili
{
  "nik": "3201xxxxxxxxxx",
  "ttl": "Jakarta, 01-01-1990",
  "gender": "Laki-laki",
  "agama": "Islam",
  "keperluan": "Mendaftar kuliah S2"
}

// skck
{
  "nik": "3201xxxxxxxxxx",
  "ttl": "Bandung, 10-05-1995",
  "gender": "Perempuan",
  "agama": "Kristen Protestan",
  "marital_status": "Belum Kawin",
  "pekerjaan": "Mahasiswa",
  "keperluan": "Melamar kerja"
}

// sktm
{
  "nik": "3201xxxxxxxxxx",
  "no_kk": "3201xxxxxxxxxx",
  "alasan": "Biaya pengobatan",
  "pernyataan_kondisi": "Kepala keluarga tidak bekerja akibat sakit"
}

// sku
{
  "nik": "3201xxxxxxxxxx",
  "ttl": "Surabaya, 22-08-1985",
  "gender": "Laki-laki",
  "nama_usaha": "Warung Bu Siti",
  "jenis_usaha": "Warung makan",
  "alamat_usaha": "Jl. Merpati No. 5, RT 03",
  "keperluan": "Pengajuan KUR BRI"
}

// nikah
{
  "nik": "3201xxxxxxxxxx",
  "ttl": "Jakarta, 14-02-2000",
  "gender": "Laki-laki",
  "pekerjaan": "Karyawan Swasta",
  "nama_ayah": "Suharto",
  "nama_ibu": "Sumiati"
}

// kematian
{
  "nama_almarhum": "Sutrisno",
  "nik_almarhum": "3201xxxxxxxxxx",
  "ttl_almarhum": "Solo, 12-12-1950",
  "tanggal_meninggal": "2026-03-20",
  "penyebab": "Sakit",
  "hubungan_pelapor": "Anak"
}

// ktp_kk
{
  "nik": "3201xxxxxxxxxx",
  "alasan": "KTP hilang",
  "keterangan": "Kehilangan saat bepergian"
}
```

---

## 2. Resident Flow — Form Dinamis

### RequestLetterScreen (redesign)

Multi-step form menggantikan form sederhana yang ada.

**Step 1 — Pilih Jenis Surat**
- Dropdown atau grid pilihan jenis surat
- Setelah pilih, tampil info singkat dokumen yang perlu disiapkan warga sebagai referensi (tidak wajib upload, hanya informasi)

**Step 2 — Isi Form (dinamis per jenis surat)**

Field per jenis surat:

| Jenis Surat | Field |
|---|---|
| Domisili | NIK, TTL, Gender, Agama, Keperluan |
| KTP/KK | NIK, Alasan (KTP baru/hilang/rusak/perpanjangan, KK baru/perbaikan data), Keterangan |
| SKCK | NIK, TTL, Gender, Agama, Status Perkawinan, Pekerjaan, Keperluan |
| SKTM | NIK, No KK, Alasan Kebutuhan (pendidikan/kesehatan/lainnya), Pernyataan Kondisi |
| SKU | NIK, TTL, Gender, Nama Usaha, Jenis Usaha, Alamat Usaha, Keperluan |
| Nikah | NIK, TTL, Gender, Pekerjaan, Nama Ayah, Nama Ibu |
| Kematian | Nama Almarhum, NIK Almarhum, TTL Almarhum, Tanggal Meninggal, Penyebab, Hubungan Pelapor |
| Custom | Keperluan (teks bebas) |

**Step 3 — Review & Kirim**
- Tampil ringkasan semua data yang diisi
- Tombol edit untuk kembali ke step 2
- Tombol kirim untuk submit

Setelah submit:
- Data tersimpan ke `letter_requests` dengan `form_data` berisi semua field yang diisi
- Status otomatis `pending`
- Warga kembali ke layanan screen dan dapat track status

### Tracking Status di Layanan Screen

| Status | Label | Aksi |
|---|---|---|
| `pending` | Menunggu Verifikasi | — |
| `verified` | Surat Siap | Shortcut ke Dokumen Saya |
| `rejected` | Ditolak | Tampil alasan + tombol Ajukan Ulang |
| `completed` | Selesai | Lihat Dokumen |

---

## 3. Admin Flow — Verifikasi + Auto-Generate

### AdminRequestsScreen

Tombol "Buat Surat" diganti "Verifikasi". Tidak ada lagi navigasi ke `CreateLetterScreen` dari permohonan warga.

### VerifyRequestScreen (baru)

Screen atau bottom sheet full yang menampilkan:

- Semua data dari `form_data` dalam tampilan read-only, dikelompokkan rapi
- Data profil warga (nama, unit) dari `profiles`
- Jenis surat yang dimohon

Dua aksi:

**Tolak:**
- Admin isi alasan penolakan (wajib)
- Status update ke `rejected`
- Warga dapat notifikasi

**ACC & Generate Surat:**
1. Sistem panggil `LetterPdfGenerator.getTemplate()` dengan data dari `form_data` + data komunitas dari DB
2. Insert ke tabel `letters` dengan `generated_content` hasil generate
3. Update `letter_requests.status` ke `verified`, isi `letter_id` dengan ID surat yang baru dibuat
4. Warga dapat notifikasi "Surat kamu sudah siap"

Admin masih bisa download/share PDF dari halaman letters yang sudah ada untuk dikirim manual via WA.

### CreateLetterScreen

Tetap dipertahankan untuk kebutuhan admin membuat surat mandiri (tanpa permohonan dari warga). Tidak ada perubahan di screen ini.

---

## 4. Resident View Dokumen

### letters_screen.dart

Halaman "Dokumen Saya" di resident side sudah ada. Pastikan query menggunakan `resident_id` warga yang sedang login.

Setiap dokumen yang di-ACC otomatis muncul di sini karena `letters.resident_id` di-set saat insert.

Tampilan per dokumen:
- Jenis surat dan nomor surat
- Tanggal dibuat
- Tombol Unduh PDF — generate PDF on-the-fly dari `generated_content` yang tersimpan

Tidak ada perubahan besar pada screen ini, hanya verifikasi bahwa query sudah benar.

---

## 5. Perubahan File

| File | Perubahan |
|---|---|
| `supabase/migrations/` | Migration baru: tambah `form_data`, `applicant_name`, update status values |
| `lib/features/layanan/models/letter_request_model.dart` | Tambah field `formData`, `applicantName`; update status labels |
| `lib/features/layanan/screens/request_letter_screen.dart` | Redesign total: multi-step form dinamis per jenis surat |
| `lib/features/layanan/screens/admin_requests_screen.dart` | Ganti tombol "Buat Surat" jadi "Verifikasi" |
| `lib/features/layanan/screens/verify_request_screen.dart` | Buat baru: tampil data warga + aksi ACC/Tolak + auto-generate |
| `lib/features/layanan/providers/layanan_provider.dart` | Tambah method `verifyAndGenerateLetter`, `rejectRequest` |
| `lib/features/letters/screens/letters_screen.dart` | Verifikasi query by `resident_id` |
| `lib/app/router.dart` | Tambah route `/admin/layanan/verifikasi/:id` |

---

## Hal yang Tidak Berubah

- `LetterPdfGenerator` — tidak ada perubahan, tetap digunakan untuk generate
- `CreateLetterScreen` — tetap ada untuk pembuatan surat mandiri oleh admin
- Template isi surat per jenis — tidak ada perubahan
- Tabel `letters` — tidak ada perubahan schema
