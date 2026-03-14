import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final totalAsync = ref.watch(totalExpensesProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        title: Text(
          'Pengeluaran Kas',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: Text('Catat Pengeluaran',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
      ),
      body: Column(
        children: [
          // ─── Header Total ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pengeluaran $monthLabel',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(totalAsync),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ],
            ),
          ),

          // ─── List ───
          Expanded(
            child: expensesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: AppColors.grey300),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pengeluaran bulan ini',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.grey500,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return _ExpenseCard(
                        expense: expense,
                        format: currencyFormat,
                        ref: ref);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final NumberFormat format;
  final WidgetRef ref;

  const _ExpenseCard(
      {required this.expense,
      required this.format,
      required this.ref});

  static const Map<String, IconData> _categoryIcons = {
    'Kebersihan': Icons.cleaning_services_outlined,
    'Keamanan': Icons.security_outlined,
    'Infrastruktur': Icons.construction_outlined,
    'Sosial': Icons.people_outline,
    'Operasional': Icons.settings_outlined,
    'Lain-lain': Icons.more_horiz,
  };

  static const Map<String, Color> _categoryColors = {
    'Kebersihan': Color(0xFF10B981),
    'Keamanan': Color(0xFF3B82F6),
    'Infrastruktur': Color(0xFFF59E0B),
    'Sosial': Color(0xFF8B5CF6),
    'Operasional': Color(0xFF6B7280),
    'Lain-lain': Color(0xFF9CA3AF),
  };

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[expense.category] ?? Icons.receipt;
    final color = _categoryColors[expense.category] ?? AppColors.grey600;
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(expense.expenseDate);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Hapus Pengeluaran',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            content: Text('Yakin ingin menghapus pengeluaran ini?',
                style: GoogleFonts.plusJakartaSans()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Batal', style: GoogleFonts.plusJakartaSans()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Hapus',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengeluaran dihapus')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          title: Text(
            expense.description,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.grey800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${expense.category} · $dateStr',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppColors.grey500),
          ),
          trailing: Text(
            format.format(expense.amount),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}
