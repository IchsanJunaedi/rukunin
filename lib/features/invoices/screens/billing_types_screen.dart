import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../models/billing_type_model.dart';
import '../providers/billing_type_provider.dart';
import 'add_edit_billing_type_screen.dart';

class BillingTypesScreen extends ConsumerWidget {
  const BillingTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final billingTypesAsync = ref.watch(billingTypesProvider);
    final currencyFormat = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Konfigurasi Iuran',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditBillingTypeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: billingTypesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (types) {
          if (types.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.request_page_outlined, size: 64, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada jenis iuran',
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              return _buildBillingTypeCard(context, ref, type, currencyFormat);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditBillingTypeScreen(),
            ),
          );
        },
        backgroundColor: RukuninColors.brandGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBillingTypeCard(BuildContext context, WidgetRef ref, BillingTypeModel type, NumberFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: type.isActive ? (isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2) : (isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2),
        ),
      ),
      child: Opacity(
        opacity: type.isActive ? 1.0 : 0.5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              type.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!type.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Nonaktif',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          format.format(type.amount),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: RukuninColors.brandGreen,
                          ),
                        ),
                        if (type.costPerMotorcycle > 0 || type.costPerCar > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '+${format.format(type.costPerMotorcycle)}/motor · +${format.format(type.costPerCar)}/mobil',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: type.isActive,
                    activeThumbColor: RukuninColors.success,
                    onChanged: (val) async {
                      final notifier = ref.read(billingTypesProvider.notifier);
                      try {
                        await notifier.updateBillingType(type.copyWith(isActive: val));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: $e')),
                          );
                        }
                      }
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
                    onSelected: (val) async {
                      if (val == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditBillingTypeScreen(billingType: type),
                          ),
                        );
                      } else if (val == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Hapus Jenis Iuran',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                            content: Text(
                              'Yakin ingin menghapus "${type.name}"?\nData historis tagihan tetap tersimpan.',
                              style: GoogleFonts.plusJakartaSans(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Batal', style: GoogleFonts.plusJakartaSans()),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: RukuninColors.error),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('Hapus',
                                    style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          try {
                            await ref.read(billingTypesProvider.notifier).deleteBillingType(type.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${type.name} berhasil dihapus'),
                                  backgroundColor: RukuninColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal hapus: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
                            const SizedBox(width: 8),
                            Text('Edit Iuran', style: GoogleFonts.plusJakartaSans()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: RukuninColors.error),
                            const SizedBox(width: 8),
                            Text('Hapus', style: GoogleFonts.plusJakartaSans(color: RukuninColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 15, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                  const SizedBox(width: 8),
                  Text(
                    'Jatuh tempo tiap tanggal ${type.billingDay} setiap bulan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
