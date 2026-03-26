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

class PollVoteScreen extends ConsumerWidget {
  final String pollId;
  const PollVoteScreen({super.key, required this.pollId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pollAsync = ref.watch(pollDetailProvider(pollId));
    final votesAsync = ref.watch(pollVotesProvider(pollId));
    final myVoteAsync = ref.watch(myVoteProvider(pollId));

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
          style: GoogleFonts.plusJakartaSans(
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
          if (poll == null) {
            return Center(child: Text('Polling tidak ditemukan',
                style: GoogleFonts.plusJakartaSans(
                    color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)));
          }
          return votesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: RukuninColors.brandGreen)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (votes) => myVoteAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: RukuninColors.brandGreen)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (myVote) => _PollVoteBody(
                poll: poll,
                votes: votes,
                myVote: myVote,
                isDark: isDark,
                onVote: (v) => _doVote(context, ref, v),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _doVote(BuildContext context, WidgetRef ref, bool voteValue) async {
    try {
      await ref.read(voteNotifierProvider.notifier).vote(pollId, voteValue);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan suara: $e')),
        );
      }
    }
  }
}

class _PollVoteBody extends ConsumerStatefulWidget {
  final PollModel poll;
  final List<PollVoteModel> votes;
  final PollVoteModel? myVote;
  final bool isDark;
  final Future<void> Function(bool) onVote;

  const _PollVoteBody({
    required this.poll,
    required this.votes,
    required this.myVote,
    required this.isDark,
    required this.onVote,
  });

  @override
  ConsumerState<_PollVoteBody> createState() => _PollVoteBodyState();
}

class _PollVoteBodyState extends ConsumerState<_PollVoteBody> {
  bool _voting = false;

  Future<void> _vote(bool value) async {
    setState(() => _voting = true);
    await widget.onVote(value);
    if (mounted) setState(() => _voting = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'id');
    final poll = widget.poll;
    final votes = widget.votes;
    final myVote = widget.myVote;
    final isDark = widget.isDark;

    final hasVoted = myVote != null;
    final showResults = hasVoted || poll.isClosed;

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
                poll.isClosed ? 'Polling Selesai' : 'Polling Aktif',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: poll.isOpen ? RukuninColors.brandGreen : RukuninColors.lightTextTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          poll.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            height: 1.3,
          ),
        ),
        if (poll.description != null && poll.description!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            poll.description!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
              height: 1.6,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Berakhir ${fmt.format(poll.endsAt)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 24),
        if (showResults) ...[
          Text(
            'Hasil Suara',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total suara',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 16),
          _ResidentVoteBar(
            label: 'Ya',
            count: yesCount,
            percent: yesPct,
            color: RukuninColors.brandGreen,
            isMyVote: myVote?.vote == true,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _ResidentVoteBar(
            label: 'Tidak',
            count: noCount,
            percent: noPct,
            color: RukuninColors.error,
            isMyVote: myVote?.vote == false,
            isDark: isDark,
          ),
          if (hasVoted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: RukuninColors.brandGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Kamu sudah memilih "${myVote.vote ? 'Ya' : 'Tidak'}"',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: RukuninColors.brandGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        if (!hasVoted && poll.isOpen) ...[
          Text(
            'Berikan Suaramu',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _voting ? null : () => _vote(true),
                    icon: const Icon(Icons.thumb_up_rounded, size: 18),
                    label: Text('Ya',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RukuninColors.brandGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _voting ? null : () => _vote(false),
                    icon: const Icon(Icons.thumb_down_rounded, size: 18),
                    label: Text('Tidak',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RukuninColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_voting) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator(color: RukuninColors.brandGreen)),
          ],
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

class _ResidentVoteBar extends StatelessWidget {
  final String label;
  final int count;
  final double percent;
  final Color color;
  final bool isMyVote;
  final bool isDark;

  const _ResidentVoteBar({
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
    required this.isMyVote,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMyVote
            ? color.withValues(alpha: 0.08)
            : (isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMyVote ? color.withValues(alpha: 0.4) : (isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
          width: isMyVote ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(label,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary)),
                  if (isMyVote) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle_rounded, size: 14, color: color),
                  ],
                ],
              ),
              Text('${(percent * 100).toInt()}% ($count)',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
