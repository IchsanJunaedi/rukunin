import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/notification_model.dart';

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);

  return (data as List).map((e) => NotificationModel.fromMap(e)).toList();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return 0;

  final data = await client
      .from('notifications')
      .select('id')
      .eq('user_id', userId)
      .eq('is_read', false);

  return (data as List).length;
});

// Helper function untuk insert notifikasi (dipakai di berbagai provider)
Future<void> insertNotification({
  required dynamic client, // SupabaseClient
  required String communityId,
  required String userId,
  required String type,
  required String title,
  String? body,
  Map<String, dynamic>? metadata,
}) async {
  try {
    await client.from('notifications').insert({
      'community_id': communityId,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': ?body,
      'metadata': ?metadata,
    });
  } catch (_) {
    // Notifikasi gagal tidak boleh break flow utama
  }
}
