import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../../invoices/models/invoice_model.dart';
import '../providers/resident_invoices_provider.dart';
import '../providers/upload_proof_provider.dart';
import 'package:image_picker/image_picker.dart';

class ResidentInvoicesScreen extends ConsumerStatefulWidget {
  const ResidentInvoicesScreen({super.key});

  @override
  ConsumerState<ResidentInvoicesScreen> createState() => _ResidentInvoicesScreenState();
}

class _ResidentInvoicesScreenState extends ConsumerState<ResidentInvoicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invoicesAsync = ref.watch(residentInvoicesProvider);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: const Text('Riwayat Tagihan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: RukuninColors.brandGreen,
          unselectedLabelColor: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
          indicatorColor: RukuninColors.brandGreen,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Belum Lunas'),
            Tab(text: 'Lunas'),
          ],
        ),
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada tagihan sama sekali',
                    style: GoogleFonts.plusJakartaSans(color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                  ),
                ],
              ),
            );
          }

          final pendingInvoices = invoices.where((inv) => inv.status == 'pending' || inv.status == 'overdue' || inv.status == 'awaiting_verification').toList();
          final paidInvoices = invoices.where((inv) => inv.status == 'paid').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _InvoiceListBuilder(invoices: invoices),
              _InvoiceListBuilder(invoices: pendingInvoices),
              _InvoiceListBuilder(invoices: paidInvoices),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
      ),
    );
  }
}

class _InvoiceListBuilder extends ConsumerStatefulWidget {
  final List<InvoiceModel> invoices;
  const _InvoiceListBuilder({required this.invoices});

  @override
  ConsumerState<_InvoiceListBuilder> createState() => _InvoiceListBuilderState();
}

class _InvoiceListBuilderState extends ConsumerState<_InvoiceListBuilder> {
  bool _isUploading = false;

  Future<void> _uploadProof(String invoiceId, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() => _isUploading = true);
        final bytes = await pickedFile.readAsBytes();
        await ref.read(uploadPaymentProofProvider).uploadProof(invoiceId, bytes, pickedFile.name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bukti pembayaran berhasil diunggah! Menunggu verifikasi RT.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showPaymentActionSheet(BuildContext context, InvoiceModel invoice, String amountFmt, String monthName) {
    if (invoice.status == 'paid') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tagihan ini sudah lunas.')));
      return;
    }
    if (invoice.status == 'awaiting_verification') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bukti sudah diunggah. Menunggu verifikasi admin.')));
      return;
    }

    final paymentInfo = ref.read(residentCommunityPaymentProvider).value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentBottomSheet(
        invoiceId: invoice.id,
        billingTypeName: invoice.billingTypeName,
        periodLabel: 'Periode $monthName',
        amountFormatted: amountFmt,
        amount: invoice.amount,
        paymentInfo: paymentInfo,
        onUpload: (source) => _uploadProof(invoice.id, source),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prefetch payment info agar sudah tersedia saat user tap tagihan
    ref.watch(residentCommunityPaymentProvider);

    if (widget.invoices.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada tagihan di kategori ini',
          style: GoogleFonts.plusJakartaSans(color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(residentInvoicesProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.invoices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final inv = widget.invoices[index];
          final monthName = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(inv.year, inv.month));
          final amountFmt = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(inv.amount);

          Color statusColor;
          String statusText;
          if (inv.status == 'paid') {
            statusColor = RukuninColors.success;
            statusText = 'Lunas';
          } else if (inv.status == 'overdue') {
            statusColor = RukuninColors.error;
            statusText = 'Terlambat';
          } else if (inv.status == 'awaiting_verification') {
            statusColor = const Color(0xFF3B82F6);
            statusText = 'Menunggu Verifikasi Admin';
          } else {
            statusColor = RukuninColors.warning;
            statusText = 'Belum Dibayar';
          }

          return InkWell(
            onTap: _isUploading ? null : () => _showPaymentActionSheet(context, inv, amountFmt, monthName),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_rounded, color: statusColor, size: 28),
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
                            fontSize: 15,
                            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Periode $monthName',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amountFmt,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Payment Bottom Sheet ─────────────────────────────────────────────────────

enum _PaymentStep { selectMethod, transferDetails, qrisDetails }

class _PaymentBottomSheet extends StatefulWidget {
  final String invoiceId;
  final String billingTypeName;
  final String periodLabel;
  final String amountFormatted;
  final double amount;
  final PaymentInfoModel? paymentInfo;
  final void Function(ImageSource) onUpload;

  const _PaymentBottomSheet({
    required this.invoiceId,
    required this.billingTypeName,
    required this.periodLabel,
    required this.amountFormatted,
    required this.amount,
    required this.paymentInfo,
    required this.onUpload,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  late _PaymentStep _step;

  @override
  void initState() {
    super.initState();
    final info = widget.paymentInfo;
    if (info == null || !info.hasAnyMethod) {
      _step = _PaymentStep.selectMethod;
    } else if (info.hasBank && !info.hasQris) {
      _step = _PaymentStep.transferDetails;
    } else if (!info.hasBank && info.hasQris) {
      _step = _PaymentStep.qrisDetails;
    } else {
      _step = _PaymentStep.selectMethod;
    }
  }

  bool get _canGoBack {
    final info = widget.paymentInfo;
    return _step != _PaymentStep.selectMethod && info != null && info.hasBank && info.hasQris;
  }

  void _onBack() {
    if (_canGoBack) {
      setState(() => _step = _PaymentStep.selectMethod);
    } else {
      Navigator.pop(context);
    }
  }

  void _doUpload(ImageSource source) {
    final onUpload = widget.onUpload;
    Navigator.pop(context);
    // Jalankan callback setelah frame selesai agar context bottom sheet sudah clean
    WidgetsBinding.instance.addPostFrameCallback((_) => onUpload(source));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: switch (_step) {
          _PaymentStep.selectMethod => _buildSelectMethod(isDark),
          _PaymentStep.transferDetails => _buildTransferDetails(isDark),
          _PaymentStep.qrisDetails => _buildQrisDetails(isDark),
        },
      ),
    );
  }

  // ── Step 1: Pilih Metode ──────────────────────────────────────────────────

  Widget _buildSelectMethod(bool isDark) {
    final info = widget.paymentInfo;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHeader('Bayar Tagihan', onBack: null, isDark: isDark),
          const SizedBox(height: 16),
          _buildInvoiceSummaryCard(isDark),
          const SizedBox(height: 24),
          Text(
            'Pilih cara pembayaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 12),
          if (info == null || !info.hasAnyMethod)
            _buildNoMethodWarning()
          else ...[
            if (info.hasBank)
              _buildMethodCard(
                icon: Icons.account_balance_rounded,
                title: 'Transfer Bank',
                subtitle: '${info.bankName} · ${_maskAccountNumber(info.accountNumber ?? '')}',
                onTap: () => setState(() => _step = _PaymentStep.transferDetails),
                isDark: isDark,
              ),
            if (info.hasBank && info.hasQris) const SizedBox(height: 12),
            if (info.hasQris)
              _buildMethodCard(
                icon: Icons.qr_code_rounded,
                title: 'Bayar via QRIS',
                subtitle: 'Scan QR dengan e-wallet atau m-banking',
                onTap: () => setState(() => _step = _PaymentStep.qrisDetails),
                isDark: isDark,
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: RukuninColors.brandGreen, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMethodWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RukuninColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RukuninColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: RukuninColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Admin belum mengatur info pembayaran. Hubungi pengurus RT.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: RukuninColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2a: Transfer Bank ────────────────────────────────────────────────

  Widget _buildTransferDetails(bool isDark) {
    final info = widget.paymentInfo!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHeader('Transfer Bank', onBack: _onBack, isDark: isDark),
          const SizedBox(height: 16),
          _buildInvoiceSummaryCard(isDark),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2),
            ),
            child: Column(
              children: [
                _buildDetailRow('Bank', info.bankName ?? '-', isDark: isDark),
                const Divider(height: 24),
                _buildDetailRow(
                  'No. Rekening',
                  info.accountNumber ?? '-',
                  canCopy: true,
                  copyValue: info.accountNumber ?? '',
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _buildDetailRow('Atas Nama', info.accountName ?? '-', isDark: isDark),
                const Divider(height: 24),
                _buildDetailRow(
                  'Nominal',
                  widget.amountFormatted,
                  canCopy: true,
                  copyValue: widget.amount.toInt().toString(),
                  valueStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                  ),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoTip('Gunakan nominal yang tepat agar mudah diverifikasi oleh admin.', isDark),
          const SizedBox(height: 20),
          _buildUploadLabel(isDark),
          const SizedBox(height: 12),
          _buildUploadButtons(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool canCopy = false,
    String copyValue = '',
    TextStyle? valueStyle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: valueStyle ??
                      GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                      ),
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: copyValue));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label disalin'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(Icons.copy_rounded, size: 16, color: RukuninColors.brandGreen),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 2b: QRIS ─────────────────────────────────────────────────────────

  Widget _buildQrisDetails(bool isDark) {
    final qrisUrl = widget.paymentInfo!.qrisUrl!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHeader('Bayar via QRIS', onBack: _onBack, isDark: isDark),
          const SizedBox(height: 16),
          _buildInvoiceSummaryCard(isDark),
          const SizedBox(height: 20),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2, width: 1.5),
              ),
              padding: const EdgeInsets.all(16),
              child: CachedNetworkImage(
                imageUrl: qrisUrl,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                placeholder: (_, _) => const SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, _, _) => SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(child: Icon(Icons.broken_image_rounded, size: 48, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoTip('Buka e-wallet atau m-banking → pilih Scan QR / QRIS → scan kode di atas.', isDark),
          const SizedBox(height: 20),
          _buildUploadLabel(isDark),
          const SizedBox(height: 12),
          _buildUploadButtons(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  Widget _buildSheetHeader(String title, {required VoidCallback? onBack, required bool isDark}) {
    return Row(
      children: [
        if (onBack != null) ...[
          GestureDetector(
            onTap: onBack,
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: RukuninColors.brandGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.billingTypeName,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                widget.periodLabel,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
              ),
            ],
          ),
          Text(
            widget.amountFormatted,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTip(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: RukuninColors.brandGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded, size: 16, color: RukuninColors.brandGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadLabel(bool isDark) {
    return Text(
      'Sudah bayar? Unggah bukti pembayaran',
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildUploadButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: RukuninColors.brandGreen.withValues(alpha: 0.12),
              foregroundColor: RukuninColors.brandGreen,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _doUpload(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: Text('Kamera', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: RukuninColors.brandGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _doUpload(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded, size: 20),
            label: Text('Galeri', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  String _maskAccountNumber(String number) {
    if (number.length <= 4) return number;
    return '${'•' * (number.length - 4)}${number.substring(number.length - 4)}';
  }
}
