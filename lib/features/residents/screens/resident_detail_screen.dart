import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../models/resident_model.dart';
import '../../invoices/providers/invoice_provider.dart';

class ResidentDetailScreen extends ConsumerWidget {
  final ResidentModel resident;

  const ResidentDetailScreen({super.key, required this.resident});

  Future<void> _launchWhatsApp(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor WA tidak tersedia')),
        );
      }
      return;
    }

    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '62${phone.substring(1)}';
    } else if (phone.startsWith('+62')) {
      formattedPhone = '62${phone.substring(3)}';
    }

    final url = Uri.parse('https://wa.me/$formattedPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    final invoicesAsync = ref.watch(residentInvoicesProvider(resident.id));
    final arrearsAsync = ref.watch(residentTotalArrearsProvider(resident.id));

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        title: Text(
          'Detail Warga',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/admin/warga/edit', extra: resident),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile
            _buildProfileCard(),
            const SizedBox(height: 20),

            // Arrears Summary
            arrearsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (total) {
                if (total <= 0) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        Text(
                          'Tidak ada penunggakan kas.',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF047857),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(
                            'Total Tunggakan',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(total),
                        style: GoogleFonts.playfairDisplay(
                          color: AppColors.error,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            Text(
              'Histori Tagihan (6 Bulan)',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 12),

            // Invoices List
            invoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Belum ada histori tagihan.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: invoices.map((inv) {
                    final isOverdue = inv.status == 'overdue' || (inv.status != 'paid' && inv.dueDate.isBefore(DateTime.now()));
                    final isPaid = inv.status == 'paid';
                    
                    Color statusColor = AppColors.warning;
                    String statusText = 'Pending';
                    
                    if (isPaid) {
                      statusColor = AppColors.success;
                      statusText = 'Lunas';
                    } else if (isOverdue) {
                      statusColor = AppColors.error;
                      statusText = 'Terlambat';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: ListTile(
                        title: Text(
                          '${inv.billingTypeName} - ${inv.month}/${inv.year}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Jatuh tempo: ${dateFormat.format(inv.dueDate)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(inv.amount),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.grey800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchWhatsApp(context, resident.phone),
        backgroundColor: const Color(0xFF25D366), // WA Green
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(
          'Kirim WA',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: resident.photoUrl != null && resident.photoUrl!.isNotEmpty
                    ? Image.network(
                        resident.photoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildInitialsAvatar(),
                      )
                    : _buildInitialsAvatar(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resident.fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                        if (!resident.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.grey200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Nonaktif',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.pin_drop_outlined, resident.alamatLengkap),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.phone_outlined, resident.phone ?? '-'),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.credit_card_outlined, resident.nik ?? '-'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terdaftar sejak',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.grey500,
                ),
              ),
              Text(
                dateFormat.format(resident.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 60,
      height: 60,
      color: resident.isActive ? AppColors.primary : AppColors.grey300,
      child: Center(
        child: Text(
          resident.initials,
          style: GoogleFonts.plusJakartaSans(
            color: resident.isActive ? AppColors.onPrimary : AppColors.grey600,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.grey500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.grey600,
            ),
          ),
        ),
      ],
    );
  }
}
