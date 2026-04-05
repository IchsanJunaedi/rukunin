import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/tokens.dart';
import '../../../core/supabase/supabase_client.dart';
import 'package:go_router/go_router.dart' as import_go_router;
import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  Future<void> _markRead(WidgetRef ref, String notifId) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('notifications').update({'is_read': true}).eq('id', notifId);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(ref),
            child: Text(
              'Tandai Semua Dibaca',
              style: RukuninFonts.pjs(
                fontSize: 12,
                color: RukuninColors.brandGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: RukuninFonts.pjs(
                      fontSize: 16,
                      color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (ctx, i) => _NotifCard(
              notif: notifs[i],
              onTap: () {
                _markRead(ref, notifs[i].id);
                _navigateFromNotif(context, notifs[i]);
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateFromNotif(BuildContext context, NotificationModel notif) {
    String? path;
    switch (notif.type) {
      case 'payment':
        path = '/resident/tagihan';
        break;
      case 'announcement':
        path = '/resident/pengumuman';
        break;
      case 'letter_request':
      case 'complaint':
        path = '/resident/layanan';
        break;
      case 'join_request':
        path = '/admin/warga';
        break;
      case 'join_approved':
      case 'join_rejected':
        path = '/resident';
        break;
    }
    if (path != null) {
      import_go_router.GoRouter.of(context).go(path);
    }
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeAgo = DateFormat('d MMM, HH:mm', 'id_ID').format(notif.createdAt.toLocal());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead
              ? (isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface)
              : RukuninColors.brandGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? (isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2)
                : RukuninColors.brandGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(notif.icon, size: 20, color: RukuninColors.brandGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: RukuninFonts.pjs(
                      fontSize: 14,
                      fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                    ),
                  ),
                  if (notif.body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notif.body!,
                      style: RukuninFonts.pjs(
                        fontSize: 12,
                        color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    timeAgo,
                    style: RukuninFonts.pjs(
                      fontSize: 11,
                      color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: RukuninColors.brandGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
