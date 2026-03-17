enum ReportFilterMode { currentMonth, threeMonths, sixMonths, custom }

// State model untuk laporan per bulan
class MonthlyReport {
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpected;
  final double totalExpense;
  
  MonthlyReport({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpected,
    required this.totalExpense,
  });

  double get netBalance => totalIncome - totalExpense;
  double get collectionRate => totalExpected > 0 ? (totalIncome / totalExpected) * 100 : 0;
}

// State class untuk satu layar laporan
class ReportState {
  final int selectedMonth;
  final int selectedYear;
  final MonthlyReport currentMonthReport;
  final List<MonthlyReport> lastSixMonths;
  final bool isLoading;
  final String? error;
  final ReportFilterMode filterMode;

  ReportState({
    required this.selectedMonth,
    required this.selectedYear,
    required this.currentMonthReport,
    required this.lastSixMonths,
    this.isLoading = false,
    this.error,
    this.filterMode = ReportFilterMode.currentMonth,
  });

  ReportState copyWith({
    int? selectedMonth,
    int? selectedYear,
    MonthlyReport? currentMonthReport,
    List<MonthlyReport>? lastSixMonths,
    bool? isLoading,
    String? error,
    ReportFilterMode? filterMode,
  }) {
    return ReportState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      currentMonthReport: currentMonthReport ?? this.currentMonthReport,
      lastSixMonths: lastSixMonths ?? this.lastSixMonths,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterMode: filterMode ?? this.filterMode,
    );
  }
}
