# Borderless UI Refactor — Design Spec
**Date:** 2026-04-06
**Status:** Approved

---

## Tujuan

Menghapus seluruh border/outline dari semua elemen visual di aplikasi Rukunin dan menggantinya dengan sistem visual yang bersih berbasis **background elevation** dan **ultra-soft shadow**. Target hasil akhir: tampilan minimalis bergaya Material You / Modern FinTech.

---

## Scope

- **170 border instances** di **45 file** Dart
- Termasuk: cards, containers, input fields, buttons (OutlinedButton), status badges, bottom sheets, dialogs, TabBar indicator, Divider
- Tidak ada pengecualian — semua border dihapus

---

## Strategi Visual

### Light Mode

| Elemen | Sebelum | Sesudah |
|---|---|---|
| Card / Container | Border tipis + background putih | Tanpa border, background `lightCardSurface (#FFFFFF)` di atas `lightBg (#F4F6FA)` |
| Input Field | `OutlineInputBorder` | `InputBorder.none`, fill `lightInputFill (#F0F2F5)`, shadow ultra-soft |
| Interactive Card | Border hijau tipis | Tanpa border, `RukuninShadow.card` |
| Badge/Chip | Border warna semi-transparent | Tanpa border, background color-only |
| OutlinedButton | Border + transparent bg | `TextButton` atau `ElevatedButton.tonal` |

### Dark Mode

| Elemen | Strategi |
|---|---|
| Card statis (info) | Surface elevation — `darkSurface (#141B24)` di atas `darkBg (#0D1117)` |
| Card interaktif (stat card, quick action) | Tanpa border + `RukuninShadow.interactiveGlow` (green glow ~3%) |
| Input Field | Fill `darkSurface`, tanpa border |

---

## Token Baru — `lib/app/tokens.dart`

### Tambahan ke `RukuninColors`

```dart
// Light mode elevation
static const Color lightCardSurface = Color(0xFFFFFFFF);   // card di atas lightBg
static const Color lightInputFill   = Color(0xFFF0F2F5);   // input fill

// Dark mode — gunakan darkSurface yang sudah ada (Color(0xFF141B24))
```

### Tambahan ke `RukuninShadow`

```dart
// Card biasa — light mode only, barely-there
static const List<BoxShadow> card = [
  BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2)),
];

// Input field & interactive elements — ultra-soft depth
static const List<BoxShadow> inputField = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
];

// Interactive card dark mode — subtle brand glow (~3% opacity)
static const List<BoxShadow> interactiveGlow = [
  BoxShadow(color: Color(0x08388E3C), blurRadius: 16, offset: Offset(0, 4)),
];
```

**Opacity reference:** `0x08` = 3.1%, `0x0A` = 3.9%. Keduanya di bawah threshold "terlihat berat".

---

## Perubahan Design System Global

### `lib/app/theme.dart`

- **`InputDecorationTheme`**: Semua border → `InputBorder.none`. `fillColor` pakai `lightInputFill` (light) / `darkSurface` (dark). `filled: true`.
- **`OutlinedButtonThemeData`**: Hapus, ganti ke `TextButton` style untuk secondary action. `side: BorderSide.none`.
- **`DividerThemeData`**: `color: Colors.transparent`, `thickness: 0`.
- **`CardTheme`**: `elevation: 0`, shape tanpa border.
- **`TabBarTheme`**: `indicatorColor: Colors.transparent`, ganti ke underline thickness-only indicator tanpa border.

### `lib/app/components.dart`

- **`SurfaceCard`**: Hapus `border:`. Light → `color: lightCardSurface` + `boxShadow: RukuninShadow.card`. Dark → `color: darkSurface`.
- **`GlassCard`**: Hapus `border:` dari inner `BoxDecoration`. Pertahankan glassmorphism (blur, opacity).
- **`EmptyState`**, **`ShimmerBox`**, widget shared lain: hapus border hardcoded.

---

## Sweep Feature Files — Aturan Per Kategori

### 1. Cards & Containers (`BoxDecoration`)
```dart
// SEBELUM
decoration: BoxDecoration(
  color: isDark ? darkSurface : lightSurface,
  border: Border.all(color: darkBorder, width: 0.5),
  borderRadius: BorderRadius.circular(16),
)

// SESUDAH
decoration: BoxDecoration(
  color: isDark ? RukuninColors.darkSurface : RukuninColors.lightCardSurface,
  borderRadius: BorderRadius.circular(16),
  boxShadow: isDark ? null : RukuninShadow.card,
)
```

### 2. Interactive Cards (stat card, quick action) — dark mode
```dart
boxShadow: isDark ? RukuninShadow.interactiveGlow : RukuninShadow.card,
```

### 3. Input Fields
```dart
// SEBELUM
OutlineInputBorder(borderSide: BorderSide(color: ...))

// SESUDAH
border: InputBorder.none,
enabledBorder: InputBorder.none,
focusedBorder: InputBorder.none,
filled: true,
fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightInputFill,
```
Tambah wrapper `Container` dengan `boxShadow: RukuninShadow.inputField` jika field butuh depth visual.

### 4. OutlinedButton → TextButton
```dart
// SEBELUM
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: RukuninColors.error),
    foregroundColor: RukuninColors.error,
  ),
  child: Text('Tolak'),
)

// SESUDAH
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: RukuninColors.error,
  ),
  child: Text('Tolak'),
)
```

### 5. Status Badge / Chip
```dart
// SEBELUM
decoration: BoxDecoration(
  color: statusColor.withValues(alpha: 0.1),
  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
)

// SESUDAH
decoration: BoxDecoration(
  color: statusColor.withValues(alpha: 0.12), // sedikit lebih opak untuk kompensasi
)
```

### 6. Bottom Sheet & Dialog
Hapus `border:` dari container `BoxDecoration`. `borderRadius` tetap ada.

### 7. Divider
- Jika `Divider` dipakai sebagai **spacing** → ganti ke `SizedBox(height: N)`.
- Jika dipakai sebagai **separator visual** antar section → pertahankan sebagai `Divider(color: Colors.transparent)` atau hapus total; konteks memutuskan. Tidak ada garis horizontal yang terlihat.

---

## Urutan Implementasi

1. **`lib/app/tokens.dart`** — definisi token baru
2. **`lib/app/theme.dart`** — global theme borderless
3. **`lib/app/components.dart`** — shared widgets borderless
4. **Feature files** (43 file) — sweep per kategori elemen

**File prioritas tinggi** (border count terbanyak):
- `admin_dashboard_screen.dart`
- `resident_invoices_screen.dart`
- `residents_screen.dart`
- `invoices_screen.dart`
- `auth/` screens (login, register, forgot password)
- `layanan/` screens
- `polling/` screens

---

## Success Criteria

- Zero `Border.all(...)` yang visible di runtime (kecuali yang memang invisible/transparent)
- Zero `OutlinedButton` dengan `BorderSide` non-transparent
- Zero `OutlineInputBorder` non-transparent
- Semua card tetap terbedakan dari background tanpa border
- Input field tetap teridentifikasi sebagai area input
- Shadow tidak tampak "berat" — blur radius ≥ 8, opacity ≤ 4%
- Konsisten di light mode dan dark mode
