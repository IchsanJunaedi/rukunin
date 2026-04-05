import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/tokens.dart';
import '../models/letter_request_model.dart';
import '../providers/layanan_provider.dart';

class VerifyRequestScreen extends ConsumerStatefulWidget {
  final LetterRequestModel request;
  const VerifyRequestScreen({super.key, required this.request});

  @override
  ConsumerState<VerifyRequestScreen> createState() => _VerifyRequestScreenState();
}

class _VerifyRequestScreenState extends ConsumerState<VerifyRequestScreen> {
  final _alasanCtrl = TextEditingController();
  bool _loadingAcc = false;
  bool _loadingTolak = false;

  @override
  void dispose() {
    _alasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _acc() async {
    setState(() => _loadingAcc = true);
    try {
      await ref.read(layananServiceProvider).verifyAndGenerateLetter(request: widget.request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surat berhasil di-generate!'), backgroundColor: RukuninColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: RukuninColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAcc = false);
    }
  }

  Future<void> _tolak() async {
    if (_alasanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan penolakan wajib diisi'), backgroundColor: RukuninColors.error),
      );
      return;
    }
    setState(() => _loadingTolak = true);
    try {
      await ref.read(layananServiceProvider).rejectRequest(
        requestId: widget.request.id,
        residentId: widget.request.residentId,
        communityId: widget.request.communityId,
        alasan: _alasanCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permohonan ditolak.'), backgroundColor: RukuninColors.warning),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: RukuninColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTolak = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final request = widget.request;
    final fd = request.formData ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Permohonan', style: RukuninFonts.pjs(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info warga
            _card(
              isDark: isDark,
              title: 'Data Warga',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row('Nama', request.residentName ?? request.applicantName ?? '-'),
                if (request.residentUnit != null) _row('Unit', request.residentUnit!),
                _row('Jenis Surat', request.typeLabel),
                _row('Diajukan', _formatDate(request.createdAt)),
              ]),
            ),
            const SizedBox(height: 12),

            // Data form yang diisi warga
            _card(
              isDark: isDark,
              title: 'Data yang Diisi Warga',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fd.isEmpty
                    ? [Text('Tidak ada data form.', style: RukuninFonts.pjs(fontSize: 13))]
                    : fd.entries.map((e) => _row(_labelFor(e.key), e.value.toString())).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol ACC
            ElevatedButton.icon(
              onPressed: _loadingAcc || _loadingTolak ? null : _acc,
              style: ElevatedButton.styleFrom(
                backgroundColor: RukuninColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _loadingAcc
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_loadingAcc ? 'Memproses...' : 'ACC & Generate Surat', style: RukuninFonts.pjs(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),

            Divider(color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
            const SizedBox(height: 16),

            Text('Tolak Permohonan', style: RukuninFonts.pjs(fontSize: 14, fontWeight: FontWeight.w700, color: RukuninColors.error)),
            const SizedBox(height: 8),
            TextField(
              controller: _alasanCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadingAcc || _loadingTolak ? null : _tolak,
              style: OutlinedButton.styleFrom(
                foregroundColor: RukuninColors.error,
                side: const BorderSide(color: RukuninColors.error),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loadingTolak
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: RukuninColors.error, strokeWidth: 2))
                  : Text('Tolak Permohonan', style: RukuninFonts.pjs(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _card({required bool isDark, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: RukuninFonts.pjs(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 140, child: Text(label, style: RukuninFonts.pjs(fontSize: 12, color: RukuninColors.darkTextTertiary))),
      Expanded(child: Text(value.isEmpty ? '-' : value, style: RukuninFonts.pjs(fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  String _labelFor(String key) => const {
    'nik': 'NIK', 'ttl': 'TTL', 'gender': 'Jenis Kelamin', 'agama': 'Agama',
    'keperluan': 'Keperluan', 'alasan': 'Alasan', 'keterangan': 'Keterangan',
    'no_kk': 'No KK', 'pernyataan_kondisi': 'Kondisi Ekonomi', 'marital_status': 'Status Nikah',
    'pekerjaan': 'Pekerjaan', 'nama_usaha': 'Nama Usaha', 'jenis_usaha': 'Jenis Usaha',
    'alamat_usaha': 'Alamat Usaha', 'nama_ayah': 'Nama Ayah', 'nama_ibu': 'Nama Ibu',
    'nama_almarhum': 'Nama Almarhum', 'nik_almarhum': 'NIK Almarhum', 'ttl_almarhum': 'TTL Almarhum',
    'tanggal_meninggal': 'Tgl Meninggal', 'penyebab': 'Penyebab', 'hubungan_pelapor': 'Hubungan Pelapor',
  }[key] ?? key;
}
