import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../models/complaint_model.dart';
import '../providers/layanan_provider.dart';

class AdminComplaintsScreen extends ConsumerStatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  ConsumerState<AdminComplaintsScreen> createState() =>
      _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState
    extends ConsumerState<AdminComplaintsScreen> {
  String _filter = 'semua';

  static const List<String> _filterOptions = ['semua', 'pending', 'in_progress', 'resolved'];
  static const Map<String, String> _filterLabels = {
    'semua': 'Semua',
    'pending': 'Menunggu',
    'in_progress': 'Ditindaklanjuti',
    'resolved': 'Selesai',
  };

  Color _statusColor(String status) {
    return switch (status) {
      'pending'     => AppColors.warning,
      'in_progress' => AppColors.primary,
      'resolved'    => AppColors.success,
      'rejected'    => AppColors.error,
      _             => AppColors.grey400,
    };
  }

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(adminComplaintsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaduan Warga'),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: complaintsAsync.when(
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
                            ref.invalidate(adminComplaintsProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (complaints) {
                final filtered = _filter == 'semua'
                    ? complaints
                    : complaints
                        .where((c) => c.status == _filter)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.report_problem_outlined,
                            color: AppColors.grey400, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada pengaduan',
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
                      ref.invalidate(adminComplaintsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final complaint = filtered[index];
                      return _ComplaintCard(
                        complaint: complaint,
                        statusColor: _statusColor(complaint.status),
                        onUpdateStatus: () =>
                            _showUpdateStatusSheet(context, complaint),
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

  void _showUpdateStatusSheet(BuildContext context, ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UpdateStatusSheet(complaint: complaint),
    );
  }
}

// ─────────────────────────────────────────────────────
//  COMPLAINT CARD
// ─────────────────────────────────────────────────────
class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final Color statusColor;
  final VoidCallback onUpdateStatus;

  const _ComplaintCard({
    required this.complaint,
    required this.statusColor,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM y', 'id').format(complaint.createdAt);

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
          // Top row: title + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  complaint.statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              complaint.categoryLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.grey600,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Resident name + unit
          Text(
            complaint.residentName ?? '-',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
          if (complaint.residentUnit != null) ...[
            const SizedBox(height: 2),
            Text(
              'Unit ${complaint.residentUnit}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.grey500,
              ),
            ),
          ],
          const SizedBox(height: 6),

          // Date
          Text(
            dateStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.grey400,
            ),
          ),

          // Photo thumbnail
          if (complaint.photoUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                complaint.photoUrl!,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 80,
                  color: AppColors.grey200,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.grey400),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Update Status button
          SizedBox(
            width: double.infinity,
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
    );
  }
}

// ─────────────────────────────────────────────────────
//  UPDATE STATUS SHEET
// ─────────────────────────────────────────────────────
class _UpdateStatusSheet extends ConsumerStatefulWidget {
  final ComplaintModel complaint;
  const _UpdateStatusSheet({required this.complaint});

  @override
  ConsumerState<_UpdateStatusSheet> createState() =>
      _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<_UpdateStatusSheet> {
  String _selectedStatus = 'in_progress';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  static const _statusOptions = [
    ('in_progress', 'Ditindaklanjuti'),
    ('resolved', 'Selesai'),
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
            'Update Status Pengaduan',
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
      await ref.read(layananServiceProvider).updateComplaintStatus(
            complaintId: widget.complaint.id,
            residentId: widget.complaint.residentId,
            communityId: widget.complaint.communityId,
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
