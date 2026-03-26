import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../providers/announcement_provider.dart';
import '../models/announcement_model.dart';
import '../../polling/providers/poll_provider.dart';
import '../../polling/models/poll_model.dart';

class AnnouncementsScreen extends ConsumerWidget {
  final bool isAdmin;
  const AnnouncementsScreen({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final announcementsAsync = ref.watch(announcementsProvider);
    final pollsAsync = isAdmin ? null : ref.watch(pollsActiveProvider);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push('/admin/pengumuman/buat'),
              backgroundColor: RukuninColors.brandGreen,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  Icon(Icons.campaign_rounded,
                      color: RukuninColors.brandGreen, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Pengumuman RT',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: announcementsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: RukuninColors.brandGreen),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: RukuninColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat pengumuman',
                          style: GoogleFonts.plusJakartaSans(
                              color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(announcementsProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  Widget pollSection = const SizedBox.shrink();
                  if (!isAdmin && pollsAsync != null) {
                    pollSection = pollsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                      data: (polls) {
                        if (polls.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.how_to_vote_rounded,
                                      size: 16, color: RukuninColors.brandGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    'POLLING AKTIF',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: RukuninColors.brandGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...polls.map((p) => _ActivePollCard(poll: p, isDark: isDark)),
                              const SizedBox(height: 8),
                              const Divider(),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  if (list.isEmpty) {
                    return Column(
                      children: [
                        pollSection,
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.campaign_outlined,
                                    size: 72, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada pengumuman',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pengumuman dari pengurus RT\nakan muncul di sini.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(announcementsProvider);
                      if (!isAdmin) ref.invalidate(pollsActiveProvider);
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: list.length + 1,
                      separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == 0) return pollSection;
                        final item = list[i - 1];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: i == 1 ? 16 : 0,
                            bottom: i == list.length ? 16 : 0,
                          ),
                          child: _AnnouncementCard(
                            item: item,
                            isAdmin: isAdmin,
                            onDelete: isAdmin
                                ? () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Hapus Pengumuman?',
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                        content: Text('Pengumuman "${item.title}" akan dihapus permanen.',
                                            style: GoogleFonts.plusJakartaSans()),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text('Hapus', style: GoogleFonts.plusJakartaSans(color: RukuninColors.error)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(createAnnouncementProvider).delete(item.id);
                                    }
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePollCard extends StatelessWidget {
  final PollModel poll;
  final bool isDark;
  const _ActivePollCard({required this.poll, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/resident/polling/${poll.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              RukuninColors.brandGreen.withValues(alpha: 0.08),
              RukuninColors.brandTeal.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RukuninColors.brandGreen.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.how_to_vote_rounded,
                  color: RukuninColors.brandGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poll.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Berakhir ${DateFormat('dd MMM yyyy', 'id').format(poll.endsAt)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Vote →',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: RukuninColors.brandGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel item;
  final bool isAdmin;
  final VoidCallback? onDelete;
  const _AnnouncementCard({required this.item, this.isAdmin = false, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = switch (item.type) {
      'urgent' => RukuninColors.error,
      'penting' => RukuninColors.warning,
      _ => const Color(0xFF3B82F6),
    };
    final typeLabel = switch (item.type) {
      'urgent' => 'URGENT',
      'penting' => 'PENTING',
      _ => 'INFO',
    };
    final typeIcon = switch (item.type) {
      'urgent' => Icons.warning_rounded,
      'penting' => Icons.priority_high_rounded,
      _ => Icons.info_rounded,
    };

    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: typeColor, width: 4)),
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
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 12, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy', 'id').format(item.createdAt),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                ),
                if (isAdmin && onDelete != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline_rounded,
                        size: 18, color: RukuninColors.error),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              item.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('EEEE, dd MMMM yyyy', 'id').format(item.createdAt),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                item.body,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
