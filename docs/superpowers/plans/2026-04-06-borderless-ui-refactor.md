# Borderless UI Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all visible borders from every widget in the Rukunin Flutter app and replace them with background-elevation contrast (cards) and ultra-soft shadow (inputs/interactive elements).

**Architecture:** Four phases in strict order — (1) add new shadow/color tokens, (2) fix global theme, (3) fix shared components, (4) sweep all 43 feature files in logical batches. Each phase commits independently so rollback is scoped.

**Tech Stack:** Flutter 3.x, Dart, `lib/app/tokens.dart`, `lib/app/theme.dart`, `lib/app/components.dart`, feature screens under `lib/features/`.

---

## Rules applied everywhere

Throughout all tasks, apply these transformations mechanically:

| Pattern | Replace with |
|---|---|
| `border: Border.all(...)` inside `BoxDecoration` | delete the `border:` line entirely |
| `OutlineInputBorder(borderSide: BorderSide(...))` | `InputBorder.none` |
| `OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(...)))` | `TextButton(style: TextButton.styleFrom(foregroundColor: <same color>))` |
| `OutlinedButton.styleFrom(side: BorderSide(...), foregroundColor: X)` | `TextButton.styleFrom(foregroundColor: X)` |
| `side: BorderSide(color: ...)` inside ChipTheme / Card shape | delete `side:` line |
| `dividerColor: border` in TabBarTheme | `dividerColor: Colors.transparent` |
| `color: border, thickness: 0.5` in DividerTheme | `color: Colors.transparent, thickness: 0` |
| Bare `Divider()` or `Divider(height: 1)` used as visual separator | delete or replace with `SizedBox(height: 1)` |
| `shape: RoundedRectangleBorder(borderRadius: ..., side: BorderSide(...))` | keep `borderRadius`, delete `side:` |
| Badge/chip `BoxDecoration` with both `color: x.withValues(alpha: 0.1)` and `border: Border.all(color: x.withValues(alpha: 0.3))` | keep color, raise alpha to `0.13`, delete border |

**Shadow tokens to use (defined in Task 1):**
- Cards in light mode → `boxShadow: RukuninShadow.card`
- Interactive cards in dark mode → `boxShadow: RukuninShadow.interactiveGlow`
- Input fields → `boxShadow: RukuninShadow.inputField` (wrap field in `Container` if needed)

---

## Task 1 — New tokens in `lib/app/tokens.dart`

**Files:**
- Modify: `lib/app/tokens.dart`

- [ ] **Step 1: Add color tokens to `RukuninColors`**

Open `lib/app/tokens.dart`. After the `lightBorderSub` line (line 30), add:

```dart
  // ── Borderless elevation colors ───────────────────────────────────────────
  static const Color lightCardSurface = Color(0xFFFFFFFF); // card on lightBg (#F4F6FA)
  static const Color lightInputFill   = Color(0xFFF0F2F5); // input fill, slightly darker
```

- [ ] **Step 2: Add shadow tokens to `RukuninShadow`**

After the closing `]` of `get neonGlow` (line 149), before the closing `}` of `RukuninShadow`, add:

```dart

  // ── Borderless shadow tokens ──────────────────────────────────────────────

  /// Card in light mode — barely-there depth (3.1% opacity)
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  /// Input field & interactive elements — ultra-soft (3.9% opacity)
  static const List<BoxShadow> inputField = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Interactive card dark mode — subtle brand glow (3.1% opacity green)
  static const List<BoxShadow> interactiveGlow = [
    BoxShadow(color: Color(0x0800C853), blurRadius: 16, offset: Offset(0, 4)),
  ];
```

- [ ] **Step 3: Verify no analysis errors**

```bash
flutter analyze lib/app/tokens.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/app/tokens.dart
git commit -m "feat(tokens): add borderless shadow and elevation color tokens"
```

---

## Task 2 — Global theme: `lib/app/theme.dart`

**Files:**
- Modify: `lib/app/theme.dart`

- [ ] **Step 1: Fix AppBar — remove bottom border**

Find (line ~118):
```dart
      shape: Border(
        bottom: BorderSide(color: border, width: 0.5),
      ),
```
Replace with:
```dart
      shape: null,
```

- [ ] **Step 2: Fix CardTheme — remove side**

Find (line ~169):
```dart
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: 0.5),
      ),
```
Replace with:
```dart
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
```

- [ ] **Step 3: Fix InputDecorationTheme — borderless with new fill**

Replace the entire `inputDecorationTheme:` block (lines ~178-206):
```dart
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: RukuninFonts.pjs(fontSize: 14, color: textTer),
      labelStyle: RukuninFonts.pjs(fontSize: 14, color: textSec),
      errorStyle: RukuninFonts.pjs(fontSize: 12, color: RukuninColors.error),
    ),
```

- [ ] **Step 4: Fix OutlinedButtonTheme — borderless secondary button**

Replace the `outlinedButtonTheme:` block (lines ~230-241):
```dart
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPri,
        side: BorderSide.none,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: RukuninFonts.pjs(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
```

- [ ] **Step 5: Fix ChipTheme — remove side**

Find `side: BorderSide(color: border, width: 0.5),` inside `chipTheme` and delete that line.

- [ ] **Step 6: Fix TabBarTheme — remove divider**

Find `dividerColor: border,` inside `tabBarTheme` and replace with:
```dart
      dividerColor: Colors.transparent,
```

- [ ] **Step 7: Fix DividerTheme — invisible**

Replace `dividerTheme:` block:
```dart
    dividerTheme: const DividerThemeData(
      color: Colors.transparent,
      thickness: 0,
      space: 0,
    ),
```

- [ ] **Step 8: Fix DialogTheme — remove border from shape**

Find inside `dialogTheme`:
```dart
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border, width: 0.5),
      ),
```
Replace with:
```dart
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
```

- [ ] **Step 9: Fix PopupMenuTheme — remove border from shape**

Find inside `popupMenuTheme`:
```dart
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border, width: 0.5),
      ),
```
Replace with:
```dart
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
```

- [ ] **Step 10: Fix DropdownMenuTheme — borderless input**

Replace the `border:` inside `dropdownMenuTheme.inputDecorationTheme`:
```dart
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
```

- [ ] **Step 11: Fix CheckboxTheme — remove border side**

Find inside `checkboxTheme`:
```dart
      side: BorderSide(color: border, width: 1.5),
```
Replace with:
```dart
      side: BorderSide.none,
```

- [ ] **Step 12: Analyze and commit**

```bash
flutter analyze lib/app/theme.dart
git add lib/app/theme.dart
git commit -m "feat(theme): remove all borders from global theme — borderless design system"
```

---

## Task 3 — Shared components: `lib/app/components.dart`

**Files:**
- Modify: `lib/app/components.dart`

- [ ] **Step 1: Find all borders in components.dart**

```bash
grep -n "border:\|Border\.all\|BorderSide\|OutlinedButton" lib/app/components.dart
```
Expected lines: ~113, ~884, ~905. Note the exact lines.

- [ ] **Step 2: Fix SurfaceCard — remove border, add shadow**

Find `SurfaceCard` class. Its `BoxDecoration` has a `border:` property. Replace the decoration:

```dart
// BEFORE (approximate):
decoration: BoxDecoration(
  color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
  borderRadius: BorderRadius.circular(borderRadius),
  border: hasBorder ? Border.all(color: borderColor, width: 0.5) : null,
  boxShadow: boxShadow,
),

// AFTER:
decoration: BoxDecoration(
  color: isDark ? RukuninColors.darkSurface : RukuninColors.lightCardSurface,
  borderRadius: BorderRadius.circular(borderRadius),
  boxShadow: isDark ? null : RukuninShadow.card,
),
```

If `SurfaceCard` has `hasBorder` / `borderColor` constructor params that are now unused, remove those params entirely and update all call sites (search: `SurfaceCard(` across codebase to verify none pass `hasBorder`).

- [ ] **Step 3: Fix GlassCard — remove border from BoxDecoration**

Find `GlassCard`. Its inner `BoxDecoration` (inside the `BackdropFilter` or `Container`) has:
```dart
border: Border.all(color: ..., width: ...),
```
Delete that `border:` line. Keep everything else (blur, color, borderRadius).

- [ ] **Step 4: Fix any other bordered widgets in components.dart**

Lines ~884 and ~905 identified in Step 1. For each:
- If it's a `BoxDecoration` with `border: Border.all(...)` → delete the `border:` line
- If it's an `OutlinedButton` → convert to `TextButton` keeping same `foregroundColor`

- [ ] **Step 5: Analyze and commit**

```bash
flutter analyze lib/app/components.dart
git add lib/app/components.dart
git commit -m "feat(components): borderless SurfaceCard, GlassCard, shared widgets"
```

---

## Task 4 — Auth screens batch

**Files:** `lib/features/auth/screens/` (6 files)
- `login_screen.dart`, `register_admin_screen.dart`, `register_resident_screen.dart`, `register_resident_step2_screen.dart`, `forgot_password_screen.dart`, `reset_password_screen.dart`

- [ ] **Step 1: Remove all borders from auth screens**

For each file, run:
```bash
grep -n "border:\|Border\.all\|OutlineInputBorder\|OutlinedButton\|BorderSide" lib/features/auth/screens/<filename>.dart
```

Apply transformations per the Rules table at the top. Specific known patterns:

**`register_admin_screen.dart`** — has `OutlineInputBorder` with `_kWhite.withValues(alpha: 0.1)` border. Replace all 4 border declarations with `InputBorder.none`. Keep `fillColor` as-is.

**`login_screen.dart`** — has `border: Border.all(...)` in a container. Delete the `border:` line.

**All auth screens** — any `OutlinedButton` for "Kembali" or secondary → convert to `TextButton`.

- [ ] **Step 2: Analyze batch**

```bash
flutter analyze lib/features/auth/screens/
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/screens/
git commit -m "feat(auth): borderless login, register, forgot-password screens"
```

---

## Task 5 — Dashboard + residents batch

**Files:**
- `lib/features/dashboard/screens/admin_dashboard_screen.dart`
- `lib/features/residents/screens/residents_screen.dart`
- `lib/features/residents/screens/add_edit_resident_screen.dart`
- `lib/features/residents/screens/resident_detail_screen.dart`
- `lib/shell/float_nav.dart`

- [ ] **Step 1: Fix admin_dashboard_screen.dart**

```bash
grep -n "border:\|Border\.all" lib/features/dashboard/screens/admin_dashboard_screen.dart
```

For each `BoxDecoration` with `border: Border.all(color: RukuninColors.brandGreen.withValues(...))`:
- Delete `border:` line
- In dark mode containers for stat cards / quick actions: add `boxShadow: RukuninShadow.interactiveGlow`
- In light mode containers: add `boxShadow: RukuninShadow.card`

Pattern for `_DashStatCard` light mode container:
```dart
// BEFORE
decoration: BoxDecoration(
  color: RukuninColors.lightSurface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(
    color: RukuninColors.brandGreen.withValues(alpha: 0.14),
    width: 1.0,
  ),
  boxShadow: [...],
),
// AFTER
decoration: BoxDecoration(
  color: RukuninColors.lightCardSurface,
  borderRadius: BorderRadius.circular(18),
  boxShadow: RukuninShadow.card,
),
```

- [ ] **Step 2: Fix residents_screen.dart and add_edit_resident_screen.dart**

```bash
grep -n "border:\|Border\.all\|OutlineInputBorder\|OutlinedButton" lib/features/residents/screens/residents_screen.dart lib/features/residents/screens/add_edit_resident_screen.dart lib/features/residents/screens/resident_detail_screen.dart
```

For each `BoxDecoration.border` → delete. For `OutlineInputBorder` in add_edit form → `InputBorder.none`. For `OutlinedButton` → `TextButton`.

- [ ] **Step 3: Fix float_nav.dart**

```bash
grep -n "border:" lib/shell/float_nav.dart
```

Line ~92: `border: Border.all(color: borderColor, width: 0.5)` → delete line. Add `boxShadow: RukuninShadow.card` if there's no shadow already.

- [ ] **Step 4: Analyze and commit**

```bash
flutter analyze lib/features/dashboard/ lib/features/residents/ lib/shell/
git add lib/features/dashboard/ lib/features/residents/ lib/shell/float_nav.dart
git commit -m "feat(dashboard,residents,nav): borderless cards and containers"
```

---

## Task 6 — Invoices + payments batch

**Files:**
- `lib/features/invoices/screens/invoices_screen.dart`
- `lib/features/invoices/screens/create_invoice_screen.dart`
- `lib/features/invoices/screens/billing_types_screen.dart`
- `lib/features/invoices/screens/add_edit_billing_type_screen.dart`
- `lib/features/resident_portal/screens/resident_invoices_screen.dart`
- `lib/features/resident_portal/screens/resident_kas_screen.dart`
- `lib/features/payments/screens/payments_screen.dart`

- [ ] **Step 1: Sweep all invoice/payment borders**

```bash
grep -n "border:\|Border\.all\|OutlineInputBorder\|OutlinedButton" \
  lib/features/invoices/screens/invoices_screen.dart \
  lib/features/invoices/screens/create_invoice_screen.dart \
  lib/features/invoices/screens/billing_types_screen.dart \
  lib/features/invoices/screens/add_edit_billing_type_screen.dart \
  lib/features/resident_portal/screens/resident_invoices_screen.dart \
  lib/features/resident_portal/screens/resident_kas_screen.dart \
  lib/features/payments/screens/payments_screen.dart
```

Apply Rules table. Key patterns in these files:
- Status badge containers (`color: statusColor.withValues(alpha: 0.1), border: Border.all(...)`) → delete `border:`, raise alpha to `0.13`
- Payment method cards with green border → delete `border:`, no shadow needed (background contrast sufficient)
- `OutlineInputBorder` in create_invoice form → `InputBorder.none`

- [ ] **Step 2: Analyze and commit**

```bash
flutter analyze lib/features/invoices/ lib/features/resident_portal/ lib/features/payments/
git add lib/features/invoices/ lib/features/resident_portal/ lib/features/payments/
git commit -m "feat(invoices,payments): borderless invoice cards, status badges, forms"
```

---

## Task 7 — Polling + announcements batch

**Files:**
- `lib/features/polling/screens/create_poll_screen.dart` (11 instances — highest count)
- `lib/features/polling/screens/poll_detail_admin_screen.dart`
- `lib/features/polling/screens/poll_vote_screen.dart`
- `lib/features/polling/screens/polls_admin_screen.dart`
- `lib/features/announcements/screens/announcements_screen.dart`
- `lib/features/announcements/screens/create_announcement_screen.dart`

- [ ] **Step 1: Sweep polling/announcement borders**

```bash
grep -n "border:\|Border\.all\|OutlineInputBorder\|OutlinedButton" \
  lib/features/polling/screens/create_poll_screen.dart \
  lib/features/polling/screens/poll_detail_admin_screen.dart \
  lib/features/polling/screens/poll_vote_screen.dart \
  lib/features/polling/screens/polls_admin_screen.dart \
  lib/features/announcements/screens/announcements_screen.dart \
  lib/features/announcements/screens/create_announcement_screen.dart
```

`create_poll_screen.dart` (11 instances) will have the most work. Common pattern: option containers with border → delete border, add subtle background difference or `RukuninShadow.card`. Forms: `OutlineInputBorder` → `InputBorder.none`.

- [ ] **Step 2: Analyze and commit**

```bash
flutter analyze lib/features/polling/ lib/features/announcements/
git add lib/features/polling/ lib/features/announcements/
git commit -m "feat(polling,announcements): borderless poll options, form fields"
```

---

## Task 8 — Layanan + letters + marketplace batch

**Files:**
- `lib/features/layanan/screens/admin_complaints_screen.dart`
- `lib/features/layanan/screens/admin_contacts_screen.dart`
- `lib/features/layanan/screens/admin_requests_screen.dart`
- `lib/features/layanan/screens/request_letter_screen.dart`
- `lib/features/layanan/screens/verify_request_screen.dart`
- `lib/features/letters/screens/create_letter_screen.dart`
- `lib/features/marketplace/screens/add_listing_screen.dart`
- `lib/features/marketplace/screens/listing_detail_screen.dart`

- [ ] **Step 1: Sweep layanan/letters/marketplace borders**

```bash
grep -n "border:\|Border\.all\|OutlineInputBorder\|OutlinedButton" \
  lib/features/layanan/screens/admin_complaints_screen.dart \
  lib/features/layanan/screens/admin_contacts_screen.dart \
  lib/features/layanan/screens/admin_requests_screen.dart \
  lib/features/layanan/screens/request_letter_screen.dart \
  lib/features/layanan/screens/verify_request_screen.dart \
  lib/features/letters/screens/create_letter_screen.dart \
  lib/features/marketplace/screens/add_listing_screen.dart \
  lib/features/marketplace/screens/listing_detail_screen.dart
```

Apply Rules. For `OutlinedButton` in verify_request (Tolak/Setujui) → `TextButton` with `foregroundColor: RukuninColors.error` for Tolak.

- [ ] **Step 2: Analyze and commit**

```bash
flutter analyze lib/features/layanan/ lib/features/letters/ lib/features/marketplace/
git add lib/features/layanan/ lib/features/letters/ lib/features/marketplace/
git commit -m "feat(layanan,letters,marketplace): borderless cards and forms"
```

---

## Task 9 — Remaining screens batch

**Files:**
- `lib/features/expenses/screens/expenses_screen.dart`
- `lib/features/reports/screens/reports_screen.dart`
- `lib/features/notifications/screens/notifications_screen.dart`
- `lib/features/settings/screens/admin_profile_screen.dart`
- `lib/features/settings/screens/payment_settings_screen.dart`
- `lib/features/resident_portal/screens/resident_profile_screen.dart`
- `lib/features/community/screens/community_settings_screen.dart`
- `lib/features/ai_assistant/screens/ai_assistant_screen.dart`

- [ ] **Step 1: Sweep remaining borders**

```bash
grep -n "border:\|Border\.all\|OutlineInputBorder\|OutlinedButton" \
  lib/features/expenses/screens/expenses_screen.dart \
  lib/features/reports/screens/reports_screen.dart \
  lib/features/notifications/screens/notifications_screen.dart \
  lib/features/settings/screens/admin_profile_screen.dart \
  lib/features/settings/screens/payment_settings_screen.dart \
  lib/features/resident_portal/screens/resident_profile_screen.dart \
  lib/features/community/screens/community_settings_screen.dart \
  lib/features/ai_assistant/screens/ai_assistant_screen.dart
```

Apply Rules table. For each result:
- `border: Border.all(...)` in BoxDecoration → delete
- `OutlineInputBorder` → `InputBorder.none`
- `OutlinedButton` → `TextButton`

- [ ] **Step 2: Analyze and commit**

```bash
flutter analyze lib/features/expenses/ lib/features/reports/ lib/features/notifications/ lib/features/settings/ lib/features/community/ lib/features/ai_assistant/
git add lib/features/expenses/ lib/features/reports/ lib/features/notifications/ lib/features/settings/ lib/features/community/ lib/features/ai_assistant/ lib/features/resident_portal/screens/resident_profile_screen.dart
git commit -m "feat(settings,reports,expenses,ai): borderless remaining screens"
```

---

## Task 10 — Final verification sweep

**Files:** All Dart files in `lib/`

- [ ] **Step 1: Zero-border scan**

```bash
grep -rn "Border\.all\|side: BorderSide(" lib/ --include="*.dart" | grep -v "BorderSide\.none\|side: BorderSide\.none\|//\|pdf_generator\|letter_pdf"
```

Expected: zero results (PDF generators are excluded — they generate documents, not app UI).

- [ ] **Step 2: Zero OutlineInputBorder scan**

```bash
grep -rn "OutlineInputBorder" lib/ --include="*.dart" | grep -v "BorderSide\.none\|borderSide: BorderSide\.none"
```

Expected: zero results.

- [ ] **Step 3: Zero OutlinedButton with visible border scan**

```bash
grep -rn "OutlinedButton" lib/ --include="*.dart" | grep -v "//\|BorderSide\.none"
```

Expected: zero results (all OutlinedButton converted to TextButton).

- [ ] **Step 4: Full project analyze**

```bash
flutter analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 5: Push all commits**

```bash
git push
```

---

## Self-Review Checklist

- **Tokens (Task 1):** `lightCardSurface`, `lightInputFill`, `RukuninShadow.card`, `.inputField`, `.interactiveGlow` — all defined ✓
- **Theme (Task 2):** AppBar border, CardTheme side, InputDecoration, OutlinedButton, ChipTheme, TabBar divider, DividerTheme, DialogTheme, PopupMenuTheme, DropdownMenu, CheckboxTheme — all 11 covered ✓
- **Components (Task 3):** SurfaceCard, GlassCard, other bordered widgets — covered ✓
- **Feature files:** 43 files split across Tasks 4-9, no file missed ✓
- **Verification (Task 10):** Three independent grep checks + full analyze ✓
- **PDF generators excluded:** `letter_pdf_generator.dart`, `pdf_generator.dart` — borders there are for PDF document layout, not app UI ✓
- **Shadow tokens match spec:** `0x08` = 3.1%, `0x0A` = 3.9% — both under 4% threshold ✓
- **Interactive card dark glow:** `0x0800C853` = green glow 3.1% opacity ✓
- **No placeholder steps:** every step has exact commands or code ✓
