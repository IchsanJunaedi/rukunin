# UI Overhaul Spec A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade visual Rukunin ke Gen Z aesthetic: ganti font ke Plus Jakarta Sans, tambah neon glow tokens, glassmorphism cards di dashboard, Lottie animation untuk payment success, dan fade+slide page transitions.

**Architecture:** Token-first approach — font dan glow token ditambahkan ke `tokens.dart` agar seluruh codebase bisa pakai. `GlassCard` + `LottieSuccessDialog` ditambahkan ke `components.dart` sebagai shared widgets. Page transitions ditambahkan di satu tempat (`router.dart`). Tidak ada file baru — semua extend file yang sudah ada.

**Tech Stack:** Flutter/Dart, google_fonts (sudah ada), lottie ^3.1.0 (baru), flutter_animate ^4.5.0 (baru), dart:ui (ImageFilter — sudah ada di Flutter SDK).

---

## File Map

| Action | Path | Perubahan |
|--------|------|-----------|
| Modify | `lib/app/tokens.dart` | Tambah `RukuninFonts` class + `RukuninShadow.neonGlow` |
| Modify | `lib/app/components.dart` | Tambah `GlassCard` + `LottieSuccessDialog` |
| Modify | `pubspec.yaml` | Tambah lottie + flutter_animate dependencies + assets/lottie/ |
| Modify | semua `*.dart` di `lib/` | Replace `GoogleFonts.poppins` → `RukuninFonts.pjs` |
| Modify | `lib/features/dashboard/screens/admin_dashboard_screen.dart` | Gradient bg + GlassCard |
| Modify | `lib/features/resident_portal/screens/resident_home_screen.dart` | Gradient bg + GlassCard |
| Modify | `lib/features/resident_portal/screens/resident_invoices_screen.dart` | Lottie pada upload success |
| Modify | `lib/features/invoices/screens/invoices_screen.dart` | Lottie pada verify paid |
| Modify | `lib/app/router.dart` | `_buildPage` helper + `pageBuilder` untuk semua full-screen routes |
| Create | `assets/lottie/payment_success.json` | Download dari LottieFiles |

---

## Task 1: Tokens — `RukuninFonts` dan `neonGlow`

**Files:**
- Modify: `lib/app/tokens.dart`

- [ ] **Step 1: Tambah import google_fonts ke tokens.dart**

Di baris 1, tepat setelah `import 'package:flutter/material.dart';`, tambahkan:

```dart
import 'package:google_fonts/google_fonts.dart';
```

- [ ] **Step 2: Tambah class `RukuninFonts` di akhir file**

Di baris paling akhir `lib/app/tokens.dart` (setelah closing `}` dari `RukuninShadow`), tambahkan:

```dart
abstract class RukuninFonts {
  static TextStyle pjs({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}
```

- [ ] **Step 3: Tambah `neonGlow` ke class `RukuninShadow`**

Di `lib/app/tokens.dart`, di dalam `abstract class RukuninShadow`, tepat setelah getter `brand` (setelah baris yang berisi `];` di akhir brand getter), tambahkan:

```dart
  static List<BoxShadow> get neonGlow => [
    BoxShadow(
      color: const Color(0xFF00C853).withValues(alpha: 0.35),
      blurRadius: 18,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF00C853).withValues(alpha: 0.15),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];
```

- [ ] **Step 4: Verifikasi compile**

```bash
flutter analyze lib/app/tokens.dart
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
rtk git add lib/app/tokens.dart
rtk git commit -m "feat(tokens): add RukuninFonts helper and neonGlow shadow token"
```

---

## Task 2: Font Replacement — Poppins → Plus Jakarta Sans

**Files:**
- Modify: semua `*.dart` di `lib/` yang mengandung `GoogleFonts.poppins`

- [ ] **Step 1: Hitung jumlah file yang perlu diubah**

```bash
grep -rl "GoogleFonts.poppins" lib/ | wc -l
```

Expected: angka antara 20-40 (banyak file).

```bash
grep -r "GoogleFonts.poppins" lib/ | wc -l
```

Expected: angka yang lebih besar (total baris yang mengandung poppins).

- [ ] **Step 2: Jalankan replace di semua file**

```bash
find lib/ -name "*.dart" | xargs sed -i 's/GoogleFonts\.poppins(/RukuninFonts.pjs(/g'
```

- [ ] **Step 3: Verifikasi replace berhasil**

```bash
grep -r "GoogleFonts.poppins" lib/ | wc -l
```

Expected: `0` — tidak ada lagi `GoogleFonts.poppins`.

```bash
grep -r "RukuninFonts.pjs" lib/ | wc -l
```

Expected: angka yang sama dengan hasil Step 1 Step 2 (total baris).

- [ ] **Step 4: Pastikan import tokens.dart ada di semua file yang diubah**

Cek apakah ada file yang pakai `RukuninFonts.pjs` tapi belum import tokens.dart:

```bash
grep -rl "RukuninFonts.pjs" lib/ | xargs grep -L "tokens.dart"
```

Expected: output kosong (semua file sudah import tokens.dart karena mereka juga pakai `RukuninColors`).

Kalau ada output, tambahkan import secara manual ke file tersebut:
```dart
import '../../../app/tokens.dart'; // path menyesuaikan posisi file
```

- [ ] **Step 5: Analyze dan fix**

```bash
flutter analyze lib/
```

Kalau ada warning `unused import` untuk `google_fonts` di file tertentu, itu normal (google_fonts masih diperlukan oleh tokens.dart). Warning bukan error — tidak perlu fix.

Kalau ada **error** (bukan warning), cek apakah ada panggilan `GoogleFonts.poppins` yang punya parameter tidak dikenal oleh `RukuninFonts.pjs` — misalnya `shadows`, `decoration`, `decorationColor`. Untuk kasus seperti itu, ubah manual ke:

```dart
// Kalau ada parameter ekstra yang tidak ada di RukuninFonts.pjs:
GoogleFonts.plusJakartaSans(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  shadows: [...], // parameter ekstra tetap di sini
)
```

- [ ] **Step 6: Hot restart dan visual check**

```bash
flutter run
```

Buka admin dashboard dan resident home. Font sekarang harus terlihat lebih rounded dan modern (Plus Jakarta Sans) dibanding Poppins sebelumnya. Tidak ada UI yang broken.

- [ ] **Step 7: Commit**

```bash
rtk git add lib/
rtk git commit -m "feat(ui): replace Poppins with Plus Jakarta Sans via RukuninFonts"
```

---

## Task 3: Tambah Dependencies dan Lottie Asset

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/lottie/payment_success.json`

- [ ] **Step 1: Edit pubspec.yaml — tambah dependencies**

Di `pubspec.yaml`, dalam blok `dependencies:`, tambahkan setelah `go_router` (atau setelah dependency terakhir yang ada):

```yaml
  lottie: ^3.1.0
  flutter_animate: ^4.5.0
```

- [ ] **Step 2: Edit pubspec.yaml — tambah asset folder**

Di `pubspec.yaml`, dalam blok `flutter:` → `assets:`, tambahkan:

```yaml
    - assets/lottie/
```

Kalau belum ada blok `assets:`, tambahkan di bawah `flutter:`:
```yaml
flutter:
  assets:
    - assets/lottie/
    - .env  # .env sudah ada, jangan hapus
```

- [ ] **Step 3: Buat folder dan download asset Lottie**

```bash
mkdir -p assets/lottie
```

Download file JSON dari LottieFiles:
1. Buka browser → `lottiefiles.com/free-animations/success`
2. Cari animasi "Success Checkmark" atau "Payment Success" yang berwarna hijau
3. Download sebagai `.json` (bukan `.lottie`)
4. Simpan sebagai `assets/lottie/payment_success.json`

Alternatif URL yang diketahui bekerja dengan baik (open license):
- `lottiefiles.com/animations/success-74ejBdcMGD` — checkmark hijau minimalis

**Verifikasi file ada:**
```bash
ls -la assets/lottie/payment_success.json
```

Expected: file ada dengan ukuran antara 5KB - 100KB.

- [ ] **Step 4: flutter pub get**

```bash
flutter pub get
```

Expected: Resolving dependencies... lottie 3.x.x, flutter_animate 4.x.x muncul dalam output.

- [ ] **Step 5: Commit**

```bash
rtk git add pubspec.yaml pubspec.lock assets/lottie/payment_success.json
rtk git commit -m "feat(deps): add lottie and flutter_animate, add Lottie asset"
```

---

## Task 4: Tambah `GlassCard` dan `LottieSuccessDialog` ke components.dart

**Files:**
- Modify: `lib/app/components.dart`

- [ ] **Step 1: Tambah import `dart:ui` di bagian atas components.dart**

Di `lib/app/components.dart`, tepat setelah baris `import 'package:flutter/services.dart';` (baris 2), tambahkan:

```dart
import 'dart:ui';
import 'package:lottie/lottie.dart';
```

- [ ] **Step 2: Tambah `GlassCard` widget**

Di `lib/app/components.dart`, di bagian paling akhir file (setelah widget terakhir yang ada), tambahkan:

```dart
// ── GLASS CARD ────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: const Color(0xFF00C853).withValues(alpha: 0.22),
                  width: 1.0,
                ),
                boxShadow: RukuninShadow.neonGlow,
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    // Light mode: plain surface without blur
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: RukuninColors.lightSurface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: RukuninColors.brandGreen.withValues(alpha: 0.12),
            width: 1.0,
          ),
          boxShadow: RukuninShadow.sm,
        ),
        child: child,
      ),
    );
  }
}

// ── LOTTIE SUCCESS DIALOG ─────────────────────────────────────────────────────

class LottieSuccessDialog extends StatefulWidget {
  final String message;
  const LottieSuccessDialog({super.key, required this.message});

  @override
  State<LottieSuccessDialog> createState() => _LottieSuccessDialogState();
}

class _LottieSuccessDialogState extends State<LottieSuccessDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/lottie/payment_success.json',
            width: 180,
            repeat: false,
            onLoaded: (comp) {
              Future.delayed(
                comp.duration + const Duration(milliseconds: 400),
                () {
                  if (context.mounted) Navigator.of(context).pop();
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: RukuninFonts.pjs(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verifikasi compile**

```bash
flutter analyze lib/app/components.dart
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
rtk git add lib/app/components.dart
rtk git commit -m "feat(components): add GlassCard with glassmorphism and LottieSuccessDialog"
```

---

## Task 5: Admin Dashboard — Gradient Background + GlassCard

**Files:**
- Modify: `lib/features/dashboard/screens/admin_dashboard_screen.dart`

- [ ] **Step 1: Bungkus body dengan Stack untuk gradient background**

Di method `build` dari `AdminDashboardScreen` (sekitar baris 76-91), ubah:

```dart
// SEBELUM:
body: data.when(
  loading: () => _buildSkeleton(context),
  error: (e, _) => Center(...),
  data: (d) => _buildContent(context, ref, d),
),

// SESUDAH:
body: Stack(
  children: [
    Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.8),
            radius: 1.2,
            colors: [
              const Color(0xFF00C853).withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ),
    data.when(
      loading: () => _buildSkeleton(context),
      error: (e, _) => Center(
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Gagal memuat data',
          description: e.toString(),
          ctaLabel: 'Coba lagi',
          onCta: () => ref.invalidate(dashboardProvider),
        ),
      ),
      data: (d) => _buildContent(context, ref, d),
    ),
  ],
),
```

- [ ] **Step 2: Ganti `_KasHeroCard` container dengan `GlassCard`**

Di class `_KasHeroCard` (sekitar baris 316-421), ubah:

```dart
// SEBELUM:
return Container(
  padding: const EdgeInsets.all(22),
  decoration: BoxDecoration(
    color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
      width: 0.5,
    ),
    boxShadow: RukuninShadow.sm,
  ),
  child: Column(
    ...
  ),
);

// SESUDAH:
return GlassCard(
  padding: const EdgeInsets.all(22),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // isi Column yang sama, tidak berubah
      ...
    ],
  ),
);
```

Hapus baris `final isDark = Theme.of(context).brightness == Brightness.dark;` dari `_KasHeroCard._build` HANYA jika `isDark` tidak lagi dipakai di dalam Column. Kalau masih dipakai (untuk warna teks progress bar), biarkan saja.

- [ ] **Step 3: Ganti `_CommunityCodeTile` dari SurfaceCard ke GlassCard**

Di class `_CommunityCodeTile` (sekitar baris 436), ubah:

```dart
// SEBELUM:
return SurfaceCard(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  child: Row(...),
);

// SESUDAH:
return GlassCard(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  borderRadius: 16,
  child: Row(
    // isi Row yang sama, tidak berubah
    ...
  ),
);
```

- [ ] **Step 4: Ganti `_DashStatCard` container dengan `GlassCard`**

Di class `_DashStatCard` (sekitar baris 556-638), ubah outer Container:

```dart
// SEBELUM:
return Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: RukuninColors.brandGreen.withValues(alpha: isDark ? 0.22 : 0.14),
      width: 1.0,
    ),
    boxShadow: isDark ? [...] : [...],
  ),
  child: Column(...),
);

// SESUDAH:
return GlassCard(
  padding: const EdgeInsets.all(16),
  borderRadius: 18,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // isi Column yang sama, tidak berubah
      ...
    ],
  ),
);
```

Hapus variabel `isDark` dari `_DashStatCard.build()` jika tidak ada lagi yang menggunakannya setelah replace. Kalau masih dipakai di icon container styling, biarkan.

- [ ] **Step 5: Wrap `_QuickActions` GridView dengan GlassCard**

Di class `_QuickActions.build()` (sekitar baris 657), ubah:

```dart
// SEBELUM:
return GridView.count(
  crossAxisCount: 4,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisSpacing: 10,
  mainAxisSpacing: 14,
  childAspectRatio: 0.85,
  children: _items
      .map((a) => _ActionBtn(icon: a.$1, label: a.$2, route: a.$3))
      .toList(),
);

// SESUDAH:
return GlassCard(
  padding: const EdgeInsets.all(12),
  child: GridView.count(
    crossAxisCount: 4,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 14,
    childAspectRatio: 0.85,
    children: _items
        .map((a) => _ActionBtn(icon: a.$1, label: a.$2, route: a.$3))
        .toList(),
  ),
);
```

- [ ] **Step 6: Verifikasi compile**

```bash
flutter analyze lib/features/dashboard/screens/admin_dashboard_screen.dart
```

Expected: No errors.

- [ ] **Step 7: Visual check**

```bash
flutter run
```

Buka admin dashboard di dark mode:
- [ ] Background ada subtle green radial gradient di pojok kiri atas
- [ ] KasHeroCard punya efek glass (background sedikit transparent, green border, glow)
- [ ] 4 stat cards punya efek glass
- [ ] CommunityCodeTile punya efek glass
- [ ] Quick Actions section punya glass background
- [ ] Light mode: cards tetap white surface tanpa blur

- [ ] **Step 8: Commit**

```bash
rtk git add lib/features/dashboard/screens/admin_dashboard_screen.dart
rtk git commit -m "feat(dashboard): add glassmorphism cards and gradient background"
```

---

## Task 6: Resident Home — Gradient Background + GlassCard

**Files:**
- Modify: `lib/features/resident_portal/screens/resident_home_screen.dart`

- [ ] **Step 1: Bungkus body dengan Stack**

Di `ResidentHomeScreen.build()`, ubah:

```dart
// SEBELUM:
body: RefreshIndicator(
  color: RukuninColors.brandGreen,
  onRefresh: () async {
    ref.invalidate(currentResidentProfileProvider);
    ref.invalidate(residentInvoicesProvider);
  },
  child: CustomScrollView(...),
),

// SESUDAH:
body: Stack(
  children: [
    Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.8),
            radius: 1.2,
            colors: [
              const Color(0xFF00C853).withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ),
    RefreshIndicator(
      color: RukuninColors.brandGreen,
      onRefresh: () async {
        ref.invalidate(currentResidentProfileProvider);
        ref.invalidate(residentInvoicesProvider);
      },
      child: CustomScrollView(
        // isi yang sama, tidak berubah
        ...
      ),
    ),
  ],
),
```

- [ ] **Step 2: Ganti `_TagihanHeroCard` container dengan GlassCard**

Di class `_TagihanHeroCard` (sekitar baris 178), ubah:

```dart
// SEBELUM:
return Container(
  padding: const EdgeInsets.all(22),
  decoration: BoxDecoration(
    color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: lunas
          ? RukuninColors.success.withValues(alpha: 0.3)
          : RukuninColors.warning.withValues(alpha: 0.3),
      width: 0.5,
    ),
    boxShadow: RukuninShadow.sm,
  ),
  child: Column(...),
);

// SESUDAH:
return GlassCard(
  padding: const EdgeInsets.all(22),
  child: Column(
    // isi Column yang sama, tidak berubah
    ...
  ),
);
```

- [ ] **Step 2b: Ganti `_KasBanner` dari SurfaceCard ke GlassCard**

Di class `_KasBanner` (sekitar baris 280), ubah:

```dart
// SEBELUM:
return SurfaceCard(
  onTap: onTap,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  child: Row(...),
);

// SESUDAH:
return GlassCard(
  onTap: onTap,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  borderRadius: 16,
  child: Row(
    // isi Row yang sama, tidak berubah
    ...
  ),
);
```

`_InvoiceItem` (yang pakai `SurfaceCard` dengan `accentColor`) dibiarkan — tidak diganti karena GlassCard tidak punya `accentColor` parameter, dan list item tidak perlu glassmorphism.

- [ ] **Step 3: Verifikasi compile**

```bash
flutter analyze lib/features/resident_portal/screens/resident_home_screen.dart
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
rtk git add lib/features/resident_portal/screens/resident_home_screen.dart
rtk git commit -m "feat(resident): add glassmorphism and gradient background to resident home"
```

---

## Task 7: Lottie pada Resident Upload Bukti Bayar

**Files:**
- Modify: `lib/features/resident_portal/screens/resident_invoices_screen.dart`

- [ ] **Step 1: Tambah import components.dart ke resident_invoices_screen.dart**

`components.dart` sudah diimport (baris 7). Verifikasi:

```bash
grep "components.dart" lib/features/resident_portal/screens/resident_invoices_screen.dart
```

Expected: ada baris `import '../../../app/components.dart';`. Kalau sudah ada, tidak perlu tambah.

- [ ] **Step 2: Ubah success callback di `_uploadProof`**

Di class `_InvoiceListBuilderState` (sekitar baris 114-135), ubah blok `if (pickedFile != null)`:

```dart
// SEBELUM:
if (pickedFile != null) {
  setState(() => _isUploading = true);
  final bytes = await pickedFile.readAsBytes();
  await ref.read(uploadPaymentProofProvider).uploadProof(invoiceId, bytes, pickedFile.name);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bukti pembayaran berhasil diunggah! Menunggu verifikasi RT.')),
    );
  }
}

// SESUDAH:
if (pickedFile != null) {
  setState(() => _isUploading = true);
  final bytes = await pickedFile.readAsBytes();
  await ref.read(uploadPaymentProofProvider).uploadProof(invoiceId, bytes, pickedFile.name);
  if (mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LottieSuccessDialog(
        message: 'Bukti pembayaran terkirim!\nMenunggu verifikasi admin.',
      ),
    );
  }
}
```

- [ ] **Step 3: Verifikasi compile**

```bash
flutter analyze lib/features/resident_portal/screens/resident_invoices_screen.dart
```

Expected: No errors.

- [ ] **Step 4: Visual check**

```bash
flutter run
```

Login sebagai resident → Tagihan → tap invoice yang belum bayar → pilih upload bukti bayar → pilih foto → setelah upload: dialog Lottie muncul dengan animasi success dan text "Bukti pembayaran terkirim! Menunggu verifikasi admin." → dialog auto-dismiss setelah animasi selesai.

- [ ] **Step 5: Commit**

```bash
rtk git add lib/features/resident_portal/screens/resident_invoices_screen.dart
rtk git commit -m "feat(payment): add Lottie success animation on proof upload"
```

---

## Task 8: Lottie pada Admin Verifikasi Pembayaran

**Files:**
- Modify: `lib/features/invoices/screens/invoices_screen.dart`

- [ ] **Step 1: Pastikan components.dart sudah diimport**

```bash
grep "components.dart" lib/features/invoices/screens/invoices_screen.dart
```

Kalau belum ada, tambahkan import di baris atas:
```dart
import '../../../app/components.dart';
```

- [ ] **Step 2: Ubah success callback "Konfirmasi Lunas ✓"**

Di `invoices_screen.dart`, cari baris sekitar 365-375 (onPressed handler untuk "Konfirmasi Lunas"). Ubah:

```dart
// SEBELUM:
onPressed: () async {
  Navigator.pop(ctx);
  try {
    await ref.read(invoiceListProvider.notifier).markInvoiceAsPaid(invoice['id'].toString());
    ref.invalidate(invoiceWithResidentProvider);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tagihan berhasil ditandai lunas!'), backgroundColor: RukuninColors.success)
    );
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal: $e'))
    );
  }
},

// SESUDAH:
onPressed: () async {
  Navigator.pop(ctx);
  try {
    await ref.read(invoiceListProvider.notifier).markInvoiceAsPaid(invoice['id'].toString());
    ref.invalidate(invoiceWithResidentProvider);
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LottieSuccessDialog(
          message: 'Pembayaran terverifikasi!',
        ),
      );
    }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal: $e'))
    );
  }
},
```

- [ ] **Step 3: Verifikasi compile**

```bash
flutter analyze lib/features/invoices/screens/invoices_screen.dart
```

Expected: No errors.

- [ ] **Step 4: Visual check**

```bash
flutter run
```

Login sebagai admin → Tagihan → tap invoice yang `awaiting_verification` → tap "Konfirmasi Lunas ✓" → Lottie dialog muncul → auto-dismiss → invoice di list berubah status.

- [ ] **Step 5: Commit**

```bash
rtk git add lib/features/invoices/screens/invoices_screen.dart
rtk git commit -m "feat(invoices): add Lottie success animation on payment verification"
```

---

## Task 9: Page Transitions di Router

**Files:**
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Tambah import `CustomTransitionPage` (sudah ada via go_router)**

Verifikasi go_router sudah diimport:
```bash
grep "go_router" lib/app/router.dart | head -3
```

Expected: ada baris `import 'package:go_router/go_router.dart';`. `CustomTransitionPage` adalah bagian dari go_router — tidak perlu import tambahan.

- [ ] **Step 2: Tambah helper `_buildPage` di level file**

Di `lib/app/router.dart`, tepat setelah semua baris `import ...` (sebelum deklarasi `final _rootNavigatorKey`), tambahkan:

```dart
CustomTransitionPage<void> _buildPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}
```

- [ ] **Step 3: Ganti `builder:` dengan `pageBuilder:` untuk semua routes di luar ShellRoute**

Berikut adalah **daftar lengkap** semua route di luar ShellRoute yang perlu diubah. Ganti satu per satu:

```dart
// 1. /login
GoRoute(
  path: '/login',
  pageBuilder: (context, state) => _buildPage(state: state, child: const LoginScreen()),
),

// 2. /register/admin
GoRoute(
  path: '/register/admin',
  pageBuilder: (context, state) => _buildPage(state: state, child: const RegisterAdminScreen()),
),

// 3. /register/resident
GoRoute(
  path: '/register/resident',
  pageBuilder: (context, state) => _buildPage(state: state, child: const RegisterResidentScreen()),
),

// 4. /pending-approval
GoRoute(
  path: '/pending-approval',
  pageBuilder: (context, state) => _buildPage(state: state, child: const PendingApprovalScreen()),
),

// 5. /forgot-password
GoRoute(
  path: '/forgot-password',
  pageBuilder: (context, state) => _buildPage(state: state, child: const ForgotPasswordScreen()),
),

// 6. /reset-password
GoRoute(
  path: '/reset-password',
  pageBuilder: (context, state) => _buildPage(state: state, child: const ResetPasswordScreen()),
),

// 7. /register/resident/step2
GoRoute(
  path: '/register/resident/step2',
  pageBuilder: (context, state) => _buildPage(
    state: state,
    child: RegisterResidentStep2Screen(step1Data: state.extra as RegisterStep1Data),
  ),
),

// 8. /bantuan
GoRoute(
  path: '/bantuan',
  pageBuilder: (context, state) => _buildPage(state: state, child: const HelpCenterScreen()),
),

// 9. /admin/profil
GoRoute(
  path: '/admin/profil',
  pageBuilder: (context, state) => _buildPage(state: state, child: const AdminProfileScreen()),
),

// 10. /admin/riwayat-pembayaran
GoRoute(
  path: '/admin/riwayat-pembayaran',
  pageBuilder: (context, state) => _buildPage(state: state, child: const PaymentsScreen()),
),

// 11. /admin/pengaturan-rek
GoRoute(
  path: '/admin/pengaturan-rek',
  pageBuilder: (context, state) => _buildPage(state: state, child: const PaymentSettingsScreen()),
),

// 12. /admin/warga/detail
GoRoute(
  path: '/admin/warga/detail',
  pageBuilder: (context, state) => _buildPage(
    state: state,
    child: ResidentDetailScreen(resident: state.extra as ResidentModel),
  ),
),

// 13. /admin/warga/tambah
GoRoute(
  path: '/admin/warga/tambah',
  pageBuilder: (context, state) => _buildPage(state: state, child: const AddEditResidentScreen()),
),

// 14. /admin/warga/edit
GoRoute(
  path: '/admin/warga/edit',
  pageBuilder: (context, state) => _buildPage(
    state: state,
    child: AddEditResidentScreen(resident: state.extra as ResidentModel),
  ),
),

// 15. /resident/notifikasi
GoRoute(
  path: '/resident/notifikasi',
  pageBuilder: (context, state) => _buildPage(state: state, child: const NotificationsScreen()),
),

// 16. /admin/notifikasi
GoRoute(
  path: '/admin/notifikasi',
  pageBuilder: (context, state) => _buildPage(state: state, child: const NotificationsScreen()),
),

// 17. /resident/kas
GoRoute(
  path: '/resident/kas',
  pageBuilder: (context, state) => _buildPage(state: state, child: const ResidentKasScreen()),
),

// 18. /resident/marketplace/tambah
GoRoute(
  path: '/resident/marketplace/tambah',
  pageBuilder: (context, state) => _buildPage(state: state, child: const AddListingScreen()),
),

// 19. /resident/marketplace/detail
GoRoute(
  path: '/resident/marketplace/detail',
  pageBuilder: (context, state) => _buildPage(
    state: state,
    child: ListingDetailScreen(listing: state.extra as MarketplaceListingModel),
  ),
),

// 20. /admin/layanan-requests
GoRoute(
  path: '/admin/layanan-requests',
  pageBuilder: (context, state) => _buildPage(state: state, child: const AdminRequestsScreen()),
),

// 21. /admin/layanan-verifikasi/:id
GoRoute(
  path: '/admin/layanan-verifikasi/:id',
  pageBuilder: (context, state) => _buildPage(
    state: state,
    child: VerifyRequestScreen(request: state.extra as LetterRequestModel),
  ),
),

// 22. /admin/pengaduan
GoRoute(
  path: '/admin/pengaduan',
  pageBuilder: (context, state) => _buildPage(state: state, child: const AdminComplaintsScreen()),
),

// 23. /admin/layanan/kontak
GoRoute(
  path: '/admin/layanan/kontak',
  pageBuilder: (context, state) => _buildPage(state: state, child: const AdminContactsScreen()),
),

// 24. /resident/dokumen-saya
GoRoute(
  path: '/resident/dokumen-saya',
  pageBuilder: (context, state) => _buildPage(state: state, child: const ResidentLettersScreen()),
),

// 25. /resident/layanan/permohonan
GoRoute(
  path: '/resident/layanan/permohonan',
  pageBuilder: (context, state) {
    final type = state.uri.queryParameters['type'];
    return _buildPage(state: state, child: RequestLetterScreen(initialType: type));
  },
),

// 26. /resident/layanan/pengaduan-baru
GoRoute(
  path: '/resident/layanan/pengaduan-baru',
  pageBuilder: (context, state) => _buildPage(state: state, child: const ComplaintFormScreen()),
),

// 27. /admin/polling
GoRoute(
  path: '/admin/polling',
  pageBuilder: (context, state) => _buildPage(state: state, child: const PollsAdminScreen()),
),

// 28. /admin/polling/buat
GoRoute(
  path: '/admin/polling/buat',
  pageBuilder: (context, state) => _buildPage(state: state, child: const CreatePollScreen()),
),

// 29. /admin/polling/:id
GoRoute(
  path: '/admin/polling/:id',
  pageBuilder: (context, state) => _buildPage(
    state: state,
    child: PollDetailAdminScreen(pollId: state.pathParameters['id']!),
  ),
),

// 30. /resident/polling/:id
GoRoute(
  path: '/resident/polling/:id',
  pageBuilder: (context, state) => _buildPage(
    state: state,
    child: PollVoteScreen(pollId: state.pathParameters['id']!),
  ),
),
```

**Routes DALAM ShellRoute** (`/admin`, `/admin/warga`, `/admin/tagihan`, dll.) **tetap menggunakan `builder:`** — jangan diubah.

- [ ] **Step 4: Verifikasi compile**

```bash
flutter analyze lib/app/router.dart
```

Expected: No errors.

- [ ] **Step 5: Visual check**

```bash
flutter run
```

- [ ] Navigasi dari login ke dashboard: ada fade + slight slide-up
- [ ] Buka "Profil Warga" dari list: fade + slide
- [ ] Tap back: transisi reverse lebih cepat (220ms)
- [ ] Tab switching (bottom nav) tidak punya transisi — ini benar, biarkan

- [ ] **Step 6: Commit**

```bash
rtk git add lib/app/router.dart
rtk git commit -m "feat(router): add fade+slide page transitions for all full-screen routes"
```

---

## Scope Check

| Requirement dari spec | Task |
|----------------------|------|
| Font PJS via `RukuninFonts.pjs()` helper | Task 1 + Task 2 |
| `neonGlow` shadow token | Task 1 |
| `GlassCard` widget | Task 4 |
| `LottieSuccessDialog` widget | Task 4 |
| Gradient background admin dashboard | Task 5 |
| Glassmorphism semua cards dashboard | Task 5 |
| Gradient background resident home | Task 6 |
| GlassCard resident home | Task 6 |
| Lottie resident upload bukti bayar | Task 7 |
| Lottie admin konfirmasi lunas | Task 8 |
| Page transitions semua full-screen routes | Task 9 |
| lottie + flutter_animate di pubspec | Task 3 |
| `assets/lottie/` terdaftar di pubspec | Task 3 |

Semua requirement tercakup. Tidak ada TBD atau placeholder.
