import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/announcement_model.dart';

/// Mengambil semua pengumuman milik community, diurutkan terbaru dulu
final announcementsProvider = FutureProvider.autoDispose<List<AnnouncementModel>>((ref) async {
  final client = ref.read(supabaseClientProvider);

  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  // Ambil community_id dari profile user
  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();

  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return [];

  final res = await client
      .from('announcements')
      .select()
      .eq('community_id', communityId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => AnnouncementModel.fromMap(e)).toList();
});

/// Provider untuk create pengumuman baru (Admin)
final createAnnouncementProvider = Provider((ref) {
  final client = ref.read(supabaseClientProvider);
  return CreateAnnouncementService(client: client, ref: ref);
});

class CreateAnnouncementService {
  final dynamic client;
  final Ref ref;
  const CreateAnnouncementService({required this.client, required this.ref});

  Future<void> create({
    required String communityId,
    required String title,
    required String body,
    required String type,
  }) async {
    await client.from('announcements').insert({
      'community_id': communityId,
      'title': title,
      'body': body,
      'type': type,
      'created_by': client.auth.currentUser?.id,
    });
    ref.invalidate(announcementsProvider);
  }

  Future<void> delete(String id) async {
    await client.from('announcements').delete().eq('id', id);
    ref.invalidate(announcementsProvider);
  }

  /// Broadcast teks pengumuman ke semua warga via WhatsApp (best-effort)
  Future<Map<String, int>> broadcastWa({
    required String communityId,
    required String title,
    required String body,
    required String type,
  }) async {
    int success = 0;
    int fail = 0;

    // Ambil nama komunitas untuk pesan WA
    final commData = await client
        .from('communities')
        .select('name')
        .eq('id', communityId)
        .maybeSingle();
    final rwName = commData?['name'] ?? 'Pengurus RW';

    final typeLabel = type == 'urgent'
        ? '🚨 URGENT'
        : type == 'penting'
            ? '⚠️ PENTING'
            : '📢 INFO';

    final message = '$typeLabel\n*$title*\n\n$body\n\n— $rwName';

    // Ambil semua nomor HP warga aktif di community ini
    final residents = await client
        .from('profiles')
        .select('phone')
        .eq('community_id', communityId)
        .eq('role', 'resident');

    final session = client.auth.currentSession;

    for (final resident in (residents as List)) {
      final phone = resident['phone']?.toString();
      if (phone == null || phone.isEmpty) {
        fail++;
        continue;
      }
      try {
        final res = await client.functions.invoke(
          'send-whatsapp',
          headers: session?.accessToken != null
              ? {'Authorization': 'Bearer ${session!.accessToken}'}
              : null,
          body: {'target': phone, 'message': message},
        );
        final isSuccess = res.data != null && res.data['success'] == true;
        if (isSuccess) {
          success++;
        } else {
          fail++;
        }
      } catch (_) {
        fail++;
      }
    }

    return {'success': success, 'fail': fail};
  }
}
