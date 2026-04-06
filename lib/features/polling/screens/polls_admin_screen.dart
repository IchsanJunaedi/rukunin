import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/tokens.dart';
import '../providers/poll_provider.dart';
import '../models/poll_model.dart';

class PollsAdminScreen extends ConsumerWidget {
  const PollsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pollsAsync = ref.watch(pollsAdminProvider);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Polling',
          style: RukuninFonts.pjs(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/polling/buat'),
        backgroundColor: RukuninColors.brandGreen,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: pollsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: RukuninColors.brandGreen)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: RukuninColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Gagal memuat polling', style: RukuninFonts.pjs(
                  color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
              TextButton(
                onPressed: () => ref.invalidate(pollsAdminProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (polls) {
          if (polls.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_vote_outlined,
                      size: 72,
                      color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                  const SizedBox(height: 16),
                  Text('Belum ada polling',
                      style: RukuninFonts.pjs(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
                  const SizedBox(height: 6),
                  Text('Buat polling untuk musyawarah warga.',
                      style: RukuninFonts.pjs(
                          fontSize: 13,
                          color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
                ],
              ),
            );
          }

          final active = polls.where((p) => p.isOpen).toList();
          final done = polls.where((p) => p.isClosed).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pollsAdminProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionLabel(label: 'Aktif', isDark: isDark),
                  const SizedBox(height: 8),
                  ...active.map((p) => _PollCard(poll: p, isDark: isDark)),
                  const SizedBox(height: 20),
                ],
                if (done.isNotEmpty) ...[
                  _SectionLabel(label: 'Selesai', isDark: isDark),
                  const SizedBox(height: 8),
                  ...done.map((p) => _PollCard(poll: p, isDark: isDark)),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: RukuninFonts.pjs(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final PollModel poll;
  final bool isDark;
  const _PollCard({required this.poll, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = poll.isOpen ? RukuninColors.brandGreen : RukuninColors.lightTextTertiary;
    final statusLabel = poll.isOpen ? 'Aktif' : 'Selesai';

    return GestureDetector(
      onTap: () => context.push('/admin/polling/${poll.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightCardSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? null : RukuninShadow.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poll.title,
                    style: RukuninFonts.pjs(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Berakhir ${DateFormat('dd MMM yyyy', 'id').format(poll.endsAt)}',
                    style: RukuninFonts.pjs(
                      fontSize: 12,
                      color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: RukuninFonts.pjs(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
          ],
        ),
      ),
    );
  }
}
