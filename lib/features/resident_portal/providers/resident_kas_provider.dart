import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../expenses/models/expense_model.dart';

class ResidentKasData {
  final double totalIncome;
  final double totalExpense;
  final List<ExpenseModel> recentExpenses;
  final int currentMonth;
  final int currentYear;

  const ResidentKasData({
    required this.totalIncome,
    required this.totalExpense,
    required this.recentExpenses,
    required this.currentMonth,
    required this.currentYear,
  });

  double get netBalance => totalIncome - totalExpense;
}

final residentKasProvider = FutureProvider.autoDispose<ResidentKasData>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    return ResidentKasData(
      totalIncome: 0, totalExpense: 0, recentExpenses: [],
      currentMonth: DateTime.now().month, currentYear: DateTime.now().year,
    );
  }

  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();

  final communityId = profile?['community_id'] as String?;
  if (communityId == null) {
    return ResidentKasData(
      totalIncome: 0, totalExpense: 0, recentExpenses: [],
      currentMonth: DateTime.now().month, currentYear: DateTime.now().year,
    );
  }

  final now = DateTime.now();
  final month = now.month;
  final year = now.year;

  // Total pemasukan bulan ini dari tagihan yang sudah lunas
  final paidInvoices = await client
      .from('invoices')
      .select('amount')
      .eq('community_id', communityId)
      .eq('status', 'paid')
      .eq('month', month)
      .eq('year', year);

  final totalIncome = (paidInvoices as List).fold<double>(
    0,
    (sum, inv) => sum + (double.tryParse(inv['amount'].toString()) ?? 0),
  );

  // Total pengeluaran bulan ini
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final firstDay = '$year-${month.toString().padLeft(2, '0')}-01';
  final lastDay = '$year-${month.toString().padLeft(2, '0')}-${lastDayOfMonth.toString().padLeft(2, '0')}';

  final monthExpenses = await client
      .from('expenses')
      .select('amount')
      .eq('community_id', communityId)
      .gte('expense_date', firstDay)
      .lte('expense_date', lastDay);

  final totalExpense = (monthExpenses as List).fold<double>(
    0,
    (sum, exp) => sum + (double.tryParse(exp['amount'].toString()) ?? 0),
  );

  // 10 pengeluaran terbaru (lintas bulan) untuk ditampilkan ke warga
  final recentExpensesData = await client
      .from('expenses')
      .select()
      .eq('community_id', communityId)
      .order('expense_date', ascending: false)
      .limit(10);

  final recentExpenses = (recentExpensesData as List)
      .map((e) => ExpenseModel.fromMap(e))
      .toList();

  return ResidentKasData(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    recentExpenses: recentExpenses,
    currentMonth: month,
    currentYear: year,
  );
});
