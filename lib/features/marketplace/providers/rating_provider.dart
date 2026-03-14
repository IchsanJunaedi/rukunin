import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';

class SellerRating {
  final double averageScore;
  final int totalReviews;

  const SellerRating({
    required this.averageScore,
    required this.totalReviews,
  });
}

/// Mengambil rata-rata rating dari penjual tertentu
final sellerRatingProvider = FutureProvider.family
    .autoDispose<SellerRating?, String>((ref, sellerId) async {
  final client = ref.read(supabaseClientProvider);

  final res = await client
      .from('ratings')
      .select('score')
      .eq('seller_id', sellerId);

  final List items = res as List;
  if (items.isEmpty) return null;

  int totalScore = 0;
  for (var item in items) {
    totalScore += (item['score'] as int);
  }

  return SellerRating(
    averageScore: totalScore / items.length,
    totalReviews: items.length,
  );
});

/// Service untuk submit rating baru ke penjual
final ratingServiceProvider = Provider((ref) {
  return RatingService(ref: ref);
});

class RatingService {
  final Ref ref;
  const RatingService({required this.ref});

  Future<void> submitRating({
    required String listingId,
    required String sellerId,
    required int score,
    String? comment,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final raterId = client.auth.currentUser?.id;
    if (raterId == null) throw Exception('Belum login');
    if (raterId == sellerId) throw Exception('Tidak bisa rate diri sendiri');

    await client.from('ratings').insert({
      'listing_id': listingId,
      'rater_id': raterId,
      'seller_id': sellerId,
      'score': score,
      'comment': comment,
    });

    ref.invalidate(sellerRatingProvider(sellerId));
  }
}
