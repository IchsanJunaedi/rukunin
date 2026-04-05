# Design Spec: UI/UX Gen Z Overhaul — Spec A (Visual Theme + Lottie)
**Date:** 2026-04-05
**Status:** ✅ Design approved — ready for implementation plan

---

## Overview

Overhaul visual Rukunin untuk kesan premium dan modern sebelum launch ke Play Store. Fokus pada tiga area: (1) typography dan dark mode tokens, (2) glassmorphism + gradient di dashboard, (3) Lottie animation pada payment success, dan (4) flutter_animate page transitions.

**Tidak termasuk di Spec A:** badge gamifikasi, confetti bayar iuran, reactions/komentar di announcements — semua itu masuk Spec B (post-launch).

---

## 1. Font & Color Tokens

### Font: Plus Jakarta Sans (PJS) everywhere

Semua `GoogleFonts.poppins(...)` di seluruh codebase diganti dengan `GoogleFonts.plusJakartaSans(...)`.

Cara implementasi: tambah helper class `RukuninFonts` di `lib/app/tokens.dart`, lalu find & replace semua kemunculan `GoogleFonts.poppins` → `RukuninFonts.pjs`.

```dart
// lib/app/tokens.dart
class RukuninFonts {
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

Headline (fontSize ≥ 20, fontWeight ≥ 700) otomatis mendapat karakter PJS bold-tight yang terlihat premium — tidak perlu font terpisah. Semua parameter yang ada di `GoogleFonts.poppins(...)` dipindahkan ke `RukuninFonts.pjs(...)` tanpa perubahan nilai.

### Neon Glow Tokens (dark mode only)

Tambahkan ke `RukuninShadow` di `lib/app/tokens.dart`:

```dart
// lib/app/tokens.dart — tambahkan di class RukuninShadow
static List<BoxShadow> get neonGlow => [
  BoxShadow(
    color: Color(0xFF00C853).withValues(alpha: 0.35),
    blurRadius: 18,
    spreadRadius: 0,
  ),
  BoxShadow(
    color: Color(0xFF00C853).withValues(alpha: 0.15),
    blurRadius: 40,
    spreadRadius: 4,
  ),
];
```

Dipakai sebagai pengganti `boxShadow: RukuninShadow.sm` pada icon containers dan card borders **di dark mode saja** (`if (isDark) RukuninShadow.neonGlow else RukuninShadow.sm`).

---

## 2. Glassmorphism + Dashboard Background

### Prasyarat: Gradient Background

Glassmorphism (`BackdropFilter`) butuh layer di belakangnya untuk di-blur. Kita tambahkan gradient background pada `AdminDashboardScreen` dan `ResidentHomeScreen` menggunakan `Stack`:

```dart
// Membungkus CustomScrollView dengan Stack
Stack(
  children: [
    // Layer 1: Mesh gradient background (fixed, tidak ikut scroll)
    Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.8),
            radius: 1.2,
            colors: [
              Color(0xFF00C853).withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ),
    // Layer 2: Konten scroll
    CustomScrollView(...),
  ],
)
```

Di light mode, gradient alpha cukup rendah (0.08) sehingga tetap subtle. Di dark mode, kontrasnya lebih terasa.

### `GlassCard` Widget Baru

Tambahkan `GlassCard` ke `lib/app/components.dart`. Di light mode berperilaku identik dengan `SurfaceCard`. Di dark mode mengaktifkan `BackdropFilter` blur:

```dart
// lib/app/components.dart
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

    if (!isDark) {
      return SurfaceCard(padding: padding, onTap: onTap, child: child);
    }

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
}
```

### Penerapan di Dashboard

Card yang diganti dari container/`SurfaceCard` biasa ke `GlassCard`:

| Widget | Perubahan |
|--------|-----------|
| `_KasHeroCard` | Ganti `Container` wrapper terluar → `GlassCard` |
| `_DashStatCard` | Ganti `Container` wrapper terluar → `GlassCard` |
| `_CommunityCodeTile` | Ganti `SurfaceCard` → `GlassCard` |
| `_QuickActions` | Wrap seluruh `GridView` dengan `GlassCard(padding: EdgeInsets.all(16))` |

`SurfaceCard` tetap dipakai di screen lain — tidak ada breaking change.

---

## 3. Lottie Payment Success

### Dependency

Tambahkan ke `pubspec.yaml`:
```yaml
dependencies:
  lottie: ^3.1.0
```

### Asset

Simpan di `assets/lottie/payment_success.json`. File JSON didownload dari LottieFiles (free, open license): cari "success checkmark green" atau "payment success confetti" di lottiefiles.com — pilih yang warna hijau agar sesuai brand.

Daftarkan di `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/lottie/
```

### `LottieSuccessDialog` Widget

Tambahkan ke `lib/app/components.dart`:

```dart
// lib/app/components.dart
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
              Future.delayed(comp.duration + const Duration(milliseconds: 300), () {
                if (context.mounted) Navigator.of(context).pop();
              });
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

### Trigger Points

**1. Resident submit bukti bayar** — di `lib/features/payments/screens/payments_screen.dart`:

Cari callback sukses upload (biasanya setelah `ref.invalidate(...)` atau `showSnackBar` success). Ganti/tambahkan:
```dart
if (mounted) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const LottieSuccessDialog(message: 'Bukti pembayaran terkirim!'),
  );
}
```

**2. Admin verifikasi pembayaran** — di screen admin yang menangani approve invoice (cari `status: 'paid'` atau `awaiting_verification` di `lib/features/invoices/` atau `lib/features/payments/`):
```dart
if (mounted) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const LottieSuccessDialog(message: 'Pembayaran terverifikasi!'),
  );
}
```

---

## 4. flutter_animate Page Transitions

### Dependency

Tambahkan ke `pubspec.yaml`:
```yaml
dependencies:
  flutter_animate: ^4.5.0
```

### Helper di `router.dart`

Tambahkan helper function `_buildPage` di `lib/app/router.dart` (di luar class `AppRouter` / di level file):

```dart
// lib/app/router.dart
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

> **Catatan:** GoRouter transitions pakai Flutter built-in `FadeTransition` + `SlideTransition` karena GoRouter menyediakan `Animation<double>`, bukan `AnimationController` — sehingga `.animate()` extension dari `flutter_animate` tidak bisa langsung dipakai di `transitionsBuilder`. Package `flutter_animate` tetap ditambahkan ke pubspec dan tersedia untuk widget-level entrance animations di screen lain (misalnya card stagger animations) di iterasi berikutnya.

### Penerapan di Routes

Semua route full-screen (di luar `ShellRoute`) yang belum punya `pageBuilder` ditambahkan:

```dart
// Contoh — setiap GoRoute full-screen:
GoRoute(
  path: '/admin/tagihan/buat',
  pageBuilder: (context, state) => _buildPage(
    state: state,
    child: const CreateInvoiceScreen(),
  ),
),
```

Route di dalam `ShellRoute` (tab navigation) **tidak** mendapat custom transition — tab switch sudah punya behavior sendiri.

---

## Scope Spec B (Post-launch, tidak dikerjakan sekarang)

- Badge warga (Sultan/Kritis/Gaul) — butuh kolom DB + gamification logic
- Confetti animasi setelah bayar (beda dari Lottie dialog — ini efek layer di atas screen)
- Reactions + komentar di announcements — butuh tabel DB baru
- Lottie untuk loading states (CircularProgressIndicator replacement)

---

## Resuming This Conversation

Jika melanjutkan di sesi baru:
> "Lanjutkan dari spec `docs/superpowers/specs/2026-04-05-ui-overhaul-spec-a-design.md` — design sudah approved, tulis implementation plan-nya"

Lalu invoke `superpowers:writing-plans`.
