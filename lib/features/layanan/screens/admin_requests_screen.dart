import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../models/letter_request_model.dart';
import '../providers/layanan_provider.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> {
  String _filter = 'semua';

  static const _filterOptions = ['semua', 'pending', 'in_progress', 'ready', 'completed'];
  static const _filterLabels = {
    'semua': 'Semua',
    'pending': 'Menunggu',
    'in_progress': 'Diproses',
    'ready': 'Siap',
    'completed': 'Selesai',
  };

  Color _statusColor(String status) {
    return switch (status) {
      'pending'     => AppColors.warning,
      'in_progress' => AppColors.primary,
      'ready'       => AppColors.success,
      'completed'   => AppColors.grey500,
      'rejected'    => AppColors.error,
      _             => AppColors.grey400,
    };
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminLetterRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permohonan Surat Warga'),
      ),
      body: Column(
        children: [
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
                  backgroundColor: AppColors.grey200,
                  selectedColor: AppColors.primary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.onPrimary : AppColors.grey800,
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
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat data',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.grey800)),
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
                        const Icon(Icons.article_outlined,
                            color: AppColors.grey400, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada permohonan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
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
                        onUpdateStatus: () =>
                            _showUpdateStatusSheet(context, request),
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

  void _showUpdateStatusSheet(
      BuildContext context, LetterRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UpdateStatusSheet(request: request),
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
  final VoidCallback onUpdateStatus;

  const _RequestCard({
    required this.request,
    required this.index,
    required this.statusColor,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM y', 'id').format(request.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '#SRT-${(index + 1).toString().padLeft(3, '0')}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey600,
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
              color: AppColors.grey800,
            ),
          ),
          if (request.residentUnit != null) ...[
            const SizedBox(height: 2),
            Text(
              'Unit ${request.residentUnit}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.grey500,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Type label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              request.typeLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
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
                color: AppColors.grey600,
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
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    context.push('/admin/surat/buat', extra: {
                      'prefilledResidentId': request.residentId,
                      'prefilledLetterType': request.letterType,
                      'prefilledPurpose': request.purpose,
                      'fromRequestId': request.id,
                    });
                  },
                  child: const Text('Buat Surat'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.grey300),
                    textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: onUpdateStatus,
                  child: const Text('Update Status'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  UPDATE STATUS SHEET
// ─────────────────────────────────────────────────────
class _UpdateStatusSheet extends ConsumerStatefulWidget {
  final LetterRequestModel request;
  const _UpdateStatusSheet({required this.request});

  @override
  ConsumerState<_UpdateStatusSheet> createState() =>
      _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<_UpdateStatusSheet> {
  String _selectedStatus = 'in_progress';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  static const _statusOptions = [
    ('in_progress', 'Diproses'),
    ('ready', 'Siap Diambil'),
    ('completed', 'Selesai'),
    ('rejected', 'Ditolak'),
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Update Status Permohonan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey800,
            ),
          ),
          const SizedBox(height: 16),

          // Status dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status Baru',
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            items: _statusOptions
                .map((s) => DropdownMenuItem(
                      value: s.$1,
                      child: Text(s.$2,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedStatus = v);
            },
          ),
          const SizedBox(height: 12),

          // Admin notes
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Catatan Admin (opsional)',
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          // Simpan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.onPrimary, strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(layananServiceProvider).updateLetterRequestStatus(
            requestId: widget.request.id,
            residentId: widget.request.residentId,
            communityId: widget.request.communityId,
            newStatus: _selectedStatus,
            adminNotes:
                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update status: $e',
                style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
