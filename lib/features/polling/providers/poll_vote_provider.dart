import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/poll_vote_model.dart';

/// Semua votes untuk satu poll (admin view)
final pollVotesProvider =
    FutureProvider.autoDispose.family<List<PollVoteModel>, String>((ref, pollId) async {
  final client = ref.read(supabaseClientProvider);

  final res = await client
      .from('poll_votes')
      .select('*, profiles(full_name)')
      .eq('poll_id', pollId)
      .order('voted_at', ascending: false);

  return (res as List).map((e) => PollVoteModel.fromMap(e)).toList();
});

/// Vote milik user yang sedang login untuk poll tertentu (null = belum vote)
final myVoteProvider =
    FutureProvider.autoDispose.family<PollVoteModel?, String>((ref, pollId) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  final res = await client
      .from('poll_votes')
      .select()
      .eq('poll_id', pollId)
      .eq('resident_id', userId)
      .maybeSingle();

  return res == null ? null : PollVoteModel.fromMap(res);
});

/// Mutations: vote pada sebuah poll
class VoteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> vote(String pollId, bool voteValue) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('Tidak terautentikasi');

    await client.from('poll_votes').insert({
      'poll_id': pollId,
      'resident_id': userId,
      'vote': voteValue,
    });

    ref.invalidate(myVoteProvider(pollId));
    ref.invalidate(pollVotesProvider(pollId));
  }
}

final voteNotifierProvider =
    AsyncNotifierProvider<VoteNotifier, void>(VoteNotifier.new);
