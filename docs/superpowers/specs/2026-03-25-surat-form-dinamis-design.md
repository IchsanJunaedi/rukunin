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

## Catatan Teknis Penting

- Kolom `rt_number` **ada** di tabel `communities` (ditambah via `20260311_add_location_fields.sql`). `CreateLetterScreen` yang ada memang hardcode `'01'` karena tidak meng-include kolom ini di SELECT-nya — itu adalah bug yang harus diperbaiki di implementasi baru. Query fetch komunitas di `verifyAndGenerateLetter` harus include `rt_number`.
- Kolom `purpose` di `letter_requests` tetap diisi dari `form_data.keperluan` saat submit, agar backward compatible dengan `_RequestCard` yang menampilkan `request.purpose` sebagai subtitle.

---

## Pendekatan

**Approach yang dipilih: `form_data` JSONB di `letter_requests`**

Menyimpan semua field dinamis per jenis surat dalam satu kolom JSONB. Fleksibel untuk field unik per jenis surat (SKU punya `nama_usaha`/`alamat_usaha`, kematian punya `nama_almarhum`, dll.) tanpa perlu migration besar.

---

## 1. Database Schema

### Migration baru

```sql
-- Tambah kolom baru
ALTER TABLE letter_requests
  ADD COLUMN form_data JSONB,
  ADD COLUMN applicant_name TEXT;

-- Ganti CHECK constraint status (drop lama, tambah baru)
ALTER TABLE letter_requests
  DROP CONSTRAINT letter_requests_status_check;

ALTER TABLE letter_requests
  ADD CONSTRAINT letter_requests_status_check
  CHECK (status IN ('pending', 'verified', 'completed', 'rejected'));
```

- `form_data` — menyimpan semua field yang warga isi, format JSON per jenis surat
- `applicant_name` — nama yang tampil di header PDF. Untuk semua jenis surat selain `kematian`, diisi dari `profiles.full_name` saat warga submit. Untuk `kematian`, diisi dari `form_data.nama_almarhum` karena subjek surat adalah almarhum, bukan pemohon.

### Status flow baru

| Status | Keterangan |
|---|---|
| `pending` | Warga baru submit, admin belum verifikasi |
| `verified` | Admin ACC, surat sudah ter-generate, warga bisa lihat dokumen |
| `rejected` | Admin tolak, ada alasan penolakan |
| `completed` | Warga sudah mengambil dokumen fisik (opsional, bisa di-skip) |

Status `in_progress` dan `ready` dihapus karena tidak relevan dengan flow baru.

Request dengan status `verified` dianggap **aktif** (`isActive = true`) karena warga masih perlu mengakses dokumennya.

### Contoh `form_data` per jenis surat

```json
// custom
{
  "keperluan": "Keperluan administrasi bank"
}

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

// sktm — "alasan" menjadi "purpose" saat dipassing ke LetterPdfGenerator.getTemplate()
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

// kematian — applicant_name diisi dari nama_almarhum, bukan dari profile pemohon
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

Field per jenis surat. TTL selalu dalam format `"Kota, DD-MM-YYYY"` (contoh: `"Jakarta, 01-01-1990"`).

| Jenis Surat | Field | Catatan |
|---|---|---|
| Domisili | NIK, TTL, Gender, Agama, Keperluan | — |
| KTP/KK | NIK, Alasan (dropdown: KTP baru/hilang/rusak/perpanjangan, KK baru/perbaikan data), Keterangan | Tidak ada gender/TTL, gunakan `-` untuk `residentGender` dan `residentAge` saat generate |
| SKCK | NIK, TTL, Gender, Agama, Status Perkawinan, Pekerjaan, Keperluan | — |
| SKTM | NIK, No KK, Alasan Kebutuhan (dropdown: pendidikan/kesehatan/lainnya), Pernyataan Kondisi | Tidak ada gender, gunakan `-` untuk `residentGender`. Alasan → `purpose` saat generate |
| SKU | NIK, TTL, Gender, Nama Usaha, Jenis Usaha, Alamat Usaha, Keperluan | — |
| Nikah | NIK, TTL, Gender, Pekerjaan, Nama Ayah, Nama Ibu | — |
| Kematian | Nama Almarhum, NIK Almarhum, TTL Almarhum, Tanggal Meninggal, Penyebab, Hubungan Pelapor | Tidak ada field gender almarhum, gunakan `-`. TTL Almarhum juga format `"Kota, DD-MM-YYYY"` |
| Custom | Keperluan (teks bebas) | — |

**Step 3 — Review & Kirim**
- Tampil ringkasan semua data yang diisi
- Tombol edit untuk kembali ke step 2
- Tombol kirim untuk submit

Setelah submit:
- `applicant_name` di-set: untuk `kematian` gunakan `form_data.nama_almarhum`, untuk lainnya gunakan `profiles.full_name`
- `purpose` di-set dari `form_data.keperluan` (atau `form_data.alasan` untuk `sktm`, null untuk `kematian`) agar backward compatible dengan tampilan subtitle di `_RequestCard`
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

Tombol "Buat Surat" per card diganti "Verifikasi". Filter chips diupdate ke status baru: `semua`, `pending`, `verified`, `completed`, `rejected`.

Widget `_UpdateStatusSheet` dihapus — perubahan status sekarang hanya melalui `VerifyRequestScreen` (ACC atau Tolak), tidak ada update status manual lagi.

### VerifyRequestScreen (baru, route: `/admin/layanan-verifikasi/:id`)

Screen full yang menampilkan:
- Data profil warga (nama, unit) dari `profiles`
- Semua data dari `form_data` dalam tampilan read-only, dikelompokkan per kategori
- Jenis surat yang dimohon

Route mengikuti konvensi yang sudah ada: `/admin/layanan-verifikasi/:id` (dengan hyphen, bukan nested slash).

**Aksi Tolak:**
- Admin isi alasan penolakan (wajib)
- Status update ke `rejected` dengan `admin_notes` berisi alasan
- Panggil `ref.invalidate(adminLetterRequestsProvider)` dan `ref.invalidate(myLetterRequestsProvider)` setelah mutasi
- Warga dapat notifikasi

**Aksi ACC & Generate Surat:**

Mapping `form_data` ke parameter `LetterPdfGenerator.getTemplate()`:

| Parameter `getTemplate()` | Sumber |
|---|---|
| `residentName` | `letter_requests.applicant_name` |
| `residentNik` | `form_data.nik` — untuk `kematian`: `form_data.nik_almarhum` |
| `residentAge` | Hitung dari TTL: split `','` → ambil bagian kanan → split `'-'` → parse `DD-MM-YYYY` → hitung selisih tahun. Untuk `kematian`: gunakan `form_data.ttl_almarhum`. Untuk `ktp_kk`/`sktm`/`custom` yang tidak punya TTL: gunakan `'-'`. Pola parsing identik dengan `CreateLetterScreen` lines 138-148 |
| `residentGender` | `form_data.gender` — untuk `ktp_kk`, `sktm`, `kematian`, `custom` yang tidak punya `gender`: gunakan `'-'` |
| `residentAddress` | Dikonstruksi dari data komunitas: `"RT {rt_number}/RW {rw_number}, Kel. {kelurahan}, Kec. {kecamatan}, {kabupaten}"` |
| `rtNumber` | `community.rt_number` (kolom ini ada di tabel `communities`, bukan hardcode `'01'`) |
| `rwNumber` | `community.rw_number` |
| `village` | `community.kelurahan` |
| `district` | `community.kecamatan` |
| `city` | `community.kabupaten` |
| `purpose` | `form_data.keperluan` untuk domisili/skck/sku/nikah/ktp_kk/custom. Untuk `sktm`: `form_data.alasan`. Untuk `kematian`: `null` |

Langkah-langkah saat ACC:
1. Fetch data komunitas dari `communities` menggunakan `community_id` admin. Kolom yang di-select: `name, rt_number, rw_number, kelurahan, kecamatan, kabupaten, province, leader_name`
2. Panggil `LetterPdfGenerator.getTemplate()` dengan mapping di atas
3. Generate nomor surat (pola yang sudah ada di `CreateLetterScreen`: `{ms%1000}/RW-{rw}/{bulanRomawi}/{tahun}`)
4. Insert ke tabel `letters` dengan `generated_content`, `resident_id` = `letter_requests.resident_id`, `community_id` = admin's community_id
5. Update `letter_requests.status` = `verified`, `letter_id` = ID surat baru. Scope update dengan `.eq('id', requestId).eq('community_id', communityId)` untuk keamanan
6. `ref.invalidate(adminLetterRequestsProvider)` dan `ref.invalidate(myLetterRequestsProvider)`
7. Notifikasi warga dengan body: `"Surat {typeLabel} kamu sudah diverifikasi dan siap diunduh."`

Admin masih bisa download/share PDF dari halaman letters yang sudah ada untuk dikirim manual via WA.

### CreateLetterScreen

Tetap dipertahankan untuk kebutuhan admin membuat surat mandiri (tanpa permohonan dari warga). Tidak ada perubahan di screen ini.

---

## 4. Resident View Dokumen

### resident_letters_screen.dart (buat baru)

Halaman "Dokumen Saya" di resident side **belum ada** — `letters_screen.dart` yang ada adalah halaman admin. Perlu dibuat screen baru.

Provider baru `myLettersProvider` (di `letter_provider.dart`):
```dart
final myLettersProvider = FutureProvider.autoDispose<List<LetterModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser!.id;
  final data = await client
      .from('letters')
      .select()
      .eq('resident_id', userId)
      .order('created_at', ascending: false);
  return data.map(LetterModel.fromMap).toList();
});
```

Tampilan per dokumen:
- Jenis surat dan nomor surat
- Tanggal dibuat
- Tombol Unduh PDF — generate PDF on-the-fly dari `generated_content` yang tersimpan, menggunakan `LetterPdfGenerator.generate()` yang sudah ada

Screen ini **tidak** masuk ke ResidentShell tab (tab sudah ada 6). Dideklarasikan sebagai full-screen route di luar ShellRoute, dengan path `/resident/dokumen-saya`. Akses masuk dari:
- Shortcut "Lihat Dokumen" saat status `verified` di layanan screen
- Bisa juga ditambahkan sebagai link di `resident_home_screen.dart` jika diperlukan

RLS di Supabase sudah scope per `resident_id` — filter `community_id` tidak wajib di client query, tapi boleh ditambahkan untuk defense-in-depth.

---

## 5. Perubahan Model

### LetterRequestModel

Tambah field:
- `formData` (`Map<String, dynamic>?`) — dari kolom `form_data`
- `applicantName` (`String?`) — dari kolom `applicant_name`

Update:
- `letterRequestStatusLabels` — ganti `in_progress`/`ready` dengan `verified`
- `progressPercent` getter — tambah case `'verified': 0.9`
- `isActive` getter — sudah benar, `verified` masuk kategori aktif karena tidak exclude `verified`

---

## 6. Perubahan File

| File | Perubahan |
|---|---|
| `supabase/migrations/` | Migration baru: tambah `form_data`, `applicant_name`, drop + replace CHECK constraint status |
| `lib/features/layanan/models/letter_request_model.dart` | Tambah `formData`, `applicantName`; update status labels; update `progressPercent` |
| `lib/features/layanan/screens/request_letter_screen.dart` | Redesign total: multi-step form dinamis per jenis surat |
| `lib/features/layanan/screens/admin_requests_screen.dart` | Ganti tombol "Buat Surat" jadi "Verifikasi"; update filter chips ke status baru; hapus `_UpdateStatusSheet` |
| `lib/features/layanan/screens/layanan_screen.dart` | Update `_statusColor()` dan `_StatusBadge._label` untuk handle status `verified` |
| `lib/features/layanan/screens/verify_request_screen.dart` | Buat baru: tampil data warga + aksi ACC/Tolak + auto-generate |
| `lib/features/layanan/providers/layanan_provider.dart` | Tambah method `verifyAndGenerateLetter`, `rejectRequest`; invalidate kedua provider setelah mutasi |
| `lib/features/letters/providers/letter_provider.dart` | Tambah `myLettersProvider` yang filter by `resident_id` |
| `lib/features/letters/screens/resident_letters_screen.dart` | Buat baru: halaman "Dokumen Saya" untuk resident |
| `lib/app/router.dart` | Tambah route `/admin/layanan-verifikasi/:id` (di luar ShellRoute, pattern sama dengan `/admin/layanan-requests`); tambah route `/resident/dokumen-saya` (di luar ResidentShell) |

---

## Hal yang Tidak Berubah

- `LetterPdfGenerator` — tidak ada perubahan pada class ini
- `CreateLetterScreen` — tetap ada untuk pembuatan surat mandiri oleh admin
- Template isi surat per jenis — tidak ada perubahan
- Tabel `letters` — tidak ada perubahan schema
