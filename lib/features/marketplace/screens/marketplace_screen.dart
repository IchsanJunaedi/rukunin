import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../app/tokens.dart';
import '../models/marketplace_listing_model.dart';
import '../providers/marketplace_provider.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded,
                      color: RukuninColors.brandGreen, size: 28),
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
                    icon: Icon(Icons.add_rounded,
                        color: RukuninColors.brandGreen, size: 28),
                    tooltip: 'Jual Barang',
                    onPressed: () =>
                        context.push('/resident/marketplace/tambah'),
                  ),
                ],
              ),
            ),
            // Category filter chips
            Container(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
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
                                ? RukuninColors.brandGreen
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(icon,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
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
                                      ? Colors.white
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
                loading: () => Center(
                    child:
                        CircularProgressIndicator(color: RukuninColors.brandGreen)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: RukuninColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Gagal memuat listing',
                          style: GoogleFonts.plusJakartaSans(
                              color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
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
                              size: 72, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada yang jualan nih!',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Jadilah yang pertama jualan di sini 🎉',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/resident/marketplace/detail', extra: item),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
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
                        color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.formattedPrice,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: RukuninColors.brandGreen),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unit ${item.sellerUnit ?? '-'}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
      child: Center(
        child: Icon(Icons.image_outlined, size: 40, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
      ),
    );
  }
}
