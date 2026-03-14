import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../models/marketplace_listing_model.dart';
import '../providers/marketplace_provider.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(marketplaceListingsProvider);
    final selectedCategory = ref.watch(marketplaceCategoryFilterProvider);

    const categories = [
      ('semua', 'Semua', Icons.apps_rounded),
      ('makanan', 'Makanan', Icons.lunch_dining_rounded),
      ('jasa', 'Jasa', Icons.build_rounded),
      ('barang', 'Barang', Icons.inventory_2_rounded),
      ('tanaman', 'Tanaman', Icons.eco_rounded),
    ];

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Marketplace Warga',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded,
                        color: AppColors.primary, size: 28),
                    tooltip: 'Jual Barang',
                    onPressed: () =>
                        context.push('/resident/marketplace/tambah'),
                  ),
                ],
              ),
            ),
            // Category filter chips
            Container(
              color: AppColors.surface,
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: categories.map((cat) {
                    final (val, label, icon) = cat;
                    final isSelected = selectedCategory == val;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(marketplaceCategoryFilterProvider.notifier)
                            .setCategory(val),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(icon,
                                  size: 14,
                                  color: isSelected
                                      ? AppColors.onPrimary
                                      : Colors.white.withValues(alpha: 0.7)),
                              const SizedBox(width: 5),
                              Text(
                                label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.onPrimary
                                      : Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Listings grid
            Expanded(
              child: listingsAsync.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat listing',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.grey600)),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(marketplaceListingsProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
                data: (all) {
                  final filtered = selectedCategory == 'semua'
                      ? all
                      : all
                          .where((l) => l.category == selectedCategory)
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_outlined,
                              size: 72, color: AppColors.grey400),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada yang jualan nih!',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Jadilah yang pertama jualan di sini 🎉',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(marketplaceListingsProvider),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _ListingCard(item: filtered[i]),
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

class _ListingCard extends StatelessWidget {
  final MarketplaceListingModel item;
  const _ListingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/resident/marketplace/detail', extra: item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: item.images.isNotEmpty
                    ? Image.network(
                        item.images.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _PlaceholderImage(),
                      )
                    : _PlaceholderImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.formattedPrice,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unit ${item.sellerUnit ?? '-'}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey200,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: AppColors.grey400),
      ),
    );
  }
}
