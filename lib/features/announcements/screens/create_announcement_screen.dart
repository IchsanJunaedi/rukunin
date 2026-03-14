import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import '../providers/announcement_provider.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _type = 'info';
  bool _loading = false;
  bool _sendWa = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Tidak ada sesi login');

      final profile = await client
          .from('profiles')
          .select('community_id')
          .eq('id', userId)
          .maybeSingle();

      final communityId = profile?['community_id'] as String?;
      if (communityId == null) throw Exception('Community ID tidak ditemukan');

      final service = ref.read(createAnnouncementProvider);
      await service.create(
        communityId: communityId,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        type: _type,
      );

      // Broadcast WA jika toggle aktif
      if (_sendWa) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengumuman tersimpan. Mengirim WA...')),
          );
        }
        final result = await service.broadcastWa(
          communityId: communityId,
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          type: _type,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'WA terkirim ke ${result['success']} warga'
                '${(result['fail'] ?? 0) > 0 ? ', gagal: ${result['fail']}' : ''}.',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengumuman berhasil dikirim!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        title: Text(
          'Buat Pengumuman',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(
                'Kirim',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Jenis Pengumuman
            Text(
              'Jenis Pengumuman',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _TypeChip(
                  label: 'Info',
                  icon: Icons.info_rounded,
                  color: const Color(0xFF3B82F6),
                  selected: _type == 'info',
                  onTap: () => setState(() => _type = 'info'),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Penting',
                  icon: Icons.priority_high_rounded,
                  color: AppColors.warning,
                  selected: _type == 'penting',
                  onTap: () => setState(() => _type = 'penting'),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Urgent',
                  icon: Icons.warning_rounded,
                  color: AppColors.error,
                  selected: _type == 'urgent',
                  onTap: () => setState(() => _type = 'urgent'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Judul
            Text(
              'Judul',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'Contoh: Jadwal Kerja Bakti Minggu Ini',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style:
                  GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.grey800),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            // Isi
            Text(
              'Isi Pengumuman',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 8,
              decoration: InputDecoration(
                hintText:
                    'Tulis isi pengumuman secara lengkap di sini...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
                alignLabelWithHint: true,
              ),
              style:
                  GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.grey800),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Isi pengumuman wajib diisi' : null,
            ),
            const SizedBox(height: 20),

            // Toggle WA Blast
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  'Kirim WA ke semua warga',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.grey800,
                  ),
                ),
                subtitle: Text(
                  'Pengumuman akan di-broadcast ke nomor WA seluruh warga',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
                value: _sendWa,
                onChanged: (val) => setState(() => _sendWa = val),
                activeTrackColor: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: const Icon(Icons.send_rounded),
              label: Text(
                'Publikasikan Pengumuman',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.grey300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : AppColors.grey500),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
