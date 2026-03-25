import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../../../app/tokens.dart';
import '../../../core/utils/letter_pdf_generator.dart';
import '../../../core/supabase/supabase_client.dart';
import '../providers/letter_provider.dart';

class ResidentLettersScreen extends ConsumerWidget {
  const ResidentLettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lettersAsync = ref.watch(myLettersProvider);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: Text('Dokumen Saya', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myLettersProvider),
          ),
        ],
      ),
      body: lettersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: RukuninColors.brandGreen)),
        error: (e, _) => Center(child: Text('Gagal memuat dokumen: $e', style: GoogleFonts.plusJakartaSans())),
        data: (letters) {
          if (letters.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.folder_open_outlined, size: 56, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                const SizedBox(height: 12),
                Text('Belum ada dokumen', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
                const SizedBox(height: 4),
                Text('Dokumen yang sudah diverifikasi admin akan muncul di sini', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
              ]),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: letters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _LetterCard(letter: letters[i]),
          );
        },
      ),
    );
  }
}

class _LetterCard extends StatefulWidget {
  final LetterModel letter;
  const _LetterCard({required this.letter});

  @override
  State<_LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<_LetterCard> {
  bool _generatingPdf = false;

  Future<void> _downloadPdf() async {
    if (widget.letter.generatedContent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konten surat tidak tersedia'), backgroundColor: RukuninColors.error),
      );
      return;
    }

    setState(() => _generatingPdf = true);
    try {
      // Ambil data komunitas untuk PDF header
      final client = ProviderScope.containerOf(context).read(supabaseClientProvider);
      final profile = await client.from('profiles').select('community_id').eq('id', client.auth.currentUser!.id).single();
      final community = await client.from('communities').select('name, rt_number, rw_number, kelurahan, kecamatan, kabupaten, province, leader_name').eq('id', profile['community_id']).single();

      final bytes = await LetterPdfGenerator.generate(
        letterNumber: widget.letter.letterNumber,
        letterType: widget.letter.letterType,
        generatedContent: widget.letter.generatedContent!,
        resident: {'full_name': '-', 'nik': '-', 'gender': '-', 'date_of_birth': '', 'place_of_birth': '', 'religion': '-', 'marital_status': '-', 'occupation': '-', 'age': '-'},
        community: {
          'name': community['name'] ?? '',
          'rt_number': community['rt_number']?.toString() ?? '01',
          'rw_number': community['rw_number']?.toString() ?? '01',
          'village': community['kelurahan'] ?? '',
          'district': community['kecamatan'] ?? '',
          'city': community['kabupaten'] ?? '',
          'province': community['province'] ?? '',
          'leader_name': community['leader_name'] ?? 'Ketua RW',
        },
      );

      final safeName = (letterTypeLabels[widget.letter.letterType] ?? 'Surat').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      await FileSaver.instance.saveFile(name: 'Surat_$safeName.pdf', bytes: bytes, mimeType: MimeType.pdf);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF berhasil disimpan!'), backgroundColor: RukuninColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: RukuninColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final letter = widget.letter;
    final dateStr = DateFormat('d MMM y', 'id').format(letter.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(letterTypeLabels[letter.letterType] ?? letter.letterType, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('No. ${letter.letterNumber}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
        const SizedBox(height: 4),
        Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generatingPdf ? null : _downloadPdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: RukuninColors.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _generatingPdf
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.download, size: 18),
            label: Text(_generatingPdf ? 'Membuat PDF...' : 'Unduh PDF', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
