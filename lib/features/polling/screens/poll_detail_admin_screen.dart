import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/tokens.dart';
import '../providers/poll_provider.dart';
import '../providers/poll_vote_provider.dart';
import '../models/poll_model.dart';
import '../models/poll_vote_model.dart';

class PollDetailAdminScreen extends ConsumerWidget {
  final String pollId;
  const PollDetailAdminScreen({super.key, required this.pollId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pollAsync = ref.watch(pollDetailProvider(pollId));
    final votesAsync = ref.watch(pollVotesProvider(pollId));

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
          'Detail Polling',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
      ),
      body: pollAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: RukuninColors.brandGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (poll) {
          if (poll == null) return const Center(child: Text('Polling tidak ditemukan'));
          return votesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: RukuninColors.brandGreen)),
            error: (e, _) => Center(child: Text('Error memuat votes: $e')),
            data: (votes) => _PollDetailBody(
              poll: poll,
              votes: votes,
              isDark: isDark,
              onClose: () => _closePoll(context, ref, poll),
            ),
          );
        },
      ),
    );
  }

  Future<void> _closePoll(BuildContext context, WidgetRef ref, PollModel poll) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tutup Polling?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Polling "${poll.title}" akan ditutup dan warga tidak bisa lagi memberikan suara.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Tutup Polling',
                style: GoogleFonts.poppins(color: RukuninColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(pollNotifierProvider.notifier).closePoll(poll.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Polling berhasil ditutup')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menutup polling: $e')),
        );
      }
    }
  }
}

class _PollDetailBody extends StatelessWidget {
  final PollModel poll;
  final List<PollVoteModel> votes;
  final bool isDark;
  final VoidCallback onClose;

  const _PollDetailBody({
    required this.poll,
    required this.votes,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'id');
    final yesCount = poll.yesCount(votes);
    final noCount = poll.noCount(votes);
    final total = poll.totalVotes(votes);
    final yesPct = poll.yesPercent(votes);
    final noPct = poll.noPercent(votes);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: (poll.isOpen ? RukuninColors.brandGreen : RukuninColors.lightTextTertiary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                poll.isOpen ? 'Polling Aktif' : 'Polling Selesai',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: poll.isOpen ? RukuninColors.brandGreen : RukuninColors.lightTextTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          poll.title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
        if (poll.description != null && poll.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            poll.description!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
              height: 1.6,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${fmt.format(poll.startsAt)} – ${fmt.format(poll.endsAt)}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 20),
        Text(
          'Hasil Suara',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$total suara masuk',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: 16),
        _VoteBar(label: 'Ya', count: yesCount, percent: yesPct, color: RukuninColors.brandGreen, isDark: isDark),
        const SizedBox(height: 10),
        _VoteBar(label: 'Tidak', count: noCount, percent: noPct, color: RukuninColors.error, isDark: isDark),
        const SizedBox(height: 28),
        if (votes.isNotEmpty) ...[
          Text(
            'Rincian Suara',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...votes.map((v) => _VoterTile(vote: v, isDark: isDark)),
        ],
        if (poll.isOpen) ...[
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: RukuninColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: Text(
                'Tutup Polling',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: RukuninColors.error,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

class _VoteBar extends StatelessWidget {
  final String label;
  final int count;
  final double percent;
  final Color color;
  final bool isDark;

  const _VoteBar({required this.label, required this.count, required this.percent, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary)),
            Text('$count suara (${(percent * 100).toInt()}%)',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _VoterTile extends StatelessWidget {
  final PollVoteModel vote;
  final bool isDark;
  const _VoterTile({required this.vote, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM, HH:mm', 'id');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              vote.residentName ?? 'Warga',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (vote.vote ? RukuninColors.brandGreen : RukuninColors.error)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              vote.vote ? 'Ya' : 'Tidak',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: vote.vote ? RukuninColors.brandGreen : RukuninColors.error,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            fmt.format(vote.votedAt),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
