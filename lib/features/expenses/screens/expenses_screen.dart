import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/components.dart';
import '../../../app/tokens.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expensesAsync = ref.watch(expensesProvider);
    final totalAsync = ref.watch(totalExpensesProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        foregroundColor: Colors.white,
        title: Text(
          'Pengeluaran Kas',
          style: RukuninFonts.pjs(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RukuninColors.brandGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Catat Pengeluaran',
            style: RukuninFonts.pjs(fontWeight: FontWeight.w700)),
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
            decoration: BoxDecoration(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pengeluaran $monthLabel',
                  style: RukuninFonts.pjs(
                      fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(totalAsync),
                  style: RukuninFonts.pjs(
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
              error: (e, _) => Center(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Gagal memuat pengeluaran',
                  description: 'Periksa koneksi internet, lalu coba lagi.',
                  ctaLabel: 'Coba lagi',
                  onCta: () => ref.invalidate(expensesProvider),
                ),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pengeluaran bulan ini',
                          style: RukuninFonts.pjs(
                              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = _categoryIcons[expense.category] ?? Icons.receipt;
    final color = _categoryColors[expense.category] ?? (isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary);
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(expense.expenseDate);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: RukuninColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: RukuninColors.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Hapus Pengeluaran',
                style: RukuninFonts.pjs(fontWeight: FontWeight.w700)),
            content: Text('Yakin ingin menghapus pengeluaran ini?',
                style: RukuninFonts.pjs()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Batal', style: RukuninFonts.pjs()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: RukuninColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Hapus',
                    style: RukuninFonts.pjs(color: Colors.white)),
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
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightCardSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? null : RukuninShadow.card,
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
            style: RukuninFonts.pjs(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${expense.category} · $dateStr',
            style: RukuninFonts.pjs(
                fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
          ),
          trailing: Text(
            format.format(expense.amount),
            style: RukuninFonts.pjs(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: RukuninColors.error,
            ),
          ),
        ),
      ),
    );
  }
}
