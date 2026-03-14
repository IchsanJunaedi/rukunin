import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../providers/resident_kas_provider.dart';

class ResidentKasScreen extends ConsumerWidget {
  const ResidentKasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kasAsync = ref.watch(residentKasProvider);
    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Transparansi Kas'),
      ),
      body: kasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Gagal memuat data kas', style: GoogleFonts.plusJakartaSans(color: AppColors.grey600)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(residentKasProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (kas) {
          final monthName = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(kas.currentYear, kas.currentMonth));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(residentKasProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Label periode
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Periode $monthName',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),

                // 3 kartu ringkasan
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Pemasukan',
                        value: currencyFmt.format(kas.totalIncome),
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Pengeluaran',
                        value: currencyFmt.format(kas.totalExpense),
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Saldo bersih — full width
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kas.netBalance >= 0 ? AppColors.surface : AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo Bersih Bulan Ini',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFmt.format(kas.netBalance.abs()),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        kas.netBalance >= 0
                            ? Icons.account_balance_wallet_rounded
                            : Icons.warning_rounded,
                        color: kas.netBalance >= 0 ? AppColors.primary : Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // List pengeluaran terbaru
                Text(
                  '10 Pengeluaran Terbaru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 12),

                if (kas.recentExpenses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.grey300),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada catatan pengeluaran',
                            style: GoogleFonts.plusJakartaSans(color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...kas.recentExpenses.map((exp) {
                    final dateStr = DateFormat('d MMM yyyy', 'id_ID').format(exp.expenseDate);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.payments_outlined,
                                color: AppColors.error, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.description.isNotEmpty ? exp.description : exp.category,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.grey800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${exp.category} · $dateStr',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFmt.format(exp.amount),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 16),
                Text(
                  'Data ini hanya dapat dilihat — tidak dapat diubah oleh warga.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.grey400,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.grey800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
