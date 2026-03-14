import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../providers/announcement_provider.dart';
import '../models/announcement_model.dart';

class AnnouncementsScreen extends ConsumerWidget {
  final bool isAdmin;
  const AnnouncementsScreen({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push('/admin/pengumuman/buat'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: AppColors.onPrimary),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded,
                      color: AppColors.primary, size: 28),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat pengumuman',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.grey600)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(announcementsProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_outlined,
                              size: 72, color: AppColors.grey400),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada pengumuman',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pengumuman dari pengurus RT\nakan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(announcementsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _AnnouncementCard(
                        item: list[i],
                        isAdmin: isAdmin,
                        onDelete: isAdmin
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Hapus Pengumuman?',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                    content: Text('Pengumuman "${list[i].title}" akan dihapus permanen.',
                                        style: GoogleFonts.plusJakartaSans()),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text('Hapus', style: GoogleFonts.plusJakartaSans(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(createAnnouncementProvider).delete(list[i].id);
                                }
                              }
                            : null,
                      ),
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

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel item;
  final bool isAdmin;
  final VoidCallback? onDelete;
  const _AnnouncementCard({required this.item, this.isAdmin = false, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final typeColor = switch (item.type) {
      'urgent' => AppColors.error,
      'penting' => AppColors.warning,
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
          color: Colors.white,
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
                      fontSize: 11, color: AppColors.grey500),
                ),
                if (isAdmin && onDelete != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
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
                  color: AppColors.grey800),
            ),
            const SizedBox(height: 6),
            Text(
              item.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.grey600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: AppColors.grey300,
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
                    color: AppColors.grey800),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('EEEE, dd MMMM yyyy', 'id').format(item.createdAt),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppColors.grey500),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                item.body,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: AppColors.grey800, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
