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
