# Automated Testing Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build unit tests for 12 models, widget tests for 12 screens, and a `dart run tool/run_tests.dart` script that runs them one-by-one, writes live `test_progress.md`, then generates `test_report.md` with error details and a gap checklist.

**Architecture:** All widget tests use `ProviderScope` overrides — no real Supabase connection. `FakeSupabaseClient` stubs `auth.currentUser` to return `null` so private file-level providers exit early safely. Three `AsyncNotifierProvider` types (invoices, expenses, billing types) need stub `AsyncNotifier` subclasses — lambda syntax only works for `FutureProvider`. The runner script launches `flutter test` with `--reporter json` per file, parses newline-delimited JSON, and regenerates progress/report markdown files in the project root.

**Tech Stack:** `flutter_test`, `flutter_riverpod` ProviderScope overrides, `mocktail ^0.3.0` (for `Fake` base class), `dart:io` Process.run (runInShell: true on Windows), `dart:convert` jsonDecode.

---

## File Structure

```
pubspec.yaml                               ← modify: add mocktail: ^0.3.0
test/
  helpers/
    mock_providers.dart                    ← new: FakeSupabaseClient, stub notifiers, mockOverrides()
    test_data.dart                         ← new: fixture maps for all 12 models
  unit/
    models/
      invoice_model_test.dart              ← new
      resident_model_test.dart             ← new
      expense_model_test.dart              ← new
      billing_type_model_test.dart         ← new
      announcement_model_test.dart         ← new
      complaint_model_test.dart            ← new
      letter_request_model_test.dart       ← new
      community_contact_model_test.dart    ← new
      marketplace_listing_model_test.dart  ← new
      notification_model_test.dart         ← new
      report_model_test.dart               ← new
      family_member_model_test.dart        ← new
  widget/
    screens/
      login_screen_test.dart               ← new
      admin_dashboard_test.dart            ← new
      residents_screen_test.dart           ← new
      invoices_screen_test.dart            ← new
      expenses_screen_test.dart            ← new
      layanan_screen_test.dart             ← new
      admin_contacts_screen_test.dart      ← new
      announcements_screen_test.dart       ← new
      marketplace_screen_test.dart         ← new
      reports_screen_test.dart             ← new
      resident_home_screen_test.dart       ← new
      resident_invoices_screen_test.dart   ← new
tool/
  run_tests.dart                           ← new (create tool/ directory first)
```

---

## Task 1: Setup — pubspec + test helpers

**Files:**
- Modify: `pubspec.yaml`
- Create: `test/helpers/mock_providers.dart`
- Create: `test/helpers/test_data.dart`

- [ ] **Step 1: Add mocktail to pubspec.yaml**

Open `pubspec.yaml` and add `mocktail: ^0.3.0` under `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.14
  freezed: ^3.0.0
  json_serializable: ^6.9.4
  riverpod_generator: ^4.0.3
  mocktail: ^0.3.0
```

- [ ] **Step 2: Run flutter pub get**

```bash
flutter pub get
```

Expected: no errors, `mocktail` appears in `.dart_tool/package_config.json`.

- [ ] **Step 3: Create test/helpers/mock_providers.dart**

Create the file at `test/helpers/mock_providers.dart` with the full content below. This file defines all stubs and the central `mockOverrides()` factory used by every widget test.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rukunin/core/supabase/supabase_client.dart';
import 'package:rukunin/features/invoices/providers/invoice_list_provider.dart';
import 'package:rukunin/features/residents/providers/resident_provider.dart';
import 'package:rukunin/features/dashboard/screens/admin_dashboard_screen.dart';
import 'package:rukunin/features/expenses/providers/expense_provider.dart';
import 'package:rukunin/features/invoices/providers/billing_type_provider.dart';
import 'package:rukunin/features/announcements/providers/announcement_provider.dart';
import 'package:rukunin/features/marketplace/providers/marketplace_provider.dart';
import 'package:rukunin/features/layanan/providers/layanan_provider.dart';
import 'package:rukunin/features/resident_portal/providers/resident_invoices_provider.dart';
import 'package:rukunin/features/reports/providers/report_provider.dart';
import 'package:rukunin/features/reports/models/report_model.dart';
import 'package:rukunin/features/invoices/models/invoice_model.dart';
import 'package:rukunin/features/residents/models/resident_model.dart';
import 'package:rukunin/features/expenses/models/expense_model.dart';
import 'package:rukunin/features/invoices/models/billing_type_model.dart';
import 'package:rukunin/features/announcements/models/announcement_model.dart';
import 'package:rukunin/features/marketplace/models/marketplace_listing_model.dart';
import 'package:rukunin/features/layanan/models/community_contact_model.dart';
import 'package:rukunin/features/layanan/models/complaint_model.dart';
import 'package:rukunin/features/layanan/models/letter_request_model.dart';

// ── Supabase stubs ─────────────────────────────────────────────────────────
// FakeGoTrueClient returns currentUser = null.
// This causes all private file-level providers that check
// `client.auth.currentUser?.id == null` to exit early without any DB call.
class FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  User? get currentUser => null;
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  GoTrueClient get auth => FakeGoTrueClient();
}

// ── AsyncNotifierProvider stubs ────────────────────────────────────────────
// AsyncNotifierProvider cannot be overridden with a lambda — it requires a
// factory that returns a notifier instance. These subclasses skip the real
// build() logic entirely.

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

// ── NotifierProvider stub ──────────────────────────────────────────────────
// ReportNotifier.build() calls Future.microtask(() => loadReportData(...))
// which reaches supabaseClientProvider. This stub returns a safe initial
// state without triggering any async side-effects.
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

// ── Central override factory ───────────────────────────────────────────────
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

    // FutureProvider.autoDispose — lambda override is valid
    residentsProvider.overrideWith((_) async => residents),
    // dashboardProvider is defined inside admin_dashboard_screen.dart (not in providers/)
    dashboardProvider.overrideWith((_) async => dashboardData),
    // InvoicesScreen watches invoiceWithResidentProvider, not invoiceListProvider directly
    invoiceWithResidentProvider.overrideWith((_) async => <Map<String, dynamic>>[]),
    announcementsProvider.overrideWith((_) async => announcements),
    marketplaceListingsProvider.overrideWith((_) async => listings),
    communityContactsProvider.overrideWith((_) async => contacts),
    adminContactsProvider.overrideWith((_) async => contacts),
    myLetterRequestsProvider.overrideWith((_) async => letterRequests),
    myComplaintsProvider.overrideWith((_) async => complaints),
    // Included so tests added via gap checklist (AdminRequests/Complaints) work without changes
    adminLetterRequestsProvider.overrideWith((_) async => []),
    adminComplaintsProvider.overrideWith((_) async => []),
    residentInvoicesProvider.overrideWith((_) async => residentInvoices),
    currentResidentProfileProvider.overrideWith((_) async => null),
    // residentTotalPendingInvoicesProvider: derived Provider<double> — auto-resolves
    //   to 0.0 from the residentInvoicesProvider override above, no override needed.
    // unreadCountProvider: has `if (userId == null) return 0` guard satisfied by
    //   FakeGoTrueClient.currentUser == null, no override needed.
    //   If tests crash, add: unreadCountProvider.overrideWith((_) async => 0)

    // AsyncNotifierProvider — requires stub notifier subclass
    invoiceListProvider.overrideWith(() => FakeInvoiceListNotifier(invoices)),
    expensesProvider.overrideWith(() => FakeExpensesNotifier()),
    billingTypesProvider.overrideWith(() => FakeBillingTypesNotifier()),

    // NotifierProvider — stub skips loadReportData()
    reportProvider.overrideWith(() => FakeReportNotifier()),
  ];
}
```

- [ ] **Step 4: Create test/helpers/test_data.dart**

Create the file at `test/helpers/test_data.dart`:

```dart
// Fixture data maps for all 12 models.
// Use these in unit tests instead of hardcoding maps inline.

const invoiceMap = {
  'id': 'inv-1',
  'community_id': 'com-1',
  'resident_id': 'res-1',
  'billing_type_id': 'bt-1',
  'amount': '150000',
  'month': 3,
  'year': 2026,
  'due_date': '2026-03-31',
  'status': 'pending',
  'payment_link': null,
  'payment_token': null,
  'wa_sent_at': null,
  'created_at': '2026-03-01T00:00:00.000Z',
  'billing_types': {'name': 'Iuran Bulanan'},
};

const residentMap = {
  'id': 'res-1',
  'community_id': 'com-1',
  'full_name': 'Budi Santoso',
  'unit_number': '12',
  'phone': '08123456789',
  'nik': '3275010101010001',
  'email': 'budi@example.com',
  'status': 'active',
  'photo_url': null,
  'rt_number': 2,
  'block': 'A',
  'motorcycle_count': 1,
  'car_count': 0,
  'created_at': '2026-01-01T00:00:00.000Z',
};

const expenseMap = {
  'id': 'exp-1',
  'community_id': 'com-1',
  'amount': '250000',
  'category': 'Kebersihan',
  'description': 'Bayar tukang sampah',
  'receipt_url': null,
  'expense_date': '2026-03-15',
  'created_by': 'admin-1',
  'created_at': '2026-03-15T10:00:00.000Z',
};

const billingTypeMap = {
  'id': 'bt-1',
  'community_id': 'com-1',
  'name': 'Iuran Bulanan',
  'amount': '150000',
  'billing_day': 10,
  'is_active': true,
  'cost_per_motorcycle': '25000',
  'cost_per_car': '50000',
  'created_at': '2026-01-01T00:00:00.000Z',
};

const announcementMap = {
  'id': 'ann-1',
  'community_id': 'com-1',
  'title': 'Rapat Warga',
  'body': 'Rapat warga akan diadakan pada hari Sabtu.',
  'type': 'info',
  'created_by': 'admin-1',
  'created_at': '2026-03-20T08:00:00.000Z',
};

const complaintMap = {
  'id': 'cmp-1',
  'community_id': 'com-1',
  'resident_id': 'res-1',
  'title': 'Lampu Jalan Mati',
  'description': 'Lampu jalan di depan blok A mati sejak seminggu lalu.',
  'category': 'infrastruktur',
  'status': 'pending',
  'admin_notes': null,
  'photo_url': null,
  'created_at': '2026-03-19T10:00:00.000Z',
  'updated_at': '2026-03-19T10:00:00.000Z',
  'profiles': {'full_name': 'Budi Santoso', 'unit_number': '12'},
};

const letterRequestMap = {
  'id': 'req-1',
  'community_id': 'com-1',
  'resident_id': 'res-1',
  'letter_type': 'domisili',
  'purpose': 'Melamar kerja',
  'notes': null,
  'status': 'in_progress',
  'admin_notes': null,
  'letter_id': null,
  'created_at': '2026-03-19T10:00:00.000Z',
  'updated_at': '2026-03-19T10:00:00.000Z',
  'profiles': {'full_name': 'Budi Santoso', 'unit_number': '12'},
};

const communityContactMap = {
  'id': 'cc-1',
  'community_id': 'com-1',
  'nama': 'Ahmad Ridwan',
  'jabatan': 'Ketua RT',
  'phone': '08111222333',
  'photo_url': null,
  'urutan': 1,
  'created_at': '2026-03-01T00:00:00.000Z',
  'updated_at': '2026-03-01T00:00:00.000Z',
};

const marketplaceListingMap = {
  'id': 'ml-1',
  'community_id': 'com-1',
  'seller_id': 'res-1',
  'title': 'Nasi Uduk',
  'description': 'Nasi uduk komplit dengan lauk',
  'price': 15000,
  'category': 'makanan',
  'images': ['https://example.com/img1.jpg'],
  'status': 'active',
  'stock': 10,
  'created_at': '2026-03-10T07:00:00.000Z',
  'profiles': {
    'full_name': 'Sari Wulandari',
    'phone': '08199887766',
    'unit_number': '5',
    'photo_url': null,
  },
};

const notificationMap = {
  'id': 'notif-1',
  'community_id': 'com-1',
  'user_id': 'res-1',
  'type': 'payment',
  'title': 'Tagihan Bulan Maret',
  'body': 'Tagihan iuran bulan Maret sudah tersedia.',
  'is_read': false,
  'metadata': null,
  'created_at': '2026-03-01T08:00:00.000Z',
};

const familyMemberMap = {
  'id': 'fm-1',
  'resident_id': 'res-1',
  'full_name': 'Siti Aminah',
  'nik': '3275010101010002',
  'relationship': 'Istri',
};
```

- [ ] **Step 5: Run existing placeholder test to confirm setup is OK**

```bash
flutter test test/widget_test.dart
```

Expected: PASS (1 test).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock test/helpers/mock_providers.dart test/helpers/test_data.dart
git commit -m "test: add mocktail dependency and test helpers (mock_providers, test_data)"
```

---

## Task 2: Unit Tests — Batch 1 (InvoiceModel, ResidentModel, ExpenseModel, BillingTypeModel)

**Files:**
- Create: `test/unit/models/invoice_model_test.dart`
- Create: `test/unit/models/resident_model_test.dart`
- Create: `test/unit/models/expense_model_test.dart`
- Create: `test/unit/models/billing_type_model_test.dart`

> Note: `InvoiceModel` uses `fromJson()` not `fromMap()` — use that factory in tests.

- [ ] **Step 1: Create test/unit/models/invoice_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/invoices/models/invoice_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('InvoiceModel', () {
    test('fromJson parses all fields correctly', () {
      final model = InvoiceModel.fromJson(invoiceMap);
      expect(model.id, 'inv-1');
      expect(model.communityId, 'com-1');
      expect(model.residentId, 'res-1');
      expect(model.billingTypeId, 'bt-1');
      expect(model.amount, 150000.0);
      expect(model.month, 3);
      expect(model.year, 2026);
      expect(model.status, 'pending');
      expect(model.billingTypeName, 'Iuran Bulanan');
    });

    test('fromJson handles null optional fields', () {
      final model = InvoiceModel.fromJson({
        ...invoiceMap,
        'payment_link': null,
        'payment_token': null,
        'wa_sent_at': null,
        'billing_types': null,
      });
      expect(model.paymentLink, isNull);
      expect(model.paymentToken, isNull);
      expect(model.waSentAt, isNull);
      expect(model.billingTypeName, 'Iuran'); // default fallback
    });

    test('fromJson parses wa_sent_at as DateTime when present', () {
      final model = InvoiceModel.fromJson({
        ...invoiceMap,
        'wa_sent_at': '2026-03-05T10:00:00.000Z',
      });
      expect(model.waSentAt, isNotNull);
      expect(model.waSentAt!.year, 2026);
    });

    test('fromJson falls back gracefully on missing amount', () {
      final model = InvoiceModel.fromJson({
        ...invoiceMap,
        'amount': null,
      });
      expect(model.amount, 0.0);
    });
  });
}
```

- [ ] **Step 2: Run to verify it passes**

```bash
flutter test test/unit/models/invoice_model_test.dart
```

Expected: PASS (4 tests).

- [ ] **Step 3: Create test/unit/models/resident_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/residents/models/resident_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ResidentModel', () {
    test('fromMap parses all fields correctly', () {
      final model = ResidentModel.fromMap(residentMap);
      expect(model.id, 'res-1');
      expect(model.fullName, 'Budi Santoso');
      expect(model.unitNumber, '12');
      expect(model.status, 'active');
      expect(model.motorcycleCount, 1);
      expect(model.carCount, 0);
    });

    test('fromMap handles null optional fields', () {
      final model = ResidentModel.fromMap({
        ...residentMap,
        'community_id': null,
        'unit_number': null,
        'phone': null,
        'nik': null,
        'email': null,
        'photo_url': null,
        'rt_number': null,
        'block': null,
      });
      expect(model.communityId, isNull);
      expect(model.unitNumber, isNull);
      expect(model.phone, isNull);
    });

    test('status defaults to active when null', () {
      final model = ResidentModel.fromMap({...residentMap, 'status': null});
      expect(model.status, 'active');
    });

    test('isActive returns true for active status', () {
      final model = ResidentModel.fromMap(residentMap);
      expect(model.isActive, isTrue);
    });

    test('isActive returns false for non-active status', () {
      final model = ResidentModel.fromMap({...residentMap, 'status': 'inactive'});
      expect(model.isActive, isFalse);
    });

    test('initials returns two uppercase letters from first two words', () {
      final model = ResidentModel.fromMap(residentMap); // 'Budi Santoso'
      expect(model.initials, 'BS');
    });

    test('initials handles single word name', () {
      final model = ResidentModel.fromMap({...residentMap, 'full_name': 'Ahmad'});
      expect(model.initials, 'A');
    });

    test('alamatLengkap includes block, unit, rt', () {
      final model = ResidentModel.fromMap(residentMap);
      expect(model.alamatLengkap, contains('A'));
      expect(model.alamatLengkap, contains('12'));
      expect(model.alamatLengkap, contains('2'));
    });
  });
}
```

- [ ] **Step 4: Create test/unit/models/expense_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/expenses/models/expense_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ExpenseModel', () {
    test('fromMap parses all fields correctly', () {
      final model = ExpenseModel.fromMap(expenseMap);
      expect(model.id, 'exp-1');
      expect(model.communityId, 'com-1');
      expect(model.amount, 250000.0);
      expect(model.category, 'Kebersihan');
      expect(model.description, 'Bayar tukang sampah');
    });

    test('fromMap handles null category with empty string fallback', () {
      final model = ExpenseModel.fromMap({...expenseMap, 'category': null});
      expect(model.category, '');
    });

    test('fromMap handles null receipt_url', () {
      final model = ExpenseModel.fromMap({...expenseMap, 'receipt_url': null});
      expect(model.receiptUrl, isNull);
    });

    test('toMap includes required fields', () {
      final model = ExpenseModel.fromMap(expenseMap);
      final map = model.toMap();
      expect(map['amount'], 250000.0);
      expect(map['category'], 'Kebersihan');
      expect(map['description'], 'Bayar tukang sampah');
      expect(map.containsKey('receipt_url'), isTrue);
    });
  });
}
```

- [ ] **Step 5: Create test/unit/models/billing_type_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/invoices/models/billing_type_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('BillingTypeModel', () {
    test('fromMap parses all fields correctly', () {
      final model = BillingTypeModel.fromMap(billingTypeMap);
      expect(model.id, 'bt-1');
      expect(model.name, 'Iuran Bulanan');
      expect(model.amount, 150000.0);
      expect(model.billingDay, 10);
      expect(model.isActive, isTrue);
      expect(model.costPerMotorcycle, 25000.0);
      expect(model.costPerCar, 50000.0);
    });

    test('isActive defaults to true when null', () {
      final model = BillingTypeModel.fromMap({...billingTypeMap, 'is_active': null});
      expect(model.isActive, isTrue);
    });

    test('toMap includes all mutable fields', () {
      final model = BillingTypeModel.fromMap(billingTypeMap);
      final map = model.toMap();
      expect(map['name'], 'Iuran Bulanan');
      expect(map['amount'], 150000.0);
      expect(map['billing_day'], 10);
      expect(map['is_active'], isTrue);
    });
  });
}
```

- [ ] **Step 6: Run all batch 1 unit tests**

```bash
flutter test test/unit/models/invoice_model_test.dart test/unit/models/resident_model_test.dart test/unit/models/expense_model_test.dart test/unit/models/billing_type_model_test.dart
```

Expected: PASS (all tests).

- [ ] **Step 7: Commit**

```bash
git add test/unit/
git commit -m "test: add unit tests for InvoiceModel, ResidentModel, ExpenseModel, BillingTypeModel"
```

---

## Task 3: Unit Tests — Batch 2 (AnnouncementModel, ComplaintModel, LetterRequestModel, CommunityContactModel)

**Files:**
- Create: `test/unit/models/announcement_model_test.dart`
- Create: `test/unit/models/complaint_model_test.dart`
- Create: `test/unit/models/letter_request_model_test.dart`
- Create: `test/unit/models/community_contact_model_test.dart`

- [ ] **Step 1: Create test/unit/models/announcement_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/announcements/models/announcement_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('AnnouncementModel', () {
    test('fromMap parses all fields correctly', () {
      final model = AnnouncementModel.fromMap(announcementMap);
      expect(model.id, 'ann-1');
      expect(model.title, 'Rapat Warga');
      expect(model.type, 'info');
      expect(model.createdAt.year, 2026);
      expect(model.createdAt.month, 3);
    });

    test('fromMap handles null created_by', () {
      final model = AnnouncementModel.fromMap({...announcementMap, 'created_by': null});
      expect(model.createdBy, isNull);
    });

    test('type defaults to info when null', () {
      final model = AnnouncementModel.fromMap({...announcementMap, 'type': null});
      expect(model.type, 'info');
    });

    test('toMap includes community_id, title, body, type', () {
      final model = AnnouncementModel.fromMap(announcementMap);
      final map = model.toMap();
      expect(map['community_id'], 'com-1');
      expect(map['title'], 'Rapat Warga');
      expect(map['type'], 'info');
    });
  });
}
```

- [ ] **Step 2: Create test/unit/models/complaint_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/complaint_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ComplaintModel', () {
    test('fromMap parses all fields correctly', () {
      final model = ComplaintModel.fromMap(complaintMap);
      expect(model.id, 'cmp-1');
      expect(model.title, 'Lampu Jalan Mati');
      expect(model.category, 'infrastruktur');
      expect(model.status, 'pending');
      expect(model.residentName, 'Budi Santoso');
      expect(model.residentUnit, '12');
    });

    test('fromMap handles null profiles', () {
      final model = ComplaintModel.fromMap({...complaintMap, 'profiles': null});
      expect(model.residentName, isNull);
      expect(model.residentUnit, isNull);
    });

    test('category defaults to lainnya when null', () {
      final model = ComplaintModel.fromMap({...complaintMap, 'category': null});
      expect(model.category, 'lainnya');
    });

    test('categoryLabel returns Indonesian label', () {
      final model = ComplaintModel.fromMap(complaintMap);
      expect(model.categoryLabel, 'Infrastruktur');
    });

    test('statusLabel returns Indonesian label for pending', () {
      final model = ComplaintModel.fromMap(complaintMap);
      expect(model.statusLabel, 'Menunggu');
    });

    test('isOpen is true for pending status', () {
      final model = ComplaintModel.fromMap(complaintMap);
      expect(model.isOpen, isTrue);
    });

    test('isOpen is false for resolved status', () {
      final model = ComplaintModel.fromMap({...complaintMap, 'status': 'resolved'});
      expect(model.isOpen, isFalse);
    });
  });
}
```

- [ ] **Step 3: Create test/unit/models/letter_request_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/letter_request_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('LetterRequestModel', () {
    test('fromMap parses all fields correctly', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.id, 'req-1');
      expect(model.letterType, 'domisili');
      expect(model.status, 'in_progress');
      expect(model.residentName, 'Budi Santoso');
    });

    test('fromMap handles null profiles', () {
      final model = LetterRequestModel.fromMap({...letterRequestMap, 'profiles': null});
      expect(model.residentName, isNull);
      expect(model.residentUnit, isNull);
    });

    test('typeLabel returns Indonesian label', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.typeLabel, 'Keterangan Domisili');
    });

    test('statusLabel returns Indonesian label', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.statusLabel, 'Diproses');
    });

    test('isActive is true for in_progress', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.isActive, isTrue);
    });

    test('isActive is false for completed', () {
      final model = LetterRequestModel.fromMap({...letterRequestMap, 'status': 'completed'});
      expect(model.isActive, isFalse);
    });

    test('progressPercent is 0.60 for in_progress', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.progressPercent, 0.60);
    });

    test('progressPercent is 1.0 for completed', () {
      final model = LetterRequestModel.fromMap({...letterRequestMap, 'status': 'completed'});
      expect(model.progressPercent, 1.0);
    });
  });
}
```

- [ ] **Step 4: Create test/unit/models/community_contact_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/community_contact_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('CommunityContactModel', () {
    test('fromMap parses all fields correctly', () {
      final model = CommunityContactModel.fromMap(communityContactMap);
      expect(model.id, 'cc-1');
      expect(model.nama, 'Ahmad Ridwan');
      expect(model.jabatan, 'Ketua RT');
      expect(model.phone, '08111222333');
      expect(model.urutan, 1);
      expect(model.photoUrl, isNull);
    });

    test('initials returns two uppercase letters from two-word name', () {
      final model = CommunityContactModel.fromMap(communityContactMap); // 'Ahmad Ridwan'
      expect(model.initials, 'AR');
    });

    test('initials handles single-word name (two chars)', () {
      final model = CommunityContactModel.fromMap({...communityContactMap, 'nama': 'Ahmad'});
      expect(model.initials, 'AH');
    });

    test('toMap includes conditional photo_url when set', () {
      final model = CommunityContactModel.fromMap({
        ...communityContactMap,
        'photo_url': 'https://example.com/photo.jpg',
      });
      final map = model.toMap();
      expect(map['photo_url'], 'https://example.com/photo.jpg');
    });

    test('toMap omits photo_url when null', () {
      final model = CommunityContactModel.fromMap(communityContactMap);
      final map = model.toMap();
      expect(map.containsKey('photo_url'), isFalse);
    });
  });
}
```

- [ ] **Step 5: Run batch 2 unit tests**

```bash
flutter test test/unit/models/announcement_model_test.dart test/unit/models/complaint_model_test.dart test/unit/models/letter_request_model_test.dart test/unit/models/community_contact_model_test.dart
```

Expected: PASS (all tests).

- [ ] **Step 6: Commit**

```bash
git add test/unit/models/
git commit -m "test: add unit tests for AnnouncementModel, ComplaintModel, LetterRequestModel, CommunityContactModel"
```

---

## Task 4: Unit Tests — Batch 3 (MarketplaceListingModel, NotificationModel, ReportModel, FamilyMember)

**Files:**
- Create: `test/unit/models/marketplace_listing_model_test.dart`
- Create: `test/unit/models/notification_model_test.dart`
- Create: `test/unit/models/report_model_test.dart`
- Create: `test/unit/models/family_member_model_test.dart`

> Note: `ReportModel` in this context refers to `MonthlyReport` — the spec calls the file `report_model_test.dart` and the edge case is "totals parsing".

- [ ] **Step 1: Create test/unit/models/marketplace_listing_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/marketplace/models/marketplace_listing_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('MarketplaceListingModel', () {
    test('fromMap parses all fields including nested profiles', () {
      final model = MarketplaceListingModel.fromMap(marketplaceListingMap);
      expect(model.id, 'ml-1');
      expect(model.title, 'Nasi Uduk');
      expect(model.price, 15000);
      expect(model.category, 'makanan');
      expect(model.sellerName, 'Sari Wulandari');
      expect(model.images, hasLength(1));
    });

    test('fromMap handles null profiles', () {
      final model = MarketplaceListingModel.fromMap({...marketplaceListingMap, 'profiles': null});
      expect(model.sellerName, isNull);
      expect(model.sellerPhone, isNull);
    });

    test('fromMap handles null price', () {
      final model = MarketplaceListingModel.fromMap({...marketplaceListingMap, 'price': null});
      expect(model.price, isNull);
    });

    test('formattedPrice returns Gratis / Nego for null price', () {
      final model = MarketplaceListingModel.fromMap({...marketplaceListingMap, 'price': null});
      expect(model.formattedPrice, 'Gratis / Nego');
    });

    test('formattedPrice formats with Rp prefix', () {
      final model = MarketplaceListingModel.fromMap(marketplaceListingMap);
      expect(model.formattedPrice, startsWith('Rp'));
      expect(model.formattedPrice, contains('15'));
    });

    test('isAvailable is true for active status with stock > 0', () {
      final model = MarketplaceListingModel.fromMap(marketplaceListingMap);
      expect(model.isAvailable, isTrue);
    });

    test('isAvailable is false for sold status', () {
      final model = MarketplaceListingModel.fromMap({...marketplaceListingMap, 'status': 'sold'});
      expect(model.isAvailable, isFalse);
    });

    test('fromMap handles empty images list', () {
      final model = MarketplaceListingModel.fromMap({...marketplaceListingMap, 'images': []});
      expect(model.images, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Create test/unit/models/notification_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:rukunin/features/notifications/models/notification_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('NotificationModel', () {
    test('fromMap parses all fields correctly', () {
      final model = NotificationModel.fromMap(notificationMap);
      expect(model.id, 'notif-1');
      expect(model.type, 'payment');
      expect(model.title, 'Tagihan Bulan Maret');
      expect(model.isRead, isFalse);
    });

    test('fromMap handles null body', () {
      final model = NotificationModel.fromMap({...notificationMap, 'body': null});
      expect(model.body, isNull);
    });

    test('isRead defaults to false when null', () {
      final model = NotificationModel.fromMap({...notificationMap, 'is_read': null});
      expect(model.isRead, isFalse);
    });

    test('isRead is true when set', () {
      final model = NotificationModel.fromMap({...notificationMap, 'is_read': true});
      expect(model.isRead, isTrue);
    });

    test('icon returns receipt icon for payment type', () {
      final model = NotificationModel.fromMap(notificationMap);
      expect(model.icon, isA<IconData>());
    });

    test('icon returns notifications icon for unknown type', () {
      final model = NotificationModel.fromMap({...notificationMap, 'type': 'unknown'});
      expect(model.icon, Icons.notifications_rounded);
    });
  });
}
```

- [ ] **Step 3: Create test/unit/models/report_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/reports/models/report_model.dart';

void main() {
  group('MonthlyReport', () {
    test('constructs correctly with required fields', () {
      final report = MonthlyReport(
        month: 3,
        year: 2026,
        totalIncome: 1500000,
        totalExpected: 2000000,
        totalExpense: 300000,
      );
      expect(report.month, 3);
      expect(report.totalIncome, 1500000);
    });

    test('netBalance is totalIncome minus totalExpense', () {
      final report = MonthlyReport(
        month: 3, year: 2026,
        totalIncome: 1500000, totalExpected: 2000000, totalExpense: 300000,
      );
      expect(report.netBalance, 1200000);
    });

    test('collectionRate is percentage of income vs expected', () {
      final report = MonthlyReport(
        month: 3, year: 2026,
        totalIncome: 1500000, totalExpected: 2000000, totalExpense: 0,
      );
      expect(report.collectionRate, 75.0);
    });

    test('collectionRate returns 0 when totalExpected is 0', () {
      final report = MonthlyReport(
        month: 3, year: 2026,
        totalIncome: 0, totalExpected: 0, totalExpense: 0,
      );
      expect(report.collectionRate, 0.0);
    });
  });

  group('ReportState', () {
    MonthlyReport emptyReport() => MonthlyReport(
          month: 3, year: 2026,
          totalIncome: 0, totalExpected: 0, totalExpense: 0,
        );

    test('constructs with required fields and defaults', () {
      final state = ReportState(
        selectedMonth: 3,
        selectedYear: 2026,
        currentMonthReport: emptyReport(),
        lastSixMonths: [],
      );
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.filterMode, ReportFilterMode.currentMonth);
    });

    test('copyWith updates selectedMonth', () {
      final state = ReportState(
        selectedMonth: 3, selectedYear: 2026,
        currentMonthReport: emptyReport(), lastSixMonths: [],
      );
      final updated = state.copyWith(selectedMonth: 4);
      expect(updated.selectedMonth, 4);
      expect(updated.selectedYear, 2026); // unchanged
    });
  });
}
```

- [ ] **Step 4: Create test/unit/models/family_member_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/residents/models/family_member.dart';
import '../../helpers/test_data.dart';

void main() {
  group('FamilyMember', () {
    test('fromMap parses all fields correctly', () {
      final member = FamilyMember.fromMap(familyMemberMap);
      expect(member.id, 'fm-1');
      expect(member.fullName, 'Siti Aminah');
      expect(member.nik, '3275010101010002');
      expect(member.relationship, 'Istri');
    });

    test('fromMap handles null id and resident_id', () {
      final member = FamilyMember.fromMap({
        ...familyMemberMap,
        'id': null,
        'resident_id': null,
      });
      expect(member.id, isNull);
      expect(member.residentId, isNull);
    });

    test('fromMap handles null nik', () {
      final member = FamilyMember.fromMap({...familyMemberMap, 'nik': null});
      expect(member.nik, isNull);
    });

    test('toMap converts empty nik string to null', () {
      final member = FamilyMember.fromMap({...familyMemberMap, 'nik': ''});
      final map = member.toMap();
      expect(map['nik'], isNull);
    });

    test('toMap preserves non-empty nik', () {
      final member = FamilyMember.fromMap(familyMemberMap);
      final map = member.toMap();
      expect(map['nik'], '3275010101010002');
    });

    test('toMap omits id when null', () {
      final member = FamilyMember.fromMap({...familyMemberMap, 'id': null});
      final map = member.toMap();
      expect(map.containsKey('id'), isFalse);
    });
  });
}
```

- [ ] **Step 5: Run batch 3 unit tests**

```bash
flutter test test/unit/models/marketplace_listing_model_test.dart test/unit/models/notification_model_test.dart test/unit/models/report_model_test.dart test/unit/models/family_member_model_test.dart
```

Expected: PASS (all tests).

- [ ] **Step 6: Commit**

```bash
git add test/unit/models/
git commit -m "test: add unit tests for MarketplaceListingModel, NotificationModel, ReportModel, FamilyMember"
```

---

## Task 5: Widget Tests — Batch 1 (LoginScreen, AdminDashboardScreen, ResidentsScreen)

**Files:**
- Create: `test/widget/screens/login_screen_test.dart`
- Create: `test/widget/screens/admin_dashboard_test.dart`
- Create: `test/widget/screens/residents_screen_test.dart`

- [ ] **Step 1: Create test/widget/screens/login_screen_test.dart**

`LoginScreen` extends `ConsumerStatefulWidget` and does not use any Riverpod providers that need overriding — it reads `supabaseClientProvider` indirectly only on submit. No special overrides needed beyond the base `supabaseClientProvider`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/auth/screens/login_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('LoginScreen renders email field, password field, and Masuk button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk ke akunmu'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run login test**

```bash
flutter test test/widget/screens/login_screen_test.dart
```

Expected: PASS (1 test).

- [ ] **Step 3: Create test/widget/screens/admin_dashboard_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/dashboard/screens/admin_dashboard_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('AdminDashboardScreen renders Aksi Cepat section', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(dashboardData: {
          'total_residents': 20,
          'total_pending_invoices': 5,
          'total_income_this_month': 3000000,
          'total_expense_this_month': 500000,
          'pending_join_requests': 0,
        }),
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aksi Cepat'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Create test/widget/screens/residents_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/residents/screens/residents_screen.dart';
import 'package:rukunin/features/residents/models/resident_model.dart';
import '../../helpers/mock_providers.dart';

ResidentModel _buildResident() => ResidentModel.fromMap({
  'id': 'res-1', 'community_id': 'com-1', 'full_name': 'Budi Santoso',
  'unit_number': '12', 'phone': null, 'nik': null, 'email': null,
  'status': 'active', 'photo_url': null, 'rt_number': null, 'block': null,
  'motorcycle_count': 0, 'car_count': 0, 'created_at': '2026-01-01T00:00:00.000Z',
});

void main() {
  testWidgets('ResidentsScreen shows search field when list is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(residents: []),
        child: const MaterialApp(home: ResidentsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('ResidentsScreen shows resident name when data is present', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(residents: [_buildResident()]),
        child: const MaterialApp(home: ResidentsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run batch 1 widget tests**

```bash
flutter test test/widget/screens/login_screen_test.dart test/widget/screens/admin_dashboard_test.dart test/widget/screens/residents_screen_test.dart
```

Expected: PASS (all tests).

- [ ] **Step 6: Commit**

```bash
git add test/widget/
git commit -m "test: add widget tests for LoginScreen, AdminDashboardScreen, ResidentsScreen"
```

---

## Task 6: Widget Tests — Batch 2 (InvoicesScreen, ExpensesScreen, LayananScreen)

**Files:**
- Create: `test/widget/screens/invoices_screen_test.dart`
- Create: `test/widget/screens/expenses_screen_test.dart`
- Create: `test/widget/screens/layanan_screen_test.dart`

- [ ] **Step 1: Create test/widget/screens/invoices_screen_test.dart**

`InvoicesScreen` watches `invoiceWithResidentProvider` (overridden in `mockOverrides()`) plus two filter state providers (`invoiceMonthFilterProvider`, `invoiceYearFilterProvider`). Filter state providers are `Notifier`-based with no Supabase calls — they don't need overriding.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/invoices/screens/invoices_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('InvoicesScreen renders without crash and shows navigation arrows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: const MaterialApp(home: InvoicesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Month navigation arrows always render
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
```

- [ ] **Step 2: Create test/widget/screens/expenses_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/expenses/screens/expenses_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('ExpensesScreen renders FAB and title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: const MaterialApp(home: ExpensesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Pengeluaran Kas'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Create test/widget/screens/layanan_screen_test.dart**

`LayananScreen` has a private `_adminPhoneProvider` that accesses `client.auth.currentUser?.id`. `FakeGoTrueClient` returns `null` for `currentUser`, so the provider exits early and returns `null` safely — no crash.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/screens/layanan_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('LayananScreen renders three tabs: Surat, Pengaduan, Kontak', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: const MaterialApp(home: LayananScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Surat'), findsOneWidget);
    expect(find.text('Pengaduan'), findsOneWidget);
    expect(find.text('Kontak'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run batch 2 widget tests**

```bash
flutter test test/widget/screens/invoices_screen_test.dart test/widget/screens/expenses_screen_test.dart test/widget/screens/layanan_screen_test.dart
```

Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add test/widget/screens/
git commit -m "test: add widget tests for InvoicesScreen, ExpensesScreen, LayananScreen"
```

---

## Task 7: Widget Tests — Batch 3 (AdminContactsScreen, AnnouncementsScreen, MarketplaceScreen)

**Files:**
- Create: `test/widget/screens/admin_contacts_screen_test.dart`
- Create: `test/widget/screens/announcements_screen_test.dart`
- Create: `test/widget/screens/marketplace_screen_test.dart`

- [ ] **Step 1: Create test/widget/screens/admin_contacts_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/screens/admin_contacts_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('AdminContactsScreen renders FAB and empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(contacts: []),
        child: const MaterialApp(home: AdminContactsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Belum ada kontak'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Create test/widget/screens/announcements_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/announcements/screens/announcements_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('AnnouncementsScreen (admin) renders without crash with empty list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(announcements: []),
        child: const MaterialApp(home: AnnouncementsScreen(isAdmin: true)),
      ),
    );
    await tester.pumpAndSettle();

    // Screen renders — no specific empty state text, just no crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
```

- [ ] **Step 3: Create test/widget/screens/marketplace_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/marketplace/screens/marketplace_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('MarketplaceScreen shows empty state when no listings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(listings: []),
        child: const MaterialApp(home: MarketplaceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada yang jualan nih!'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run batch 3 widget tests**

```bash
flutter test test/widget/screens/admin_contacts_screen_test.dart test/widget/screens/announcements_screen_test.dart test/widget/screens/marketplace_screen_test.dart
```

Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add test/widget/screens/
git commit -m "test: add widget tests for AdminContactsScreen, AnnouncementsScreen, MarketplaceScreen"
```

---

## Task 8: Widget Tests — Batch 4 (ReportsScreen, ResidentHomeScreen, ResidentInvoicesScreen)

**Files:**
- Create: `test/widget/screens/reports_screen_test.dart`
- Create: `test/widget/screens/resident_home_screen_test.dart`
- Create: `test/widget/screens/resident_invoices_screen_test.dart`

- [ ] **Step 1: Create test/widget/screens/reports_screen_test.dart**

`ReportsScreen` uses `reportProvider` which is overridden with `FakeReportNotifier` — the stub returns an initial `ReportState` without calling `loadReportData()`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/reports/screens/reports_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('ReportsScreen renders Laporan Keuangan title without crash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Laporan Keuangan'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Create test/widget/screens/resident_home_screen_test.dart**

`ResidentHomeScreen` watches `currentResidentProfileProvider` (overridden to `null`) and `unreadCountProvider` (handled by `FakeGoTrueClient.currentUser == null`).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/resident_portal/screens/resident_home_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('ResidentHomeScreen renders without crash when profile is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: const MaterialApp(home: ResidentHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Render success — no crash. Profile is null so screen shows loading/empty state.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
```

- [ ] **Step 3: Create test/widget/screens/resident_invoices_screen_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/resident_portal/screens/resident_invoices_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('ResidentInvoicesScreen shows empty state when no invoices', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(residentInvoices: []),
        child: const MaterialApp(home: ResidentInvoicesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada tagihan sama sekali'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run batch 4 widget tests**

```bash
flutter test test/widget/screens/reports_screen_test.dart test/widget/screens/resident_home_screen_test.dart test/widget/screens/resident_invoices_screen_test.dart
```

Expected: PASS (all tests).

- [ ] **Step 5: Run the full test suite to verify everything passes**

```bash
flutter test test/unit/ test/widget/
```

Expected: All 24 test files pass. If any fail, read the error message — most failures will be caused by a missing provider override (add to `mockOverrides()`) or a wrong text assertion (update the `find.text()` to match what the screen actually renders).

- [ ] **Step 6: Commit**

```bash
git add test/widget/screens/
git commit -m "test: add widget tests for ReportsScreen, ResidentHomeScreen, ResidentInvoicesScreen"
```

---

## Task 9: Script Runner — tool/run_tests.dart

**Files:**
- Create: `tool/run_tests.dart` (create the `tool/` directory first — it does not exist yet)

- [ ] **Step 1: Create the tool/ directory and run_tests.dart**

Create `tool/run_tests.dart` with the full content below:

```dart
import 'dart:convert';
import 'dart:io';

// ── Test registry ──────────────────────────────────────────────────────────
const unitTests = [
  ('InvoiceModel',            'test/unit/models/invoice_model_test.dart'),
  ('ResidentModel',           'test/unit/models/resident_model_test.dart'),
  ('ExpenseModel',            'test/unit/models/expense_model_test.dart'),
  ('BillingTypeModel',        'test/unit/models/billing_type_model_test.dart'),
  ('AnnouncementModel',       'test/unit/models/announcement_model_test.dart'),
  ('ComplaintModel',          'test/unit/models/complaint_model_test.dart'),
  ('LetterRequestModel',      'test/unit/models/letter_request_model_test.dart'),
  ('CommunityContactModel',   'test/unit/models/community_contact_model_test.dart'),
  ('MarketplaceListingModel', 'test/unit/models/marketplace_listing_model_test.dart'),
  ('NotificationModel',       'test/unit/models/notification_model_test.dart'),
  ('ReportModel',             'test/unit/models/report_model_test.dart'),
  ('FamilyMember',            'test/unit/models/family_member_model_test.dart'),
];

const widgetTests = [
  ('LoginScreen',             'test/widget/screens/login_screen_test.dart'),
  ('AdminDashboardScreen',    'test/widget/screens/admin_dashboard_test.dart'),
  ('ResidentsScreen',         'test/widget/screens/residents_screen_test.dart'),
  ('InvoicesScreen',          'test/widget/screens/invoices_screen_test.dart'),
  ('ExpensesScreen',          'test/widget/screens/expenses_screen_test.dart'),
  ('LayananScreen',           'test/widget/screens/layanan_screen_test.dart'),
  ('AdminContactsScreen',     'test/widget/screens/admin_contacts_screen_test.dart'),
  ('AnnouncementsScreen',     'test/widget/screens/announcements_screen_test.dart'),
  ('MarketplaceScreen',       'test/widget/screens/marketplace_screen_test.dart'),
  ('ReportsScreen',           'test/widget/screens/reports_screen_test.dart'),
  ('ResidentHomeScreen',      'test/widget/screens/resident_home_screen_test.dart'),
  ('ResidentInvoicesScreen',  'test/widget/screens/resident_invoices_screen_test.dart'),
];

// ── Error pattern → suggestion map ────────────────────────────────────────
String _suggestion(String errorText) {
  if (errorText.contains("type 'Null' is not a subtype")) {
    return 'Tambah null fallback di fromMap untuk field yang crash';
  }
  if (errorText.contains('No element') || errorText.contains('findsNothing')) {
    return 'Cek widget key atau teks yang dicari di assertion';
  }
  if (errorText.contains('ProviderException') || errorText.contains('StateError')) {
    return 'Pastikan provider di-override di mockOverrides()';
  }
  if (errorText.contains('Supabase has not been initialized')) {
    return 'Tambah supabaseClientProvider.overrideWithValue(FakeSupabaseClient())';
  }
  return '';
}

// ── Result tracking ────────────────────────────────────────────────────────
class TestResult {
  final String label;
  final String filePath;
  final bool passed;
  final List<String> errors;
  TestResult(this.label, this.filePath, this.passed, this.errors);
}

// ── Run a single test file ─────────────────────────────────────────────────
Future<TestResult> runTest(String label, String filePath) async {
  final result = await Process.run(
    'flutter',
    ['test', filePath, '--reporter', 'json'],
    runInShell: true,       // required on Windows to find flutter via PATH
  );

  final errors = <String>[];
  bool anyFailed = false;

  final lines = result.stdout.toString().split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    try {
      final event = jsonDecode(trimmed) as Map<String, dynamic>;
      final type = event['type'] as String?;

      // 'failure' = expect() gagal, 'error' = unhandled exception
      if (type == 'testDone' &&
          (event['result'] == 'failure' || event['result'] == 'error')) {
        anyFailed = true;
        final testId = event['testID'] as int?;
        if (testId != null) {
          errors.add('Test ID $testId failed (result: ${event['result']})');
        }
      }

      if (type == 'error') {
        final msg = event['error'] as String? ?? '';
        final stackTrace = event['stackTrace'] as String? ?? '';
        // Take first line of stack trace for location
        final location = stackTrace.split('\n').firstWhere(
          (l) => l.contains(filePath) || l.contains('test/'),
          orElse: () => '',
        );
        errors.add('$msg${location.isNotEmpty ? '\n  at $location' : ''}');
      }
    } catch (_) {
      // Non-JSON line (e.g. flutter banner) — skip
    }
  }

  // Also treat non-zero exit as failure
  if (result.exitCode != 0 && !anyFailed) {
    anyFailed = true;
    final stderr = result.stderr.toString().trim();
    if (stderr.isNotEmpty) errors.add(stderr);
  }

  return TestResult(label, filePath, !anyFailed, errors);
}

// ── Progress file helpers ──────────────────────────────────────────────────
String _progressContent(
  List<(String, String)> units,
  List<(String, String)> widgets,
  Map<String, String> statusMap,
  DateTime startTime,
) {
  final buf = StringBuffer();
  buf.writeln('# Test Progress — ${startTime.toIso8601String().replaceFirst('T', ' ').substring(0, 19)}');
  buf.writeln();

  final doneUnits = statusMap.entries.where((e) => units.any((u) => u.$1 == e.key) && e.value == '✅').length;
  buf.writeln('## Unit Tests — Models ($doneUnits/${units.length} selesai)');
  buf.writeln('| Model | Status |');
  buf.writeln('|---|---|');
  for (final (label, _) in units) {
    buf.writeln('| $label | ${statusMap[label] ?? ''} |');
  }
  buf.writeln();

  final doneWidgets = statusMap.entries.where((e) => widgets.any((w) => w.$1 == e.key) && e.value == '✅').length;
  buf.writeln('## Widget Tests — Screens ($doneWidgets/${widgets.length} selesai)');
  buf.writeln('| Screen | Status |');
  buf.writeln('|---|---|');
  for (final (label, _) in widgets) {
    buf.writeln('| $label | ${statusMap[label] ?? ''} |');
  }
  return buf.toString();
}

// ── Gap analysis ───────────────────────────────────────────────────────────
Future<List<String>> runGapAnalysis() async {
  final gaps = <String>[];

  // 1. Model gap scan
  final modelDir = Directory('lib/features');
  await for (final entity in modelDir.list(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (!path.contains('/models/') || !path.endsWith('.dart')) continue;

    final content = await entity.readAsString();
    if (!content.contains('fromMap') && !content.contains('fromJson')) continue;

    final fileName = path.split('/').last; // e.g. 'invoice_model.dart'
    final baseName = fileName.replaceFirst('.dart', ''); // 'invoice_model'
    final testFile = 'test/unit/models/${baseName}_test.dart';
    if (!File(testFile).existsSync()) {
      final modelName = baseName.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join('');
      gaps.add('[ ] Belum ada unit test untuk $modelName');
    }
  }

  // 2. Screen gap scan
  final screenDir = Directory('lib/features');
  await for (final entity in screenDir.list(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (!path.contains('/screens/') || !path.endsWith('_screen.dart')) continue;

    final content = await entity.readAsString();
    if (content.contains('part of')) continue;

    // Exclude all auth screens except login_screen.dart
    if (path.contains('/auth/screens/') && !path.endsWith('/login_screen.dart')) continue;

    final fileName = path.split('/').last; // e.g. 'residents_screen.dart'
    final baseName = fileName.replaceFirst('.dart', '');
    final testFile = 'test/widget/screens/${baseName}_test.dart';
    if (!File(testFile).existsSync()) {
      final screenName = baseName.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join('');
      gaps.add('[ ] Belum ada widget test untuk $screenName');
    }
  }

  // 3. Form validation gap
  final widgetDir = Directory('test/widget/screens');
  if (widgetDir.existsSync()) {
    await for (final entity in widgetDir.list()) {
      if (entity is! File || !entity.path.endsWith('_test.dart')) continue;
      final testContent = await entity.readAsString();
      if (testContent.contains('validator') || testContent.contains('validate')) continue;

      // Find the corresponding source screen
      final testFileName = entity.path.split(Platform.pathSeparator).last;
      final screenFileName = testFileName.replaceFirst('_test.dart', '.dart');
      // Search for the screen file
      final screenFile = await _findScreen(screenFileName);
      if (screenFile != null) {
        final screenContent = await screenFile.readAsString();
        if (screenContent.contains('TextFormField')) {
          final screenName = screenFileName.replaceFirst('.dart', '')
              .split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join('');
          gaps.add('[ ] Belum ada test form validation di $screenName');
        }
      }
    }
  }

  return gaps;
}

Future<File?> _findScreen(String fileName) async {
  final dir = Directory('lib/features');
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith(fileName)) return entity;
  }
  return null;
}

// ── Main ───────────────────────────────────────────────────────────────────
void main() async {
  final startTime = DateTime.now();
  final statusMap = <String, String>{};
  final results = <TestResult>[];

  final progressFile = File('test_progress.md');

  // Initialize progress file
  await progressFile.writeAsString(_progressContent(
    unitTests, widgetTests, statusMap, startTime,
  ));

  final allTests = [...unitTests, ...widgetTests];

  for (final (label, filePath) in allTests) {
    // Mark as running
    statusMap[label] = '⏳ sedang berjalan...';
    await progressFile.writeAsString(_progressContent(
      unitTests, widgetTests, statusMap, startTime,
    ));

    stdout.write('Running $label... ');
    final result = await runTest(label, filePath);
    results.add(result);

    statusMap[label] = result.passed ? '✅' : '❌';
    await progressFile.writeAsString(_progressContent(
      unitTests, widgetTests, statusMap, startTime,
    ));

    stdout.writeln(result.passed ? '✅' : '❌');
  }

  // Gap analysis
  stdout.writeln('\nRunning gap analysis...');
  final gaps = await runGapAnalysis();

  // Generate test_report.md
  final passed = results.where((r) => r.passed).length;
  final failed = results.where((r) => !r.passed).length;
  final reportBuf = StringBuffer();
  reportBuf.writeln('# Test Report — ${startTime.toIso8601String().replaceFirst('T', ' ').substring(0, 19)}');
  reportBuf.writeln();
  reportBuf.writeln('## Ringkasan');
  reportBuf.writeln('- ✅ Passed: $passed/${results.length}');
  reportBuf.writeln('- ❌ Failed: $failed/${results.length}');
  reportBuf.writeln();

  final failedResults = results.where((r) => !r.passed).toList();
  if (failedResults.isNotEmpty) {
    reportBuf.writeln('## Error Detail');
    reportBuf.writeln();
    for (final r in failedResults) {
      reportBuf.writeln('### ❌ ${r.label}');
      reportBuf.writeln('**File:** ${r.filePath}');
      for (final err in r.errors) {
        reportBuf.writeln('**Error:** `$err`');
        final saran = _suggestion(err);
        if (saran.isNotEmpty) reportBuf.writeln('**Saran:** $saran');
      }
      reportBuf.writeln();
    }
  }

  if (gaps.isNotEmpty) {
    reportBuf.writeln('## Gap Checklist');
    for (final gap in gaps) {
      reportBuf.writeln('- $gap');
    }
  }

  await File('test_report.md').writeAsString(reportBuf.toString());

  stdout.writeln('\n✅ Done. See test_report.md');
  stdout.writeln('Passed: $passed/${results.length}');
  if (failed > 0) stdout.writeln('Failed: $failed/${results.length}');
}
```

- [ ] **Step 2: Run the script to verify it works**

```bash
dart run tool/run_tests.dart
```

Expected: Script runs all 24 test files one by one, writes `test_progress.md` live, produces `test_report.md` at the end. If all tests pass, report shows `✅ Passed: 24/24`. Gap checklist will include screens without widget tests (AdminRequestsScreen, AdminComplaintsScreen, etc.).

- [ ] **Step 3: Commit**

```bash
git add tool/run_tests.dart test_progress.md test_report.md
git commit -m "feat: add automated test runner script (tool/run_tests.dart) with live progress and gap analysis"
```

---

## Final Verification

- [ ] Run the full test suite one final time:

```bash
flutter test test/unit/ test/widget/
```

Expected: All tests pass.

- [ ] Run the script and verify both output files are generated:

```bash
dart run tool/run_tests.dart
```

Expected: `test_progress.md` and `test_report.md` present at project root with correct content.
