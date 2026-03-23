# Spec: Automated Testing Suite — Unit + Widget Tests

**Tanggal:** 2026-03-23
**Status:** Final

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
| `mocktail ^0.3.0` | Mock class untuk Dart (ditambah ke `dev_dependencies`) |
| `dart run tool/run_tests.dart` | Script custom runner |

**Tambah ke `pubspec.yaml` dev_dependencies:**
```yaml
dev_dependencies:
  mocktail: ^0.3.0
```

---

## `FakeSupabaseClient` — Mock Strategy

`SupabaseClient` dan `GoTrueClient` adalah concrete class — `mocktail` tidak bisa mock langsung. Gunakan manual stub dengan hierarki dua level:

```dart
// test/helpers/mock_providers.dart

// Stub auth client: currentUser = null agar semua private provider yang cek
// `client.auth.currentUser?.id == null` langsung return early tanpa DB call
class FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => FakeGoTrueClient();
}
```

`supabaseClientProvider` harus selalu di-override di widget tests karena tanpa override, `Supabase.instance.client` akan throw (Supabase tidak diinisialisasi di `flutter test`). Semua widget tests wajib include override ini:

```dart
supabaseClientProvider.overrideWithValue(FakeSupabaseClient()),
```

**Kenapa `auth` perlu di-stub?** Beberapa screen mendefinisikan private provider di file screen mereka sendiri (contoh: `_adminPhoneProvider` di `layanan_screen.dart`). Provider private tidak bisa di-override dari luar file, sehingga saat widget di-pump, provider tersebut mengakses `client.auth.currentUser?.id`. Jika `auth` melempar `UnimplementedError` (perilaku default `Fake`), test crash sebelum widget selesai render. Dengan meng-stub `auth` → `FakeGoTrueClient` yang mengembalikan `currentUser = null`, semua provider dengan pola `if (userId == null) return null/[]` keluar lebih awal secara aman.

Karena semua feature provider yang di-list di `mockOverrides()` di-override dengan data fixture, `FakeSupabaseClient` tidak pernah benar-benar dipanggil untuk provider tersebut — override ini hanya menjaga private/unoveridable providers tidak crash.

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
      family_member_model_test.dart
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
    mock_providers.dart    ← FakeSupabaseClient + override factory
    test_data.dart         ← fixture data untuk semua model

tool/
  run_tests.dart           ← script runner (buat direktori tool/ terlebih dahulu)

test_progress.md           ← live progress (root project, di-generate saat runtime)
test_report.md             ← final report (root project, di-generate saat runtime)
```

---

## Unit Tests — Models

Setiap model test file mencakup:

1. **`fromMap` parses correctly** — semua field terparsing dengan benar dari map valid
2. **`fromMap` handles nulls** — field nullable tidak crash saat null
3. **Computed getters** — label, status, isActive, dll. return nilai yang benar
4. **`toMap`** — output map sesuai untuk DB insert, termasuk conditional fields

**12 Model yang di-test:**

| Model | File | Edge Case Utama |
|---|---|---|
| `InvoiceModel` | `invoice_model_test.dart` | status labels, amount parsing |
| `ResidentModel` | `resident_model_test.dart` | unit_number, status |
| `ExpenseModel` | `expense_model_test.dart` | category null fallback |
| `BillingTypeModel` | `billing_type_model_test.dart` | amount, type |
| `AnnouncementModel` | `announcement_model_test.dart` | created_at parsing |
| `ComplaintModel` | `complaint_model_test.dart` | categoryLabel, statusLabel |
| `LetterRequestModel` | `letter_request_model_test.dart` | progressPercent, isActive |
| `CommunityContactModel` | `community_contact_model_test.dart` | initials getter |
| `MarketplaceListingModel` | `marketplace_listing_model_test.dart` | price, seller |
| `NotificationModel` | `notification_model_test.dart` | isRead, type |
| `ReportModel` | `report_model_test.dart` | totals parsing |
| `FamilyMember` | `family_member_model_test.dart` | `nik?.isEmpty == true ? null : nik` |

> `register_step1_data.dart` dikecualikan — bukan DB model (tidak ada `fromMap`).

---

## Widget Tests — Screens

**Mock pattern standard:**
```dart
testWidgets('description', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: mockOverrides(/* data */) ,
      child: const MaterialApp(home: TheScreen()),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Expected Text'), findsOneWidget);
});
```

**Provider types matter untuk overrides.** Tiga provider pakai `AsyncNotifierProvider` — tidak bisa di-override dengan lambda. Butuh stub notifier class:

```dart
// Stub notifiers untuk AsyncNotifierProvider
// Letakkan di test/helpers/mock_providers.dart

class FakeInvoiceListNotifier extends InvoiceListNotifier {
  final List<InvoiceModel> _data;
  FakeInvoiceListNotifier(this._data);
  @override
  Future<List<InvoiceModel>> build() async => _data;
}

class FakeExpensesNotifier extends ExpensesNotifier {
  @override
  Future<List<ExpenseModel>> build() async => [];
}

class FakeBillingTypesNotifier extends BillingTypesNotifier {
  @override
  Future<List<BillingTypeModel>> build() async => [];
}

// ReportNotifier adalah NotifierProvider — stub-nya tidak memanggil loadReportData()
// agar tidak ada dependency ke supabaseClientProvider atau currentProfileProvider.
// ReportState memiliki required fields: selectedMonth, selectedYear, currentMonthReport, lastSixMonths.
class FakeReportNotifier extends ReportNotifier {
  @override
  ReportState build() => ReportState(
    selectedMonth: DateTime.now().month,
    selectedYear: DateTime.now().year,
    currentMonthReport: MonthlyReport(
      month: DateTime.now().month,
      year: DateTime.now().year,
      totalIncome: 0,
      totalExpected: 0,
      totalExpense: 0,
    ),
    lastSixMonths: [],
  );
}
```

**`mockOverrides()` factory** di `test/helpers/mock_providers.dart`:

```dart
List<Override> mockOverrides({
  List<InvoiceModel> invoices = const [],
  List<ResidentModel> residents = const [],
  Map<String, dynamic> dashboardData = const {},
  List<AnnouncementModel> announcements = const [],
  List<MarketplaceListingModel> listings = const [],
  List<CommunityContactModel> contacts = const [],
  List<LetterRequestModel> letterRequests = const [],
  List<ComplaintModel> complaints = const [],
  List<InvoiceModel> residentInvoices = const [],
}) {
  return [
    supabaseClientProvider.overrideWithValue(FakeSupabaseClient()),

    // FutureProvider.autoDispose — lambda syntax valid
    residentsProvider.overrideWith((_) async => residents),
    // dashboardProvider didefinisikan di dalam file screen (bukan di providers/) — ini by design di codebase ini
    dashboardProvider.overrideWith((_) async => dashboardData), // import dari lib/features/dashboard/screens/admin_dashboard_screen.dart
    // invoiceWithResidentProvider (bukan invoiceListProvider) yang di-watch langsung oleh InvoicesScreen
    invoiceWithResidentProvider.overrideWith((_) async => []),
    announcementsProvider.overrideWith((_) async => announcements),
    marketplaceListingsProvider.overrideWith((_) async => listings),
    communityContactsProvider.overrideWith((_) async => contacts),
    adminContactsProvider.overrideWith((_) async => contacts),
    myLetterRequestsProvider.overrideWith((_) async => letterRequests),
    myComplaintsProvider.overrideWith((_) async => complaints),
    adminLetterRequestsProvider.overrideWith((_) async => []),  // untuk AdminRequestsScreen (gap checklist)
    adminComplaintsProvider.overrideWith((_) async => []),      // untuk AdminComplaintsScreen (gap checklist)
    residentInvoicesProvider.overrideWith((_) async => residentInvoices),
    currentResidentProfileProvider.overrideWith((_) async => null), // untuk ResidentHomeScreen
    // residentTotalPendingInvoicesProvider adalah Provider.autoDispose<double> sinkron yang
    // men-derive nilai dari residentInvoicesProvider.value ?? []. Karena residentInvoicesProvider
    // di-override ke [], provider ini resolve ke 0.0 tanpa Supabase call — tidak perlu di-override.
    // unreadCountProvider (dari notifications_provider.dart) juga di-watch ResidentHomeScreen.
    // Tidak perlu di-override: provider ini punya guard `if (userId == null) return 0`,
    // yang terpenuhi oleh FakeGoTrueClient.currentUser == null.
    // Jika test tetap crash, tambah: unreadCountProvider.overrideWith((_) async => 0)

    // AsyncNotifierProvider — wajib pakai stub notifier subclass
    invoiceListProvider.overrideWith(() => FakeInvoiceListNotifier(invoices)),
    expensesProvider.overrideWith(() => FakeExpensesNotifier()),
    billingTypesProvider.overrideWith(() => FakeBillingTypesNotifier()),

    // NotifierProvider — stub agar tidak memanggil loadReportData/supabase
    reportProvider.overrideWith(() => FakeReportNotifier()),
  ];
}
```

> `adminLetterRequestsProvider` dan `adminComplaintsProvider` di-include di `mockOverrides()` agar test yang ditambahkan saat mengikuti gap checklist (AdminRequestsScreen, AdminComplaintsScreen) tidak perlu mengubah factory ini.

> `currentResidentProfileProvider` di-override dengan `null` karena `ResidentHomeScreen` menampilkan UI empty/loading state saat profile null.

**Import paths yang dibutuhkan di `mock_providers.dart`:**
- `package:supabase_flutter/supabase_flutter.dart` → `GoTrueClient`, `User`
- `lib/core/supabase/supabase_client.dart` → `supabaseClientProvider`
- `lib/features/invoices/providers/invoice_list_provider.dart` → `invoiceListProvider`, `invoiceWithResidentProvider`, `InvoiceListNotifier`
- `lib/features/residents/providers/resident_provider.dart` → `residentsProvider`
- `lib/features/dashboard/screens/admin_dashboard_screen.dart` → `dashboardProvider`
- `lib/features/expenses/providers/expense_provider.dart` → `expensesProvider`, `ExpensesNotifier`
- `lib/features/invoices/providers/billing_type_provider.dart` → `billingTypesProvider`, `BillingTypesNotifier`
- `lib/features/announcements/providers/announcement_provider.dart` → `announcementsProvider`
- `lib/features/marketplace/providers/marketplace_provider.dart` → `marketplaceListingsProvider`
- `lib/features/layanan/providers/layanan_provider.dart` → `communityContactsProvider`, `adminContactsProvider`, `myLetterRequestsProvider`, `myComplaintsProvider`, `adminLetterRequestsProvider`, `adminComplaintsProvider`
- `lib/features/resident_portal/providers/resident_invoices_provider.dart` → `residentInvoicesProvider`, `currentResidentProfileProvider`
- `lib/features/reports/providers/report_provider.dart` → `reportProvider`, `ReportNotifier`, `ReportState`

**12 Screen yang di-test:**

| Screen | Assertions Utama |
|---|---|
| `LoginScreen` | Email field, password field, tombol Login render |
| `AdminDashboardScreen` | "Aksi Cepat" text, grid render |
| `ResidentsScreen` | Search bar, list/empty state |
| `InvoicesScreen` | Filter chips, list/empty state |
| `ExpensesScreen` | FAB present |
| `LayananScreen` | Tab "Surat", "Pengaduan", "Kontak" |
| `AdminContactsScreen` | FAB present, empty state render |
| `AnnouncementsScreen` | List/empty state |
| `MarketplaceScreen` | Grid/empty state |
| `ReportsScreen` | Render tanpa crash |
| `ResidentHomeScreen` | Render tanpa crash |
| `ResidentInvoicesScreen` | List/empty state |

---

## `tool/run_tests.dart` — Script Runner

### Cara Jalankan:
```bash
dart run tool/run_tests.dart
```

### Alur:
1. Buat/reset `test_progress.md` dengan semua baris kosong
2. Loop setiap test file satu per satu:
   - Update baris → `⏳ sedang berjalan...`
   - Jalankan: `Process.run('flutter', ['test', filePath, '--reporter', 'json'], runInShell: true)`
   - Parse output: `--reporter json` menghasilkan **newline-delimited JSON** (satu JSON object per baris). Parse `stdout` line-by-line, filter event dengan `type == 'testDone'` dan `type == 'error'`
   - Update baris → `✅` atau `❌`
3. Jalankan **gap analysis** (lihat bagian bawah)
4. Generate `test_report.md`

> **Windows:** Wajib `runInShell: true` agar `flutter` ditemukan via PATH.

### Parsing `--reporter json`:

```dart
final lines = result.stdout.toString().split('\n');
for (final line in lines) {
  if (line.trim().isEmpty) continue;
  final event = jsonDecode(line);
  // 'failure' = expect() gagal, 'error' = unhandled exception — keduanya harus ditangkap
  if (event['type'] == 'testDone' &&
      (event['result'] == 'failure' || event['result'] == 'error')) {
    // test gagal
  }
  if (event['type'] == 'error') {
    // error message detail
  }
}
```

---

## Gap Analysis Algorithm

Dijalankan setelah semua test selesai:

**1. Model gap scan:**
- Scan semua file di `lib/features/**/models/*.dart`
- Exclude: file yang tidak mengandung string `fromMap` (e.g., `register_step1_data.dart`)
- Untuk setiap `foo_model.dart`, cek apakah `test/unit/models/foo_model_test.dart` ada
- Kalau tidak ada → masuk checklist: "Belum ada unit test untuk FooModel"

**2. Screen gap scan:**
- Scan semua file di `lib/features/**/screens/*.dart`
- Exclude:
  - File yang mengandung string `part of`
  - Semua file di `auth/screens/` **kecuali** `login_screen.dart` (register, pending-approval, forgot/reset password di-exclude dari scope testing ini)
- Untuk setiap `foo_screen.dart`, cek apakah `test/widget/screens/foo_screen_test.dart` ada
- Kalau tidak ada → masuk checklist: "Belum ada widget test untuk FooScreen"

**3. Form validation gap:**
- Untuk setiap screen test yang ada, cek apakah mengandung string `validator` atau `validate`
- Kalau tidak ada dan screen source-nya mengandung `TextFormField` → masuk checklist: "Belum ada test form validation di FooScreen"

---

## Format `test_progress.md` (live)

```markdown
# Test Progress — YYYY-MM-DD HH:mm:ss

## Unit Tests — Models (0/12 selesai)
| Model | Status |
|---|---|
| InvoiceModel | ✅ |
| ResidentModel | ⏳ sedang berjalan... |
| ExpenseModel | |
| FamilyMember | |
...

## Widget Tests — Screens (0/12 selesai)
| Screen | Status |
|---|---|
| LoginScreen | |
...
```

---

## Format `test_report.md` (final)

```markdown
# Test Report — YYYY-MM-DD HH:mm:ss

## Ringkasan
- ✅ Passed: X/Y
- ❌ Failed: N/Y

## Error Detail

### ❌ ExpenseModel — fromMap null handling
**File:** test/unit/models/expense_model_test.dart:23
**Error:** `type 'Null' is not a subtype of type 'String'`
**Saran:** Tambah fallback `map['category'] as String? ?? 'lainnya'`

## Gap Checklist
- [ ] AdminComplaintsScreen belum ada widget test
- [ ] AdminRequestsScreen belum ada widget test
- [ ] AddEditResidentScreen belum ada test form validation
```

---

## Saran Upgrade — Pola Deteksi Error

| Pola Error | Saran Otomatis |
|---|---|
| `type 'Null' is not a subtype` | Tambah null fallback di `fromMap` untuk field yang crash |
| `No element` / `findsNothing` | Cek widget key atau text yang dicari di assertion |
| `ProviderException` / `StateError` | Pastikan provider di-override di `mockOverrides()` |
| `Supabase has not been initialized` | Tambah `supabaseClientProvider.overrideWithValue(FakeSupabaseClient())` |

---

## File yang Dibuat / Diubah

| File | Aksi |
|---|---|
| `pubspec.yaml` | Edit — tambah `mocktail: ^0.3.0` ke dev_dependencies |
| `test/helpers/mock_providers.dart` | Baru |
| `test/helpers/test_data.dart` | Baru |
| `test/unit/models/*.dart` (12 file) | Baru |
| `test/widget/screens/*.dart` (12 file) | Baru |
| `tool/run_tests.dart` | Baru (buat direktori `tool/` terlebih dahulu) |
| `test_progress.md` | Di-generate saat runtime |
| `test_report.md` | Di-generate saat runtime |

---

## Out of Scope

- Integration test (butuh emulator + Supabase test instance) — planned fase berikutnya
- CI/CD pipeline (GitHub Actions)
- Performance testing
- Screenshot testing
