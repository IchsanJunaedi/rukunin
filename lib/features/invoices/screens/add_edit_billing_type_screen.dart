import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/tokens.dart';
import '../models/billing_type_model.dart';
import '../providers/billing_type_provider.dart';

class AddEditBillingTypeScreen extends ConsumerStatefulWidget {
  final BillingTypeModel? billingType;

  const AddEditBillingTypeScreen({super.key, this.billingType});

  @override
  ConsumerState<AddEditBillingTypeScreen> createState() =>
      _AddEditBillingTypeScreenState();
}

class _AddEditBillingTypeScreenState
    extends ConsumerState<AddEditBillingTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _costPerMotorcycleCtrl;
  late TextEditingController _costPerCarCtrl;
  int _billingDay = 10;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.billingType?.name ?? '');
    _amountCtrl = TextEditingController(
        text: widget.billingType?.amount.toInt().toString() ?? '');
    _costPerMotorcycleCtrl = TextEditingController(
        text: widget.billingType?.costPerMotorcycle.toInt().toString() ?? '0');
    _costPerCarCtrl = TextEditingController(
        text: widget.billingType?.costPerCar.toInt().toString() ?? '0');
    _billingDay = widget.billingType?.billingDay ?? 10;
    _isActive = widget.billingType?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _costPerMotorcycleCtrl.dispose();
    _costPerCarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameCtrl.text.trim();
      final amount = double.parse(_amountCtrl.text.trim());
      final costPerMotorcycle = double.tryParse(_costPerMotorcycleCtrl.text.trim()) ?? 0;
      final costPerCar = double.tryParse(_costPerCarCtrl.text.trim()) ?? 0;

      final notifier = ref.read(billingTypesProvider.notifier);

      if (widget.billingType == null) {
        final newType = BillingTypeModel(
          id: '',
          communityId: '',
          name: name,
          amount: amount,
          billingDay: _billingDay,
          isActive: _isActive,
          costPerMotorcycle: costPerMotorcycle,
          costPerCar: costPerCar,
          createdAt: DateTime.now(),
        );
        await notifier.addBillingType(newType);
      } else {
        final updatedType = widget.billingType!.copyWith(
          name: name,
          amount: amount,
          billingDay: _billingDay,
          isActive: _isActive,
          costPerMotorcycle: costPerMotorcycle,
          costPerCar: costPerCar,
        );
        await notifier.updateBillingType(updatedType);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Jenis Iuran berhasil ${widget.billingType == null ? 'ditambahkan' : 'diperbarui'}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.billingType != null;
    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Iuran' : 'Tambah Iuran',
          style: RukuninFonts.pjs(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
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
                    Text('Nama Iuran', style: RukuninFonts.pjs(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                    )),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Kas RT, Keamanan, Kebersihan',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text('Nominal (Rp)', style: RukuninFonts.pjs(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                    )),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 50000',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Wajib diisi';
                        }
                        if (double.tryParse(val) == null) {
                          return 'Harus berupa angka valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('Tanggal Jatuh Tempo Tiap Bulan', style: RukuninFonts.pjs(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                    )),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _billingDay,
                      decoration: const InputDecoration(filled: true),
                      items: List.generate(28, (index) => index + 1)
                          .map((day) => DropdownMenuItem(
                                value: day,
                                child: Text('Tanggal $day'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _billingDay = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    // Tarif Kendaraan
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: RukuninColors.brandGreen.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.two_wheeler, size: 16, color: RukuninColors.brandGreen),
                              const SizedBox(width: 8),
                              Text('Tarif Tambahan per Kendaraan',
                                  style: RukuninFonts.pjs(
                                    fontWeight: FontWeight.w700, fontSize: 13, color: RukuninColors.brandGreen)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Isi jika iuran ini dikenakan tambahan berdasarkan jumlah kendaraan warga (misal: iuran Ronda). Kosongkan atau isi 0 jika tidak perlu.',
                            style: RukuninFonts.pjs(fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _costPerMotorcycleCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tambahan per Motor (Rp)',
                              prefixIcon: const Icon(Icons.two_wheeler, size: 18),
                              fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _costPerCarCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tambahan per Mobil (Rp)',
                              prefixIcon: const Icon(Icons.directions_car_outlined, size: 18),
                              fillColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status Aktif',
                                style: RukuninFonts.pjs(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isActive
                                    ? 'Tagihan akan diterbitkan'
                                    : 'Tagihan iuran ini dinonaktifkan',
                                style: RukuninFonts.pjs(
                                  fontSize: 12,
                                  color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isActive,
                            activeThumbColor: RukuninColors.success,
                            onChanged: (val) => setState(() => _isActive = val),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RukuninColors.brandGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _save,
                        child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Iuran'),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
