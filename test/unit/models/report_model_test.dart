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
        month: 3,
        year: 2026,
        totalIncome: 1500000,
        totalExpected: 2000000,
        totalExpense: 300000,
      );
      expect(report.netBalance, 1200000);
    });

    test('collectionRate is percentage of income vs expected', () {
      final report = MonthlyReport(
        month: 3,
        year: 2026,
        totalIncome: 1500000,
        totalExpected: 2000000,
        totalExpense: 0,
      );
      expect(report.collectionRate, 75.0);
    });

    test('collectionRate returns 0 when totalExpected is 0', () {
      final report = MonthlyReport(
        month: 3,
        year: 2026,
        totalIncome: 0,
        totalExpected: 0,
        totalExpense: 0,
      );
      expect(report.collectionRate, 0.0);
    });
  });

  group('ReportState', () {
    MonthlyReport emptyReport() => MonthlyReport(
          month: 3,
          year: 2026,
          totalIncome: 0,
          totalExpected: 0,
          totalExpense: 0,
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

    test('copyWith updates selectedMonth, preserves all other fields', () {
      final report = emptyReport();
      final state = ReportState(
        selectedMonth: 3,
        selectedYear: 2026,
        currentMonthReport: report,
        lastSixMonths: [report],
        isLoading: true,
        filterMode: ReportFilterMode.threeMonths,
      );
      final updated = state.copyWith(selectedMonth: 4);
      expect(updated.selectedMonth, 4);
      expect(updated.selectedYear, 2026);
      expect(updated.currentMonthReport, report);
      expect(updated.lastSixMonths, [report]);
      expect(updated.isLoading, isTrue);
      expect(updated.filterMode, ReportFilterMode.threeMonths);
    });
  });
}
