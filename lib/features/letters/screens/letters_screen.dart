import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../app/components.dart';
import '../../../app/tokens.dart';
import '../providers/letter_provider.dart';

class LettersScreen extends ConsumerWidget {
  const LettersScreen({super.key});

  String _getLetterTypeLabel(String type) {
    return letterTypeLabels[type] ?? type;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'printed': return Colors.green;
      case 'shared': return Colors.blue;
      default: return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'printed': return 'Dicetak';
      case 'shared': return 'Dibagikan';
      default: return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lettersAsync = ref.watch(lettersProvider);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: Text('Surat Keterangan', style: RukuninFonts.pjs(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(lettersProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/surat/buat'),
        backgroundColor: RukuninColors.brandGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Buat Surat', style: RukuninFonts.pjs(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: lettersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat daftar surat',
            description: 'Periksa koneksi internet, lalu coba lagi.',
            ctaLabel: 'Coba lagi',
            onCta: () => ref.invalidate(lettersProvider),
          ),
        ),
        data: (letters) {
          if (letters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 80, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada surat dibuat',
                    style: RukuninFonts.pjs(fontSize: 16, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan tombol "Buat Surat" untuk membuat\nsurat keterangan warga',
                    textAlign: TextAlign.center,
                    style: RukuninFonts.pjs(fontSize: 13, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: letters.length,
            itemBuilder: (context, i) {
              final letter = letters[i];
              return _LetterCard(
                letter: letter,
                statusColor: _getStatusColor(letter.status),
                statusLabel: _getStatusLabel(letter.status),
                typeLabel: _getLetterTypeLabel(letter.letterType),
              );
            },
          );
        },
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final LetterModel letter;
  final Color statusColor;
  final String statusLabel;
  final String typeLabel;

  const _LetterCard({
    required this.letter,
    required this.statusColor,
    required this.statusLabel,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final residentName = letter.resident?['full_name'] ?? 'N/A';
    final unitNumber = letter.resident?['unit_number'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/admin/surat/buat', extra: {
          'prefilledResidentId': letter.residentId,
          'prefilledLetterType': letter.letterType,
          'prefilledPurpose': letter.purpose,
        }),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.description, color: RukuninColors.brandGreen, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      residentName,
                      style: RukuninFonts.pjs(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeLabel,
                      style: RukuninFonts.pjs(fontSize: 12, color: RukuninColors.brandGreen, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${letter.letterNumber} • Unit $unitNumber',
                      style: RukuninFonts.pjs(fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text(statusLabel, style: RukuninFonts.pjs(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yy', 'id_ID').format(letter.createdAt),
                    style: RukuninFonts.pjs(fontSize: 10, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
