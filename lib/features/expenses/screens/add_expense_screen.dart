import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = ExpenseModel.categories.first;
  DateTime _expenseDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
      final expense = ExpenseModel(
        id: '',
        communityId: '',
        amount: amount,
        category: _category,
        description: _descCtrl.text.trim(),
        expenseDate: _expenseDate,
        createdAt: DateTime.now(),
      );
      await ref.read(expensesProvider.notifier).addExpense(expense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil dicatat!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMMM yyyy', 'id_ID').format(_expenseDate);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        title: Text(
          'Catat Pengeluaran',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nominal ──
                    _label('Nominal (Rp)'),
                    _card(TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.surface),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.grey300),
                        prefixText: 'Rp ',
                        prefixStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.grey500),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        final num = double.tryParse(
                            v.replaceAll('.', '').replaceAll(',', ''));
                        if (num == null || num <= 0) return 'Harus lebih dari 0';
                        return null;
                      },
                    )),
                    const SizedBox(height: 16),

                    // ── Kategori ──
                    _label('Kategori'),
                    _card(Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          isExpanded: true,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey800),
                          items: ExpenseModel.categories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _category = v!),
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),

                    // ── Keterangan ──
                    _label('Keterangan'),
                    _card(TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'Contoh: Bayar tukang potong rumput Pak Budi...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: AppColors.grey400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Keterangan wajib diisi'
                          : null,
                    )),
                    const SizedBox(height: 16),

                    // ── Tanggal ──
                    _label('Tanggal Pengeluaran'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: _card(Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              dateLabel,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey800),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right,
                                color: AppColors.grey400),
                          ],
                        ),
                      )),
                    ),
                    const SizedBox(height: 32),

                    // ── Tombol Simpan ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _save,
                        child: Text(
                          'Simpan Pengeluaran',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.grey600,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _card(Widget child) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );
}
