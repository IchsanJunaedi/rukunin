# Spec: Automated Testing Suite — Unit + Widget Tests

**Tanggal:** 2026-03-23
**Status:** Draft

---

## Ringkasan

Membuat automated testing suite untuk Rukunin yang mencakup **unit tests** (semua model) dan **widget tests** (semua screen utama). Script runner menjalankan test satu per satu, meng-update `test_progress.md` secara live, dan menghasilkan `test_report.md` final dengan error detail + saran upgrade + gap checklist.

Tidak menggunakan emulator atau koneksi Supabase nyata — semua widget test menggunakan mock providers via `ProviderScope` overrides.

---

## Tools & Dependencies

| Tool | Fungsi |
|---|---|
| `flutter test` | Runner bawaan Flutter |
| `flutter_test` | Package test: `testWidgets()`, `expect()`, `find.*()` |
| `flutter_riverpod` | `ProviderScope` overrides untuk mock providers |
| `mocktail` | Mock class untuk Supabase client (ditambah ke `dev_dependencies`) |
| `dart run tool/run_tests.dart` | Script custom runner |

---

## Struktur File

```
test/
  unit/
    models/
      invoice_model_test.dart
      resident_model_test.dart
      expense_model_test.dart
      billing_type_model_test.dart
      announcement_model_test.dart
      complaint_model_test.dart
      letter_request_model_test.dart
      community_contact_model_test.dart
      marketplace_listing_model_test.dart
      notification_model_test.dart
      report_model_test.dart
  widget/
    screens/
      login_screen_test.dart
      admin_dashboard_test.dart
      residents_screen_test.dart
      invoices_screen_test.dart
      expenses_screen_test.dart
      layanan_screen_test.dart
      admin_contacts_screen_test.dart
      announcements_screen_test.dart
      marketplace_screen_test.dart
      reports_screen_test.dart
      resident_home_screen_test.dart
      resident_invoices_screen_test.dart
  helpers/
    mock_providers.dart    ← ProviderScope overrides factory
    test_data.dart         ← fixture data untuk semua model

tool/
  run_tests.dart           ← script runner

test_progress.md           ← live progress (root project)
test_report.md             ← final report (root project)
```

---

## Unit Tests — Models

Setiap model test file mencakup:

1. **`fromMap` parses correctly** — semua field terparsing dengan benar dari map valid
2. **`fromMap` handles nulls** — field nullable tidak crash saat null
3. **Computed getters** — label, status, isActive, dll. return nilai yang benar
4. **`toMap`** (jika ada) — output map sesuai untuk DB insert

**Model yang di-test (11 model):**
- `InvoiceModel` — status labels, isOverdue, amount parsing
- `ResidentModel` — full_name, unit_number, status
- `ExpenseModel` — category, amount, date parsing
- `BillingTypeModel` — name, amount, type
- `AnnouncementModel` — title, body, created_at
- `ComplaintModel` — sudah ada, diperluas (null handling, categoryLabel)
- `LetterRequestModel` — sudah ada, diperluas (progressPercent, isActive)
- `CommunityContactModel` — sudah ada, lengkap
- `MarketplaceListingModel` — price, category, seller
- `NotificationModel` — type, isRead, body
- `ReportModel` — month, totals parsing

---

## Widget Tests — Screens

Setiap screen test mencakup:

1. **Renders without crash** — `pumpWidget` tidak throw exception
2. **Key widgets present** — AppBar title, tombol utama, list/empty state ada
3. **Form validation** (untuk screen dengan form) — field kosong → error message muncul

**Mock pattern:**
```dart
testWidgets('description', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        someProvider.overrideWith((_) async => fakeData),
      ],
      child: MaterialApp(
        home: TheScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Expected Text'), findsOneWidget);
});
```

**Screen yang di-test (12 screen utama):**

| Screen | Assertions |
|---|---|
| `LoginScreen` | Form render, email/password field, tombol Login |
| `AdminDashboardScreen` | AppBar, Aksi Cepat grid, Layanan Warga cards |
| `ResidentsScreen` | List render, search bar |
| `InvoicesScreen` | List render, filter chips |
| `ExpensesScreen` | List render, FAB |
| `LayananScreen` | 3 tab (Surat, Pengaduan, Kontak) |
| `AdminContactsScreen` | FAB, empty state |
| `AnnouncementsScreen` | List render |
| `MarketplaceScreen` | Grid render |
| `ReportsScreen` | Render tanpa crash |
| `ResidentHomeScreen` | Dashboard render |
| `ResidentInvoicesScreen` | List render |

---

## `test/helpers/mock_providers.dart`

Factory yang provide `ProviderScope` overrides standar untuk semua test:

```dart
List<Override> mockOverrides({
  List<InvoiceModel> invoices = const [],
  List<ResidentModel> residents = const [],
  // ... semua provider utama
}) {
  return [
    supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
    invoicesProvider.overrideWith((_) async => invoices),
    // ...
  ];
}
```

---

## `test/helpers/test_data.dart`

Fixture data — satu instance valid per model:

```dart
final fakeInvoice = InvoiceModel(id: 'inv-1', ...);
final fakeResident = ResidentModel(id: 'res-1', ...);
// ...
```

---

## `tool/run_tests.dart` — Script Runner

### Alur:

1. Buat/reset `test_progress.md` dengan semua baris kosong
2. Loop setiap test file satu per satu:
   - Update baris di `test_progress.md` → `⏳ sedang berjalan...`
   - Jalankan `flutter test <file> --reporter json`
   - Parse hasil JSON output
   - Update baris → `✅` atau `❌`
3. Setelah semua selesai, jalankan **gap analysis** (scan file test vs file model/screen)
4. Generate `test_report.md` dengan:
   - Ringkasan passed/failed/total
   - Error detail per test yang gagal (nama test, pesan error, saran perbaikan)
   - Gap checklist (model/screen tanpa test, pola yang belum ada)

### Format `test_progress.md` (live):

```markdown
# Test Progress — YYYY-MM-DD HH:mm:ss

## Unit Tests — Models
| Model | Status |
|---|---|
| InvoiceModel | ✅ |
| ResidentModel | ⏳ sedang berjalan... |
| ExpenseModel | |
...

## Widget Tests — Screens
| Screen | Status |
|---|---|
| LoginScreen | |
...
```

### Format `test_report.md` (final):

```markdown
# Test Report — YYYY-MM-DD HH:mm:ss

## Ringkasan
- ✅ Passed: X/Y
- ❌ Failed: N/Y

## Error Detail
### ❌ [ModelName/ScreenName] — [test name]
**File:** test/path/file_test.dart:LINE
**Error:** [pesan error]
**Saran:** [saran spesifik]

## Gap Checklist
- [ ] [Model/Screen] belum ada test
- [ ] [Field/Widget] belum ada validasi
```

---

## Saran Upgrade — Kategori

Script menghasilkan saran dari dua sumber:

1. **Dari test failure** — parser deteksi pola error umum:
   - `type 'Null' is not a subtype` → saran: tambah null fallback di `fromMap`
   - `No element` / `findsNothing` → saran: cek widget key atau text yang dicari
   - `ProviderException` → saran: tambah override di ProviderScope

2. **Dari static gap scan:**
   - Model file tanpa test file → "Belum ada unit test untuk X"
   - Screen file tanpa test file → "Belum ada widget test untuk X"
   - Screen dengan form tanpa validation test → "Belum ada test form validation di X"

---

## File yang Dibuat / Diubah

| File | Aksi |
|---|---|
| `pubspec.yaml` | Edit — tambah `mocktail` ke dev_dependencies |
| `test/helpers/mock_providers.dart` | Baru |
| `test/helpers/test_data.dart` | Baru |
| `test/unit/models/*.dart` (11 file) | Baru |
| `test/widget/screens/*.dart` (12 file) | Baru |
| `tool/run_tests.dart` | Baru |
| `test_progress.md` | Di-generate saat runtime |
| `test_report.md` | Di-generate saat runtime |

---

## Out of Scope

- Integration test (butuh emulator + Supabase test instance) — planned untuk fase berikutnya
- CI/CD pipeline (GitHub Actions) — bisa ditambah setelah suite stabil
- Performance testing
- Screenshot testing
