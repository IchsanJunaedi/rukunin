import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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
