import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../app/tokens.dart';
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
      'pending'     => RukuninColors.warning,
      'in_progress' => RukuninColors.brandGreen,
      'resolved'    => RukuninColors.success,
      'rejected'    => RukuninColors.error,
      _             => Theme.of(context).brightness == Brightness.dark
            ? RukuninColors.darkTextTertiary
            : RukuninColors.lightTextTertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  backgroundColor: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
                  selectedColor: RukuninColors.brandGreen,
                  labelStyle: GoogleFonts.poppins(
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
            child: complaintsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: RukuninColors.brandGreen),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: RukuninColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat data',
                          style: GoogleFonts.poppins(
                              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary)),
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
                        Icon(Icons.report_problem_outlined,
                            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada pengaduan',
                          style: GoogleFonts.poppins(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('d MMM y', 'id').format(complaint.createdAt);

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
          // Top row: title + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
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
                  style: GoogleFonts.poppins(
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
              color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              complaint.categoryLabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Resident name + unit
          Text(
            complaint.residentName ?? '-',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          if (complaint.residentUnit != null) ...[
            const SizedBox(height: 2),
            Text(
              'Unit ${complaint.residentUnit}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
              ),
            ),
          ],
          const SizedBox(height: 6),

          // Date
          Text(
            dateStr,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
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
                  color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
                  child: Icon(Icons.broken_image_outlined,
                      color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
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
                side: BorderSide(color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                textStyle: GoogleFonts.poppins(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Update Status Pengaduan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Status dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status Baru',
              labelStyle: GoogleFonts.poppins(fontSize: 13),
            ),
            items: _statusOptions
                .map((s) => DropdownMenuItem(
                      value: s.$1,
                      child: Text(s.$2,
                          style: GoogleFonts.poppins(fontSize: 14)),
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
              labelStyle: GoogleFonts.poppins(fontSize: 13),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          // Simpan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: RukuninColors.brandGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
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
                style: GoogleFonts.poppins()),
            backgroundColor: RukuninColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
