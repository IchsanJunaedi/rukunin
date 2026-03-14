import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/expense_model.dart';

class ExpensesNotifier extends AsyncNotifier<List<ExpenseModel>> {
  @override
  Future<List<ExpenseModel>> build() async {
    return _fetchExpenses();
  }

  Future<List<ExpenseModel>> _fetchExpenses() async {
    final client = ref.read(supabaseClientProvider);
    final profile = await ref.read(currentProfileProvider.future);
    if (profile?['community_id'] == null) return [];

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
    final lastDay = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T').first;

    final data = await client
        .from('expenses')
        .select()
        .eq('community_id', profile!['community_id'])
        .gte('expense_date', firstDay)
        .lte('expense_date', lastDay)
        .order('expense_date', ascending: false);

    return data.map((e) => ExpenseModel.fromMap(e)).toList();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      final profile = await ref.read(currentProfileProvider.future);
      if (profile?['community_id'] == null) throw Exception('Community ID tidak ditemukan');

      final map = expense.toMap();
      map['community_id'] = profile!['community_id'];
      map['created_by'] = client.auth.currentUser?.id;

      await client.from('expenses').insert(map);
      return _fetchExpenses();
    });
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.from('expenses').delete().eq('id', id);
      return _fetchExpenses();
    });
  }
}

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<ExpenseModel>>(
        ExpensesNotifier.new);

final totalExpensesProvider = Provider.autoDispose<double>((ref) {
  final expensesVal = ref.watch(expensesProvider);
  return expensesVal.maybeWhen(
    data: (list) => list.fold(0.0, (sum, e) => sum + e.amount),
    orElse: () => 0.0,
  );
});
