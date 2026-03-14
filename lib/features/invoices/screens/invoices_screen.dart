import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../providers/invoice_list_provider.dart';

// Extension untuk kapitalisasi
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Default provider dari file list provider: invoiceMonthFilterProvider & invoiceYearFilterProvider

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inisialisasi value state filter bulan dan tahun 
    final selectedMonth = ref.watch(invoiceMonthFilterProvider);
    final selectedYear = ref.watch(invoiceYearFilterProvider);
    
    // Watch future provider untuk list tagihan yang ada info Warga nya
    final invoiceListAsync = ref.watch(invoiceWithResidentProvider);

    final String monthName = DateFormat('MMMM', 'id_ID').format(DateTime(selectedYear, selectedMonth)).capitalize();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.grey100,
        appBar: AppBar(
          title: const Text('Tagihan Warga'),
          actions: [
            Consumer(
              builder: (context, ref, _) {
                return IconButton(
                  icon: const Icon(Icons.mark_chat_read_outlined),
                  tooltip: 'Broadcast WA Tagihan Bulan Ini',
                  onPressed: () => _confirmBroadcast(context, ref),
                );
              }
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Pengaturan Jenis Iuran',
              onPressed: () => context.push('/admin/pengaturan-iuran'),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Semua'),
              Tab(text: 'Belum Lunas'),
              Tab(text: 'Verifikasi'),
              Tab(text: 'Lunas'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Filter Header Bulan/Tahun
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      if (selectedMonth == 1) {
                         ref.read(invoiceMonthFilterProvider.notifier).setMonth(12);
                         ref.read(invoiceYearFilterProvider.notifier).setYear(selectedYear - 1);
                      } else {
                         ref.read(invoiceMonthFilterProvider.notifier).setMonth(selectedMonth - 1);
                      }
                    },
                  ),
                  Text(
                    '$monthName $selectedYear',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.grey800,
                    ),
                  ),
                  IconButton(
                     icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      if (selectedMonth == 12) {
                         ref.read(invoiceMonthFilterProvider.notifier).setMonth(1);
                         ref.read(invoiceYearFilterProvider.notifier).setYear(selectedYear + 1);
                      } else {
                         ref.read(invoiceMonthFilterProvider.notifier).setMonth(selectedMonth + 1);
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // List Konten Berdasarkan Tab
            Expanded(
              child: invoiceListAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (invoices) {
                  return TabBarView(
                    children: [
                      _buildInvoiceList(context, ref, invoices, 'semua'),
                      _buildInvoiceList(context, ref, invoices, 'pending'),
                      _buildInvoiceList(context, ref, invoices, 'awaiting_verification'),
                      _buildInvoiceList(context, ref, invoices, 'paid'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/admin/tagihan/buat'),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_card_outlined, color: AppColors.onPrimary),
        ),
      ),
    );
  }

  Widget _buildInvoiceList(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> allInvoices, String tabFilter) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    // Filter data tagihan sesuai tipe tab
    final filteredInvoices = allInvoices.where((inv) {
      if (tabFilter == 'semua') return true;
      if (tabFilter == 'paid') return inv['status'] == 'paid';
      if (tabFilter == 'awaiting_verification') return inv['status'] == 'awaiting_verification';
      return inv['status'] == 'pending' || inv['status'] == 'overdue'; // pending tab
    }).toList();

    if (filteredInvoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada tagihan',
              style: GoogleFonts.plusJakartaSans(color: AppColors.grey600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredInvoices.length,
      itemBuilder: (context, index) {
        final item = filteredInvoices[index];
        final billingName = item['billing_types']?['name'] ?? 'Iuran';
        final amount = double.tryParse(item['amount'].toString()) ?? 0;
        final residentName = item['profiles']?['full_name'] ?? 'Warga';
        final status = item['status']?.toString() ?? 'pending';
        
        DateTime? dueDate;
        if (item['due_date'] != null) {
          dueDate = DateTime.tryParse(item['due_date'].toString());
        }

        bool isLate = false;
        if (status == 'pending' && dueDate != null && dueDate.isBefore(DateTime.now())) {
          isLate = true;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    residentName,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(status, isLate),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  billingName,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.grey600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(amount),
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Buka dialog aksi tagihan (misal konfirmasi bayar manual/kirim WA WA)
               _showInvoiceActionDialog(context, item, ref);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, bool isLate) {
    Color bgColor;
    Color textColor;
    String label;

    if (status == 'paid') {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      label = 'Lunas';
    } else if (status == 'awaiting_verification') {
      bgColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue;
      label = 'Menunggu Verif';
    } else if (isLate) {
      bgColor = AppColors.error.withValues(alpha: 0.1);
      textColor = AppColors.error;
      label = 'Terlambat';
    } else {
      bgColor = AppColors.warning.withValues(alpha: 0.1);
      textColor = AppColors.warning;
      label = 'Belum Lunas';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  void _showInvoiceActionDialog(BuildContext context, Map<String, dynamic> invoice, WidgetRef ref) {
     final residentName = invoice['profiles']?['full_name'] ?? 'Warga';
     final status = invoice['status']?.toString() ?? 'pending';
     final isPaid = status == 'paid';
     final isAwaitingVerif = status == 'awaiting_verification';
     
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: Text('Aksi Tagihan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(residentName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
             const SizedBox(height: 4),
             Text('Status: $status', style: GoogleFonts.plusJakartaSans(color: AppColors.grey600, fontSize: 13)),
             if (isAwaitingVerif) ...[
              const SizedBox(height: 12),
              Text('Bukti Transfer:', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey800)),
              const SizedBox(height: 8),
              if (invoice['proof_url'] != null)
                GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showProofFullScreen(context, invoice['proof_url'].toString());
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: invoice['proof_url'].toString(),
                      height: 200,
                      width: 260,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        width: 260,
                        color: AppColors.grey200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        width: 260,
                        color: AppColors.grey200,
                        child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.grey500, size: 40)),
                      ),
                    ),
                  ),
                )
              else
                Row(children: [const Icon(Icons.info_outline, size: 14, color: Colors.blue), const SizedBox(width: 4), Flexible(child: Text('Warga mengklaim sudah mentransfer (tanpa foto bukti).', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.blue)))]),
            ],
           ],
         ),
         actions: [
           if (!isPaid && !isAwaitingVerif)
             OutlinedButton(
               style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
               onPressed: () async {
                 Navigator.pop(ctx);
                 try {
                   await ref.read(invoiceListProvider.notifier).markAsAwaitingVerification(invoice['id'].toString());
                   ref.invalidate(invoiceWithResidentProvider);
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tagihan ditandai menunggu verifikasi.'), backgroundColor: Colors.blue));
                 } catch (e) {
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                 }
               },
               child: Text('Tandai Menunggu Verif', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
             ),
           if (!isPaid)
             ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
               onPressed: () async {
                 Navigator.pop(ctx);
                 try {
                   await ref.read(invoiceListProvider.notifier).markInvoiceAsPaid(invoice['id'].toString());
                   ref.invalidate(invoiceWithResidentProvider);
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tagihan berhasil ditandai lunas!'), backgroundColor: AppColors.success));
                 } catch (e) {
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                 }
               },
               child: Text(isAwaitingVerif ? 'Konfirmasi Lunas ✓' : 'Tandai Lunas', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
             ),
           if (isAwaitingVerif)
             TextButton(
               style: TextButton.styleFrom(foregroundColor: AppColors.error),
               onPressed: () async {
                 Navigator.pop(ctx);
                 try {
                   await ref.read(invoiceListProvider.notifier).rejectInvoice(invoice['id'].toString());
                   ref.invalidate(invoiceWithResidentProvider);
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tagihan dikembalikan ke Belum Lunas.'), backgroundColor: AppColors.error));
                 } catch (e) {
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                 }
               },
               child: Text('Tolak', style: GoogleFonts.plusJakartaSans(color: AppColors.error)),
             ),
           TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: Text('Tutup', style: GoogleFonts.plusJakartaSans(color: AppColors.grey600)),
           ),
         ],
       )
     );
  }

  void _showProofFullScreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('Bukti Transfer', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 60),
            ),
          ),
        ),
      ),
    ));
  }

  void _confirmBroadcast(BuildContext context, WidgetRef ref) {
    showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: Text('Broadcast WhatsApp', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
         content: Text('Kirim pesan WA tagihan ke semua warga yang belum Lunas bulan ini?', style: GoogleFonts.plusJakartaSans()),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppColors.grey600)),
           ),
           ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
             onPressed: () async {
               Navigator.pop(ctx);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Sedang mengirim broadcast...'), duration: Duration(seconds: 2))
               );
                try {
                  final results = await ref.read(invoiceListProvider.notifier).broadcastInvoicesWhatsApp();
                  if (context.mounted) {
                    final lastError = results['lastError']?.toString() ?? '';
                    final failInfo = lastError.isNotEmpty ? '\nAlasan gagal: $lastError' : '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selesai! Terkirim: ${results['success']}, Gagal: ${results['fail']}$failInfo'), 
                        backgroundColor: (results['success'] as int) > 0 ? AppColors.success : AppColors.error,
                        duration: const Duration(seconds: 6),
                      )
                    );
                  }
                } catch (e) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi Kesalahan: $e'), backgroundColor: AppColors.error));
                 }
               }
             },
             child: Text('Ya, Kirim Semua', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
           ),
         ],
       )
    );
  }
}
