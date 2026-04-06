# Design Spec: Panic Button & UI Overhaul
**Date:** 2026-04-05  
**Status:** 🔄 In Progress — Panic Button design approved, UI Overhaul pending  

---

## 1. Panic Button / S.O.S Darurat

### Context
Fitur ini adalah "killer feature" Rukunin untuk perumahan modern. Admin RT/RW menekan tombol darurat, sistem mengirim WA otomatis ke satpam/security.

### Requirements (Confirmed)
- **Who presses:** Admin (RT/RW role only)
- **Who receives:** Satpam/Security via WhatsApp (Fonnte)
- **Message:** Admin pilih jenis darurat dulu (Kemalingan / Kebakaran / Medis / Lainnya), pesan WA menyesuaikan
- **UI Location:** Quick Actions section di admin dashboard (`_QuickActions` widget)
- **Approach:** Opsi B — widget `_PanicActionBtn` terpisah, warna merah, berbeda dari tombol normal

### Architecture
```
Admin tap [🚨 Darurat] di Quick Actions
        ↓
BottomSheet: pilih jenis darurat
  [Kemalingan] [Kebakaran] [Medis] [Lainnya]
        ↓
Confirmation: "Kirim alert ke satpam?"
        ↓
Provider → Edge Function `send-whatsapp` (reuse existing)
        ↓
WA terkirim ke communities.security_phone
```

### Components
| Layer | Perubahan |
|---|---|
| DB | Migration baru: `ALTER TABLE communities ADD COLUMN security_phone text` |
| Settings | Tambah field "Nomor WA Satpam" di `community_settings_screen.dart` |
| Dashboard | Tambah `_PanicActionBtn` widget baru (merah) di luar `_items` list |
| Provider | Fungsi baru `sendPanicAlert(type)` di `panic_provider.dart` |
| Edge Function | Reuse `send-whatsapp` — tidak ada perubahan backend |

### Status
✅ **Design approved** — ready for implementation plan

---

## 2. UI/UX Gen Z Overhaul

### Status
⏳ **Pending** — belum mulai brainstorming section ini

### User's Wishlist (captured, belum didesign)
- **Font:** Ganti Poppins → Plus Jakarta Sans (note: theme.dart pakai Poppins, bukan PJS seperti di ARCHITECTURE.md)
- **Dark mode:** Lebih pekat, aksen neon/menyala (bukan abu-abu flat)
- **Glassmorphism:** Efek kaca blur pada card dashboard di dark mode
- **Gradient accents:** Mesh gradient redup di background dashboard
- **Gamifikasi:** Badge warga (Sultan/Kritis/Gaul), animasi confetti setelah bayar iuran
- **Social feed:** Announcements dengan reaction emoticon (🔥👍😂) + komentar
- **Micro-interactions:** Lottie untuk loading/success, flutter_animate untuk page transitions
- **Priority item:** Animasi Lottie saat success bayar iuran — ini yang paling penting sebelum Play Store

---

## Resuming This Conversation

Jika melanjutkan di sesi baru, katakan:
> "Lanjutkan brainstorming dari spec `docs/superpowers/specs/2026-04-05-panic-button-ui-overhaul-design.md` — Panic Button sudah approved, lanjut ke UI Overhaul brainstorming"

Lalu invoke `superpowers:brainstorming` skill dan `superpowers:writing-plans` untuk Panic Button.
