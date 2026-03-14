import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
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
    final lettersAsync = ref.watch(lettersProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: Text('Surat Keterangan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(lettersProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/surat/buat'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Buat Surat', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: lettersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (letters) {
          if (letters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 80, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada surat dibuat',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.grey600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan tombol "Buat Surat" untuk membuat\nsurat keterangan warga',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.grey500),
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
    final residentName = letter.resident?['full_name'] ?? 'N/A';
    final unitNumber = letter.resident?['unit_number'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/admin/surat/buat', extra: letter),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      residentName,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeLabel,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${letter.letterNumber} • Unit $unitNumber',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yy', 'id_ID').format(letter.createdAt),
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.grey400),
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
