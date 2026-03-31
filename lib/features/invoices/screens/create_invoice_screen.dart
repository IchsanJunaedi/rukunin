import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../models/billing_type_model.dart';
import '../providers/billing_type_provider.dart';
import '../providers/invoice_list_provider.dart';
import '../../resident_portal/providers/resident_invoices_provider.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  BillingTypeModel? _selectedBillingType;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  bool _isMonthDisabled(int month) {
    if (_selectedYear > DateTime.now().year) return false;
    return month < DateTime.now().month;
  }

  // Hitung default due date dari billingDay, minimal hari ini
  DateTime _computeDefaultDueDate(BillingTypeModel billingType, int month, int year) {
    final today = DateTime.now();
    final calculated = DateTime(year, month, billingType.billingDay);
    return calculated.isBefore(DateTime(today.year, today.month, today.day))
        ? DateTime(today.year, today.month, today.day)
        : calculated;
  }

  void _onBillingTypeSelected(BillingTypeModel t) {
    setState(() {
      _selectedBillingType = t;
      _selectedDueDate = _computeDefaultDueDate(t, _selectedMonth, _selectedYear);
    });
  }

  void _onPeriodChanged({int? month, int? year}) {
    final newMonth = month ?? _selectedMonth;
    final newYear = year ?? _selectedYear;
    setState(() {
      _selectedMonth = newMonth;
      _selectedYear = newYear;
      if (_selectedBillingType != null) {
        _selectedDueDate = _computeDefaultDueDate(_selectedBillingType!, newMonth, newYear);
      }
    });
  }

  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final initial = _selectedDueDate ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: DateTime(today.year + 3, 12, 31),
      helpText: 'Pilih Tanggal Jatuh Tempo',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: RukuninColors.brandGreen,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _generateInvoices() async {
    if (_selectedBillingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis iuran terlebih dahulu')),
      );
      return;
    }
    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal jatuh tempo terlebih dahulu')),
      );
      return;
    }

    final now = DateTime.now();
    if (_selectedYear < now.year ||
        (_selectedYear == now.year && _selectedMonth < now.month)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuat tagihan untuk bulan yang sudah lewat.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dueDateFmt = DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDueDate!);
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Terbitkan Tagihan?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'Tagihan ${_selectedBillingType!.name} untuk periode '
          '${_months[_selectedMonth - 1]} $_selectedYear akan diterbitkan ke '
          'semua warga aktif.\n\nJatuh tempo: $dueDateFmt',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RukuninColors.brandGreen,
              foregroundColor: Colors.white,
            ),
            child: Text('Ya, Terbitkan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(invoiceListProvider.notifier);
      await notifier.generateBulkInvoices(
        billingTypeId: _selectedBillingType!.id,
        amount: _selectedBillingType!.amount,
        dueDate: _selectedDueDate!,
        month: _selectedMonth,
        year: _selectedYear,
        costPerMotorcycle: _selectedBillingType!.costPerMotorcycle,
        costPerCar: _selectedBillingType!.costPerCar,
      );

      if (mounted) {
        // Sync filter ke bulan/tahun tagihan yang baru dibuat agar langsung terlihat
        ref.read(invoiceMonthFilterProvider.notifier).setMonth(_selectedMonth);
        ref.read(invoiceYearFilterProvider.notifier).setYear(_selectedYear);
        ref.invalidate(invoiceWithResidentProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tagihan berhasil diterbitkan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerbitkan tagihan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final billingTypesAsync = ref.watch(billingTypesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Terbitkan Tagihan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: RukuninColors.brandGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tagihan akan diterbitkan ke seluruh warga (Resident) aktif yang terdaftar di komunitas ini.',
                            style: GoogleFonts.poppins(fontSize: 13, color: RukuninColors.brandGreen),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Jenis Iuran ──────────────────────────────────────────
                  Text('Jenis Iuran', style: AppTextStyles.label(14)),
                  const SizedBox(height: 8),
                  billingTypesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (types) {
                      final activeTypes = types.where((t) => t.isActive).toList();
                      if (activeTypes.isEmpty) {
                        return Text(
                          'Belum ada Jenis Iuran aktif. Tambahkan pada Pengaturan Jenis Iuran.',
                          style: GoogleFonts.poppins(color: RukuninColors.error),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeTypes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final t = activeTypes[index];
                          final isSelected = _selectedBillingType?.id == t.id;
                          return GestureDetector(
                            onTap: () => _onBillingTypeSelected(t),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? RukuninColors.brandGreen.withValues(alpha: 0.05) : (isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? RukuninColors.brandGreen : (isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected ? RukuninColors.brandGreen : (isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Nominal: ${currencyFormat.format(t.amount)}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 13, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Periode Tagihan ──────────────────────────────────────
                  Text('Periode Tagihan', style: AppTextStyles.label(14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: _selectedMonth,
                          decoration: const InputDecoration(filled: true, labelText: 'Bulan'),
                          items: List.generate(12, (index) {
                            final month = index + 1;
                            final disabled = _isMonthDisabled(month);
                            return DropdownMenuItem(
                              value: month,
                              enabled: !disabled,
                              child: Text(
                                _months[index],
                                style: TextStyle(color: disabled ? Colors.grey.shade400 : null),
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null && !_isMonthDisabled(val)) {
                              _onPeriodChanged(month: val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          value: _selectedYear,
                          decoration: const InputDecoration(filled: true, labelText: 'Tahun'),
                          items: List.generate(4, (index) {
                            final yearVal = DateTime.now().year + index;
                            return DropdownMenuItem(
                              value: yearVal,
                              child: Text(yearVal.toString()),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              _onPeriodChanged(
                                year: val,
                                month: _isMonthDisabled(_selectedMonth) ? DateTime.now().month : _selectedMonth,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Tanggal Jatuh Tempo ──────────────────────────────────
                  Text('Tanggal Jatuh Tempo', style: AppTextStyles.label(14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDueDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDueDate != null ? RukuninColors.brandGreen : (isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                          width: _selectedDueDate != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            color: _selectedDueDate != null ? RukuninColors.brandGreen : (isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _selectedDueDate != null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDueDate!),
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                                        ),
                                      ),
                                      if (_selectedBillingType != null)
                                        Text(
                                          'Tanggal billing default: ${_selectedBillingType!.billingDay}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                                        ),
                                    ],
                                  )
                                : Text(
                                    _selectedBillingType == null
                                        ? 'Pilih jenis iuran dahulu'
                                        : 'Ketuk untuk memilih tanggal',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                                  ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedBillingType != null && _selectedDueDate == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Wajib pilih tanggal jatuh tempo',
                        style: GoogleFonts.poppins(fontSize: 12, color: RukuninColors.error),
                      ),
                    ),

                  // ── Ringkasan ────────────────────────────────────────────
                  if (_selectedBillingType != null && _selectedDueDate != null) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ringkasan Tagihan',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
                          const SizedBox(height: 12),
                          _summaryRow('Jenis Iuran', _selectedBillingType!.name),
                          const Divider(height: 20),
                          _summaryRow('Periode', '${_months[_selectedMonth - 1]} $_selectedYear'),
                          const Divider(height: 20),
                          _summaryRow(
                            'Nominal',
                            currencyFormat.format(_selectedBillingType!.amount),
                            valueColor: RukuninColors.brandGreen,
                            valueBold: true,
                          ),
                          const Divider(height: 20),
                          _summaryRow(
                            'Jatuh Tempo',
                            DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDueDate!),
                            valueColor: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_selectedBillingType == null || _selectedDueDate == null)
                          ? null
                          : _generateInvoices,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RukuninColors.brandGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
                      ),
                      child: Text(
                        'Terbitkan ke Semua Warga',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor, bool valueBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? (isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
          ),
        ),
      ],
    );
  }
}
