import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
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
    final isEdit = widget.billingType != null;
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Iuran' : 'Tambah Iuran',
          style: GoogleFonts.plusJakartaSans(
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
                    Text('Nama Iuran', style: AppTextStyles.label(14)),
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
                    Text('Nominal (Rp)', style: AppTextStyles.label(14)),
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
                    Text('Tangal Jatuh Tempo Tiap Bulan', style: AppTextStyles.label(14)),
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
                    // Tarif Kendaraan (khusus Ronda/Keamanan)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.two_wheeler, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text('Tarif Tambahan per Kendaraan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700, fontSize: 13, color: Colors.blue.shade700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Isi jika iuran ini dikenakan tambahan berdasarkan jumlah kendaraan warga (misal: iuran Ronda). Kosongkan atau isi 0 jika tidak perlu.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.grey500),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _costPerMotorcycleCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tambahan per Motor (Rp)',
                              prefixIcon: const Icon(Icons.two_wheeler, size: 18),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _costPerCarCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tambahan per Mobil (Rp)',
                              prefixIcon: const Icon(Icons.directions_car_outlined, size: 18),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status Aktif',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.grey800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isActive
                                    ? 'Tagihan akan diterbitkan'
                                    : 'Tagihan iuran ini dinonaktifkan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isActive,
                            activeThumbColor: AppColors.success,
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
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
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
