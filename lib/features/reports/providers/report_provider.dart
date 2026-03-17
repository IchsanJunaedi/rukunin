import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/report_model.dart';

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() {
    final now = DateTime.now();
    
    // Inisialisasi awal
    final emptyReport = MonthlyReport(month: now.month, year: now.year, totalIncome: 0, totalExpected: 0, totalExpense: 0);
    
    Future.microtask(() => loadReportData(now.month, now.year));
    
    return ReportState(
      selectedMonth: now.month,
      selectedYear: now.year,
      currentMonthReport: emptyReport,
      lastSixMonths: [],
      isLoading: true,
    );
  }

  void setFilterMode(ReportFilterMode mode) {
    final now = DateTime.now();
    state = state.copyWith(
      filterMode: mode,
      selectedMonth: mode == ReportFilterMode.currentMonth ? now.month : state.selectedMonth,
      selectedYear: mode == ReportFilterMode.currentMonth ? now.year : state.selectedYear,
    );
    if (mode == ReportFilterMode.currentMonth) {
      loadReportData(now.month, now.year);
    }
  }

  void changePeriod(int month, int year) {
    if (state.selectedMonth == month && state.selectedYear == year) return;
    
    state = state.copyWith(selectedMonth: month, selectedYear: year);
    loadReportData(month, year);
  }

  Future<void> loadReportData(int month, int year) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await ref.read(currentProfileProvider.future);
      if (profile?['community_id'] == null) throw Exception('Community ID tidak ditemukan');
      
      final communityId = profile!['community_id'];
      
      // Ambil report bulan yang dipilih
      final currentReport = await _fetchMonthlyReport(client, communityId, month, year);
      
      // Ambil report 6 bulan terakhir untuk grafik (mundur dari bulan terpilih)
      List<MonthlyReport> sixMonths = [];
      for (int i = 5; i >= 0; i--) {
        int m = month - i;
        int y = year;
        if (m <= 0) {
          m += 12;
          y -= 1;
        }
        final report = await _fetchMonthlyReport(client, communityId, m, y);
        sixMonths.add(report);
      }
      
      state = state.copyWith(
        currentMonthReport: currentReport,
        lastSixMonths: sixMonths,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<MonthlyReport> _fetchMonthlyReport(dynamic client, String communityId, int month, int year) async {
     // 1. Hitung Invoices (Tagihan)
     final invoicesRes = await client.from('invoices')
         .select('amount, status')
         .eq('community_id', communityId)
         .eq('month', month)
         .eq('year', year);
         
     double totalExpected = 0;
     double totalIncome = 0;
     
     for (var inv in invoicesRes) {
       final amt = double.tryParse(inv['amount'].toString()) ?? 0;
       totalExpected += amt;
       if (inv['status'] == 'paid') {
         totalIncome += amt;
       }
     }
     
     // 2. Hitung Expenses (Pengeluaran)
     // Filter pengeluaran yang expense_date nya ada di bulan & tahun ini
     final firstDay = DateTime(year, month, 1).toIso8601String().split('T').first;
     final lastDay = DateTime(year, month + 1, 0).toIso8601String().split('T').first;
     
     final expensesRes = await client.from('expenses')
         .select('amount')
         .eq('community_id', communityId)
         .gte('expense_date', firstDay)
         .lte('expense_date', lastDay);
         
     double totalExpense = 0;
     for (var exp in expensesRes) {
       totalExpense += double.tryParse(exp['amount'].toString()) ?? 0;
     }
     
     return MonthlyReport(
       month: month,
       year: year,
       totalIncome: totalIncome,
       totalExpected: totalExpected,
       totalExpense: totalExpense,
     );
  }
}

final reportProvider = NotifierProvider<ReportNotifier, ReportState>(ReportNotifier.new);
