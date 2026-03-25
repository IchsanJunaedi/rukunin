import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/tokens.dart';
import '../models/letter_request_model.dart';
import '../providers/layanan_provider.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> {
  String _filter = 'semua';

  static const _filterOptions = ['semua', 'pending', 'verified', 'completed', 'rejected'];
  static const _filterLabels = {
    'semua': 'Semua',
    'pending': 'Menunggu',
    'verified': 'Surat Siap',
    'completed': 'Selesai',
    'rejected': 'Ditolak',
  };

  Color _statusColor(String status) {
    return switch (status) {
      'pending'   => RukuninColors.warning,
      'verified'  => RukuninColors.success,
      'completed' => RukuninColors.darkTextTertiary,
      'rejected'  => RukuninColors.error,
      _           => RukuninColors.darkTextTertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestsAsync = ref.watch(adminLetterRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permohonan Surat Warga'),
      ),
      body: Column(
        children: [
          // Banner Kelola Kontak — di atas filter chips
          GestureDetector(
            onTap: () => context.push('/admin/layanan/kontak'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: RukuninColors.brandGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: RukuninColors.brandGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.contacts_outlined,
                        color: RukuninColors.brandGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola Informasi Kontak',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Atur kontak pengurus yang tampil ke warga',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                ],
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filterOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                final selected = _filter == option;
                return FilterChip(
                  label: Text(_filterLabels[option] ?? option),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = option),
                  backgroundColor: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
                  selectedColor: RukuninColors.brandGreen,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : (isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
                  ),
                  showCheckmark: false,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                );
              },
            ),
          ),

          // List
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: RukuninColors.brandGreen),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: RukuninColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat data',
                          style: GoogleFonts.plusJakartaSans(
                              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(adminLetterRequestsProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (requests) {
                final filtered = _filter == 'semua'
                    ? requests
                    : requests
                        .where((r) => r.status == _filter)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.article_outlined,
                            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada permohonan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: RukuninColors.brandGreen,
                  onRefresh: () async =>
                      ref.invalidate(adminLetterRequestsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final request = filtered[index];
                      return _RequestCard(
                        request: request,
                        index: index,
                        statusColor: _statusColor(request.status),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────
//  REQUEST CARD
// ─────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final LetterRequestModel request;
  final int index;
  final Color statusColor;

  const _RequestCard({
    required this.request,
    required this.index,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('d MMM y', 'id').format(request.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: serial number chip + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '#SRT-${(index + 1).toString().padLeft(3, '0')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  request.statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Resident name + unit
          Text(
            request.residentName ?? '-',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          if (request.residentUnit != null) ...[
            const SizedBox(height: 2),
            Text(
              'Unit ${request.residentUnit}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Type label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RukuninColors.brandGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              request.typeLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          // Purpose
          if (request.purpose != null) ...[
            const SizedBox(height: 8),
            Text(
              request.purpose!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),

          // Date
          Text(
            dateStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RukuninColors.brandGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => context.push('/admin/layanan-verifikasi/${request.id}', extra: request),
                  child: const Text('Verifikasi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

