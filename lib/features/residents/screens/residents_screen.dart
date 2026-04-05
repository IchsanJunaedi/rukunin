import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:go_router/go_router.dart';
import '../../../app/components.dart';
import '../../../app/tokens.dart';
import '../models/resident_model.dart';
import '../providers/resident_provider.dart';
import 'package:intl/intl.dart';

class ResidentsScreen extends ConsumerStatefulWidget {
  const ResidentsScreen({super.key});

  @override
  ConsumerState<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends ConsumerState<ResidentsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final residentsAsync = ref.watch(residentsProvider);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Data Warga',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _importCsv(context),
                        icon: const Icon(
                          Icons.file_upload_outlined,
                          color: Colors.white,
                        ),
                        tooltip: 'Import CSV / Excel',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    style: RukuninFonts.pjs(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau nomor unit...',
                      hintStyle: RukuninFonts.pjs(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Counter chip + Pending banner
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                residentsAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                  data: (list) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: RukuninColors.brandGreen,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${list.length} Warga',
                            style: RukuninFonts.pjs(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Pending approval banner
                _PendingBanner(onApprovalDone: () {
                  ref.invalidate(residentsProvider);
                  ref.invalidate(pendingResidentsProvider);
                }),
              ],
            ),
          ),

          // List
          residentsAsync.when(
            loading: () => SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: RukuninColors.brandGreen),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Gagal memuat daftar warga',
                  description: 'Periksa koneksi internet, lalu coba lagi.',
                  ctaLabel: 'Coba lagi',
                  onCta: () => ref.invalidate(residentsProvider),
                ),
              ),
            ),
            data: (list) {
              final filtered = _query.isEmpty
                  ? list
                  : list
                        .where(
                          (r) =>
                              r.fullName.toLowerCase().contains(_query) ||
                              (r.unitNumber?.toLowerCase().contains(_query) ??
                                  false),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _query.isEmpty
                              ? 'Belum ada warga terdaftar'
                              : 'Tidak ditemukan',
                          style: RukuninFonts.pjs(
                            color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ResidentCard(
                      resident: filtered[i],
                      onEdit: () => context
                          .push('/admin/warga/edit', extra: filtered[i])
                          .then((_) => ref.invalidate(residentsProvider)),
                      onTapCard: () => context
                          .push('/admin/warga/detail', extra: filtered[i])
                          .then((_) => ref.invalidate(residentsProvider)),
                      onDelete: () => _confirmDelete(context, filtered[i]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context
            .push('/admin/warga/tambah')
            .then((_) => ref.invalidate(residentsProvider)),
        backgroundColor: RukuninColors.brandGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Tambah Warga',
          style: RukuninFonts.pjs(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ResidentModel resident,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus Warga',
          style: RukuninFonts.pjs(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Hapus ${resident.fullName} dari data warga? Tindakan ini tidak bisa dibatalkan.',
          style: RukuninFonts.pjs(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: RukuninColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref
          .read(residentNotifierProvider.notifier)
          .deleteResident(resident.id);
      if (context.mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${resident.fullName} dihapus'),
            backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importCsv(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String csvValue = '';

      if (kIsWeb) {
        if (file.bytes != null) {
          csvValue = utf8.decode(file.bytes!);
        }
      } else {
        if (file.path != null) {
          csvValue = await File(file.path!).readAsString();
        }
      }

      if (csvValue.isEmpty) return;

      // Parsing CSV Manual
      final lines = const LineSplitter().convert(csvValue);
      final rows = lines
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.split(',').map((e) => e.trim()).toList())
          .toList();

      if (rows.length < 2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File CSV kosong atau format salah.'),
              backgroundColor: RukuninColors.error,
            ),
          );
        }
        return;
      }

      // Ambil headers (baris pertama)
      final headers = rows.first
          .map((e) => e.toString().trim().toLowerCase())
          .toList();

      // Cek kolom wajib (nama_lengkap)
      final nameIdx = headers.indexOf('nama_lengkap');
      final nikIdx = headers.indexOf('nik');
      final unitIdx = headers.indexOf('nomor_unit');
      final phoneIdx = headers.indexOf('nomor_hp');
      final rtIdx = headers.indexOf('rt');
      final blockIdx = headers.indexOf('blok');

      if (nameIdx == -1) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kolom wajib "nama_lengkap" tidak ditemukan dalam CSV.',
              ),
              backgroundColor: RukuninColors.error,
            ),
          );
        }
        return;
      }

      final List<Map<String, dynamic>> residentsData = [];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row[nameIdx].toString().trim().isEmpty) continue;

        residentsData.add({
          'full_name': row[nameIdx].toString().trim(),
          'nik': nikIdx != -1 && row.length > nikIdx
              ? row[nikIdx].toString().trim()
              : '',
          'unit_number': unitIdx != -1 && row.length > unitIdx
              ? row[unitIdx].toString().trim()
              : '',
          'phone': phoneIdx != -1 && row.length > phoneIdx
              ? row[phoneIdx].toString().trim()
              : '',
          'rt_number': rtIdx != -1 && row.length > rtIdx
              ? int.tryParse(row[rtIdx].toString().trim()) ?? 1
              : 1,
          'block': blockIdx != -1 && row.length > blockIdx
              ? row[blockIdx].toString().trim()
              : '',
        });
      }

      if (residentsData.isEmpty) return;

      // Tampilkan dialog konfirmasi
      if (context.mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Import ${residentsData.length} Warga',
              style: RukuninFonts.pjs(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Apakah Anda yakin ingin mengimpor data ini?',
              style: RukuninFonts.pjs(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          await ref
              .read(residentNotifierProvider.notifier)
              .importCsv(residentsData);
          if (context.mounted) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final state = ref.read(residentNotifierProvider);
            if (state.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal import: ${state.error}'),
                  backgroundColor: RukuninColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${residentsData.length} warga berhasil diimport',
                  ),
                  backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membaca file: $e'),
            backgroundColor: RukuninColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ============================================================
// Pending Approval Banner
// ============================================================
class _PendingBanner extends ConsumerWidget {
  final VoidCallback onApprovalDone;

  const _PendingBanner({required this.onApprovalDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingResidentsProvider);

    return pendingAsync.when(
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
      data: (pending) {
        if (pending.isEmpty) return const SizedBox();
        return GestureDetector(
          onTap: () => _showPendingSheet(context, ref, pending),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: RukuninColors.brandGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions_rounded, color: RukuninColors.brandGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pending.length} warga baru menunggu persetujuan',
                    style: RukuninFonts.pjs(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: RukuninColors.brandGreen,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: RukuninColors.brandGreen, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPendingSheet(
    BuildContext context,
    WidgetRef ref,
    List<ResidentModel> pending,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PendingSheet(
        pending: pending,
        ref: ref,
        onDone: onApprovalDone,
      ),
    );
  }
}

class _PendingSheet extends StatelessWidget {
  final List<ResidentModel> pending;
  final WidgetRef ref;
  final VoidCallback onDone;

  const _PendingSheet({
    required this.pending,
    required this.ref,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Text(
                    'Permintaan Bergabung',
                    style: RukuninFonts.pjs(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: RukuninColors.brandGreen,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${pending.length}',
                      style: RukuninFonts.pjs(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: pending.length,
                itemBuilder: (ctx, i) => _PendingCard(
                  resident: pending[i],
                  onApprove: () async {
                    await ref
                        .read(residentNotifierProvider.notifier)
                        .approveResident(pending[i].id);
                    onDone();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  onReject: () async {
                    await ref
                        .read(residentNotifierProvider.notifier)
                        .rejectResident(pending[i].id);
                    onDone();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showPendingDetailSheet(
  BuildContext context,
  ResidentModel resident,
  VoidCallback onApprove,
  VoidCallback onReject,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Detail Warga Pending',
              style: RukuninFonts.pjs(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _pendingDetailRow(Icons.person_rounded, 'Nama Lengkap', resident.fullName),
            _pendingDetailRow(Icons.phone_android_rounded, 'No. Handphone', resident.phone ?? '-'),
            _pendingDetailRow(Icons.badge_rounded, 'NIK', resident.nik ?? '-'),
            _pendingDetailRow(
              Icons.home_work_rounded,
              'Blok / Unit',
              () {
                final parts = <String>[];
                if (resident.block != null && resident.block!.isNotEmpty) parts.add('Blok ${resident.block}');
                if (resident.unitNumber != null && resident.unitNumber!.isNotEmpty) parts.add('No. ${resident.unitNumber}');
                return parts.isNotEmpty ? parts.join(' ') : '-';
              }(),
            ),
            _pendingDetailRow(Icons.numbers_rounded, 'RT', resident.rtNumber != null ? 'RT ${resident.rtNumber}' : '-'),
            _pendingDetailRow(
              Icons.calendar_today_rounded,
              'Tanggal Daftar',
              DateFormat('d MMMM yyyy', 'id_ID').format(resident.createdAt),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onReject();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RukuninColors.error,
                      side: const BorderSide(color: RukuninColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Tolak', style: RukuninFonts.pjs(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onApprove();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RukuninColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Setujui', style: RukuninFonts.pjs(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _pendingDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Icon(icon, size: 18, color: RukuninColors.brandGreen),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: RukuninFonts.pjs(fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                    ),
                    Text(
                      value,
                      style: RukuninFonts.pjs(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    ),
  );
}

class _PendingCard extends StatelessWidget {
  final ResidentModel resident;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingCard({
    required this.resident,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final joinedAt = DateFormat('d MMM yyyy', 'id_ID').format(resident.createdAt);
    return GestureDetector(
      onTap: () => _showPendingDetailSheet(context, resident, onApprove, onReject),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: resident.photoUrl != null && resident.photoUrl!.isNotEmpty
                    ? Image.network(
                        resident.photoUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _pendingInitialsBox(resident),
                      )
                    : _pendingInitialsBox(resident),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resident.fullName,
                      style: RukuninFonts.pjs(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      [
                        if (resident.phone != null) resident.phone!,
                        'Daftar $joinedAt',
                      ].join(' · '),
                      style: RukuninFonts.pjs(
                        fontSize: 11,
                        color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RukuninColors.error,
                    side: const BorderSide(color: RukuninColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Tolak',
                    style: RukuninFonts.pjs(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RukuninColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Setujui',
                    style: RukuninFonts.pjs(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

Widget _initialsBox(ResidentModel resident, double size, double radius) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: resident.isActive ? RukuninColors.brandGreen : const Color(0xFF3A3A3A),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Center(
      child: Text(
        resident.initials,
        style: RukuninFonts.pjs(
          color: Colors.white,
          fontSize: size * 0.33,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

Widget _pendingInitialsBox(ResidentModel resident) {
  return Container(
    width: 44,
    height: 44,
    color: RukuninColors.brandGreen.withValues(alpha: 0.15),
    child: Center(
      child: Text(
        resident.initials,
        style: RukuninFonts.pjs(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _ResidentCard extends StatelessWidget {
  final ResidentModel resident;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTapCard;

  const _ResidentCard({
    required this.resident,
    required this.onEdit,
    required this.onDelete,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTapCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: resident.photoUrl != null && resident.photoUrl!.isNotEmpty
              ? Image.network(
                  resident.photoUrl!,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _initialsBox(resident, 46, 14),
                )
              : _initialsBox(resident, 46, 14),
        ),
        title: Text(
          resident.fullName,
          style: RukuninFonts.pjs(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
        subtitle: Text(
          [
            if (resident.block != null && resident.block!.isNotEmpty) 'Blok ${resident.block}',
            if (resident.unitNumber != null) 'No. ${resident.unitNumber}',
            if (resident.phone != null) resident.phone!,
          ].join(' · '),
          style: RukuninFonts.pjs(
            fontSize: 12,
            color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  SizedBox(width: 10),
                  Text('Hapus', style: TextStyle(color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ],
          child: Icon(Icons.more_vert_rounded, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
        ),
      ),
    );
  }
}
