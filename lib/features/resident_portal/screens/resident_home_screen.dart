import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../providers/resident_invoices_provider.dart';

class ResidentHomeScreen extends ConsumerWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentResidentProfileProvider);
    final totalPending = ref.watch(residentTotalPendingInvoicesProvider);
    final invoicesAsync = ref.watch(residentInvoicesProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentResidentProfileProvider);
            ref.invalidate(residentInvoicesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header
              profileAsync.when(
                data: (profile) => Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      backgroundImage: profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty
                          ? NetworkImage(profile.photoUrl!)
                          : null,
                      child: (profile?.photoUrl == null || profile!.photoUrl!.isEmpty)
                          ? Text(
                              profile?.initials ?? '?',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${profile?.fullName ?? 'Warga'} 👋',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.grey800,
                            ),
                          ),
                          Text(
                            profile?.alamatLengkap ?? 'Memuat info...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error memuat profil: $e'),
              ),

              const SizedBox(height: 32),

              // Card Total Tagihan
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6B4AC6)], // primary to deeper primary
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sisa Tagihan Anda',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.account_balance_wallet_rounded, 
                             color: Colors.white.withValues(alpha: 0.8), size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                          .format(totalPending),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (totalPending > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Harap segera dilunasi bulan ini',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else 
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Semua tagihan bulan ini telah lunas ✨',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card Transparansi Kas
              GestureDetector(
                onTap: () => context.push('/resident/kas'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_rounded,
                            color: AppColors.success, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transparansi Kas Lingkungan',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.grey800,
                              ),
                            ),
                            Text(
                              'Lihat pemasukan & pengeluaran RW',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tagihan Terkini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview 3 Invoices Terakhir
              invoicesAsync.when(
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.grey300),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada riwayat tagihan',
                              style: GoogleFonts.plusJakartaSans(color: AppColors.grey500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Tampilkan maks 3 saja dari yang paling baru
                  final recent = invoices.take(3).toList();
                  return Column(
                    children: recent.map((inv) {
                      final monthName = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(inv.year, inv.month));
                      final amountFmt = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(inv.amount);
                      
                      Color statusColor;
                      String statusText;
                      if (inv.status == 'paid') {
                        statusColor = AppColors.success;
                        statusText = 'Lunas';
                      } else if (inv.status == 'overdue') {
                        statusColor = AppColors.error;
                        statusText = 'Terlambat';
                      } else if (inv.status == 'awaiting_verification') {
                        statusColor = const Color(0xFF3B82F6);
                        statusText = 'Menunggu Verifikasi';
                      } else {
                        statusColor = AppColors.warning;
                        statusText = 'Belum Dibayar';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.receipt_rounded, color: statusColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.billingTypeName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.grey800,
                                    ),
                                  ),
                                  Text(
                                    'Periode $monthName',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusText,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              amountFmt,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.grey800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
