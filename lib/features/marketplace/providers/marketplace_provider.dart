import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/marketplace_listing_model.dart';

/// Filter kategori marketplace
class MarketplaceCategoryFilter extends Notifier<String> {
  @override
  String build() => 'semua';

  void setCategory(String category) {
    state = category;
  }
}

final marketplaceCategoryFilterProvider =
    NotifierProvider<MarketplaceCategoryFilter, String>(
        MarketplaceCategoryFilter.new);

/// Fetch semua listing aktif di community
final marketplaceListingsProvider = FutureProvider.autoDispose<List<MarketplaceListingModel>>((ref) async {
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

  // Hanya tampilkan listing yang dibuat dalam 7 hari terakhir
  final since = DateTime.now().subtract(const Duration(days: 7)).toUtc().toIso8601String();

  final res = await client
      .from('marketplace_listings')
      .select('*, profiles(full_name, phone, unit_number, photo_url)')
      .eq('community_id', communityId)
      .eq('status', 'active')
      .gte('created_at', since)
      .order('created_at', ascending: false);

  return (res as List).map((e) => MarketplaceListingModel.fromMap(e)).toList();
});

/// Fetch listing milik seller tertentu
final myListingsProvider = FutureProvider.autoDispose<List<MarketplaceListingModel>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await client
      .from('marketplace_listings')
      .select('*, profiles(full_name, phone, unit_number, photo_url)')
      .eq('seller_id', userId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => MarketplaceListingModel.fromMap(e)).toList();
});

/// Service untuk create / update / delete listing
final marketplaceServiceProvider = Provider((ref) {
  return MarketplaceService(ref: ref);
});

class MarketplaceService {
  final Ref ref;
  const MarketplaceService({required this.ref});

  Future<void> createListing({
    required String communityId,
    required String sellerId,
    required String title,
    required String category,
    String? description,
    int? price,
    required List<String> imageUrls,
    int stock = 1,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('marketplace_listings').insert({
      'community_id': communityId,
      'seller_id': sellerId,
      'title': title,
      'category': category,
      'description': description,
      'price': price ?? 0,
      'images': imageUrls,
      'status': 'active',
      'stock': stock,
    });
    ref.invalidate(marketplaceListingsProvider);
    ref.invalidate(myListingsProvider);
  }

  Future<void> editListing({
    required String listingId,
    required String title,
    required String category,
    String? description,
    int? price,
    List<String>? imageUrls,
    int? stock,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('marketplace_listings').update({
      'title': title,
      'category': category,
      'description': description,
      'price': price ?? 0,
      if (imageUrls != null) 'images': imageUrls,
      if (stock != null) 'stock': stock,
      if (stock != null && stock <= 0) 'status': 'sold',
    }).eq('id', listingId);
    ref.invalidate(marketplaceListingsProvider);
    ref.invalidate(myListingsProvider);
  }

  Future<void> markAsSold(String listingId) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('marketplace_listings')
        .update({'status': 'sold', 'stock': 0})
        .eq('id', listingId);
    ref.invalidate(marketplaceListingsProvider);
    ref.invalidate(myListingsProvider);
  }

  Future<void> deleteListing(String listingId) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('marketplace_listings')
        .delete()
        .eq('id', listingId);
    ref.invalidate(marketplaceListingsProvider);
    ref.invalidate(myListingsProvider);
  }
}
