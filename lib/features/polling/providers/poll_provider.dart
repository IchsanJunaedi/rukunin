import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/poll_model.dart';

/// Semua polls milik community (untuk admin — semua status)
final pollsAdminProvider = FutureProvider.autoDispose<List<PollModel>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();

  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return [];

  final res = await client
      .from('polls')
      .select()
      .eq('community_id', communityId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => PollModel.fromMap(e)).toList();
});

/// Hanya polls yang sedang aktif (status=open AND ends_at > now) — untuk resident
final pollsActiveProvider = FutureProvider.autoDispose<List<PollModel>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();

  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return [];

  final now = DateTime.now().toIso8601String();

  final res = await client
      .from('polls')
      .select()
      .eq('community_id', communityId)
      .eq('status', 'open')
      .gt('ends_at', now)
      .order('created_at', ascending: false);

  return (res as List).map((e) => PollModel.fromMap(e)).toList();
});

/// Poll detail by id
final pollDetailProvider =
    FutureProvider.autoDispose.family<PollModel?, String>((ref, pollId) async {
  final client = ref.read(supabaseClientProvider);

  final res = await client
      .from('polls')
      .select()
      .eq('id', pollId)
      .maybeSingle();

  return res == null ? null : PollModel.fromMap(res);
});

/// Mutations: create poll, close poll
class PollNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createPoll({
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');

    final profile = await client
        .from('profiles')
        .select('community_id')
        .eq('id', userId)
        .maybeSingle();

    final communityId = profile?['community_id'] as String?;
    if (communityId == null) throw Exception('Community tidak ditemukan');

    await client.from('polls').insert({
      'community_id': communityId,
      'created_by': userId,
      'title': title,
      'description': description,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'status': 'open',
    });

    ref.invalidate(pollsAdminProvider);
    ref.invalidate(pollsActiveProvider);
  }

  Future<void> closePoll(String pollId) async {
    final client = ref.read(supabaseClientProvider);

    await client
        .from('polls')
        .update({'status': 'closed'})
        .eq('id', pollId);

    ref.invalidate(pollsAdminProvider);
    ref.invalidate(pollsActiveProvider);
    ref.invalidate(pollDetailProvider(pollId));
  }
}

final pollNotifierProvider =
    AsyncNotifierProvider<PollNotifier, void>(PollNotifier.new);
