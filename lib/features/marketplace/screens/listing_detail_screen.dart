import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';
import '../models/marketplace_listing_model.dart';
import '../providers/marketplace_provider.dart';
import '../providers/rating_provider.dart';
import 'add_listing_screen.dart';

// ============================================================
// MAIN SCREEN
// ============================================================
class ListingDetailScreen extends ConsumerWidget {
  final MarketplaceListingModel listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(sellerRatingProvider(listing.sellerId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isSeller = currentUserId == listing.sellerId;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: CustomScrollView(
        slivers: [
          _ImageHeroAppBar(
            listing: listing,
            isSeller: isSeller,
            onEdit: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddListingScreen(existingListing: listing),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.of(context).pop(); // tutup detail, biar provider refresh
              }
            },
            onDelete: () => _confirmDelete(context, ref),
            onSold: () => _confirmSold(context, ref),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ListingHeader(listing: listing),
                  const SizedBox(height: 24),
                  _MetadataRow(listing: listing),
                  const SizedBox(height: 20),
                  _SellerCard(listing: listing, ratingAsync: ratingAsync),
                  const SizedBox(height: 24),
                  if (listing.description?.isNotEmpty == true) ...[
                    _DescriptionSection(description: listing.description!),
                    const SizedBox(height: 28),
                  ],
                  _ActionButtons(
                    listing: listing,
                    onWhatsApp: () => _openWhatsApp(
                        context, listing.sellerPhone!, listing.title),
                    onRate: () => _showRatingDialog(context, ref),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(
      BuildContext context, String phone, String title) async {
    String formatted = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (formatted.startsWith('0')) {
      formatted = '62${formatted.substring(1)}';
    } else if (!formatted.startsWith('62')) {
      formatted = '62$formatted';
    }
    final msg = Uri.encodeComponent(
        'Halo, saya tertarik dengan "$title" yang kamu jual di Rukunin. Masih tersedia?');
    final url = Uri.parse('https://wa.me/$formatted?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref) {
    int score = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Beri Ulasan Penjual',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sudah beli barang ini?\nBeri rating untuk ${listing.sellerName ?? 'penjual'}!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: AppColors.grey600),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    iconSize: 36,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      index < score
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: index < score
                          ? AppColors.primary
                          : AppColors.grey300,
                    ),
                    onPressed: () => setState(() => score = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Tulis komentar (opsional)...',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.grey600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(ctx);
                try {
                  await ref.read(ratingServiceProvider).submitRating(
                        listingId: listing.id,
                        sellerId: listing.sellerId,
                        score: score,
                        comment: commentCtrl.text.trim(),
                      );
                  nav.pop();
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Ulasan berhasil dikirim! ⭐'),
                        backgroundColor: AppColors.success));
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Iklan?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Iklan "${listing.title}" akan dihapus secara permanen.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.grey600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.plusJakartaSans(color: AppColors.grey600)),
          ),
          ElevatedButton(
            onPressed: () async {
              // We need marketplaceServiceProvider here, so I actually NEED that import.
              // Wait, I am removing it above! Let's NOT remove it and instead USE it here.
              // Let me re-add the import since I need it for this method!
              // For safety in this chunk, I'll just keep the method logic.
              final nav = Navigator.of(ctx);
              final rootNav = Navigator.of(context);
              try {
                // IMPORTANT: since I removed the import above as "unused", I must rely on 
                // something else, OR I should add the import back! Wait, the lint said 
                // it was unused because _confirmDelete wasn't in the file yet! 
                // Now it WILL be used. I should fix the previous chunk to NOT remove it.
                // But the previous chunk is already submitted. I'll just re-add it in THIS chunk.
                // Actually, let's just use ref.read(marketplaceServiceProvider) assuming I didn't remove it or I'll fix it if it complains.
                
                await ref
                    .read(marketplaceServiceProvider)
                    .deleteListing(listing.id);
                nav.pop();
                rootNav.pop();
              } catch (e) {
                nav.pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal hapus: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmSold(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tandai Iklan Terjual?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Iklan "${listing.title}" akan ditandai sebagai terjual dan tidak akan muncul lagi di halaman Marketplace. Aksi ini tidak dapat dibatalkan.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.grey600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.plusJakartaSans(color: AppColors.grey600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final rootNav = Navigator.of(context);
              try {
                await ref
                    .read(marketplaceServiceProvider)
                    .markAsSold(listing.id);
                nav.pop();
                rootNav.pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Iklan berhasil ditandai terjual! ✅'),
                        backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                nav.pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tandai Terjual'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// IMAGE HERO APP BAR — with dot indicator
// ============================================================
class _ImageHeroAppBar extends StatefulWidget {
  final MarketplaceListingModel listing;
  final bool isSeller;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSold;

  const _ImageHeroAppBar({
    required this.listing,
    required this.isSeller,
    required this.onEdit,
    required this.onDelete,
    required this.onSold,
  });

  @override
  State<_ImageHeroAppBar> createState() => _ImageHeroAppBarState();
}

class _ImageHeroAppBarState extends State<_ImageHeroAppBar> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.listing.images;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.surface,
      foregroundColor: Colors.white,
      actions: [
        if (widget.isSeller)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'edit') widget.onEdit();
              if (value == 'sold') widget.onSold();
              if (value == 'delete') widget.onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded,
                        size: 18, color: AppColors.grey800),
                    const SizedBox(width: 10),
                    Text('Edit Iklan',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sold',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: 10),
                    Text('Tandai Terjual',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: AppColors.success)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text('Hapus Iklan',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: images.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _EmptyImagePlaceholder(),
                    ),
                  ),
                  // Dot indicator (only shown if multiple images)
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _currentPage ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : _EmptyImagePlaceholder(),
      ),
    );
  }
}

class _EmptyImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.grey200,
        child: const Icon(Icons.image_outlined, size: 80, color: AppColors.grey400),
      );
}

// ============================================================
// LISTING HEADER — Price, Title, Category Badge
// ============================================================
class _ListingHeader extends StatelessWidget {
  final MarketplaceListingModel listing;
  const _ListingHeader({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.formattedPrice,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          listing.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            listing.categoryLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// METADATA ROW — Date posted + image count
// ============================================================
class _MetadataRow extends StatelessWidget {
  final MarketplaceListingModel listing;
  const _MetadataRow({required this.listing});

  @override
  Widget build(BuildContext context) {
    final imageCount = listing.images.length;
    final days = DateTime.now().difference(listing.createdAt).inDays;
    final dateLabel = days == 0
        ? 'Hari ini'
        : days == 1
            ? 'Kemarin'
            : '$days hari lalu';

    return Row(
      children: [
        _StatusChip(status: listing.status),
        const SizedBox(width: 8),
        _MetaChip(
          icon: Icons.access_time_rounded,
          label: dateLabel,
        ),
        const SizedBox(width: 8),
        if (imageCount > 0)
          _MetaChip(
            icon: Icons.photo_library_outlined,
            label: '$imageCount Foto',
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.grey500),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'available';
    final bgColor = isAvailable
        ? AppColors.success.withValues(alpha: 0.1)
        : AppColors.error.withValues(alpha: 0.1);
    final textColor = isAvailable ? AppColors.success : AppColors.error;
    final icon =
        isAvailable ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;
    final label = isAvailable ? 'Tersedia' : 'Terjual';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SELLER CARD — Avatar, name, unit, rating badge
// ============================================================
class _SellerCard extends StatelessWidget {
  final MarketplaceListingModel listing;
  final AsyncValue<SellerRating?> ratingAsync;
  const _SellerCard({required this.listing, required this.ratingAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar dengan initial atau photo_url
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: listing.sellerPhotoUrl != null && listing.sellerPhotoUrl!.isNotEmpty
                ? NetworkImage(listing.sellerPhotoUrl!)
                : null,
            child: (listing.sellerPhotoUrl == null || listing.sellerPhotoUrl!.isEmpty)
                ? Text(
                    listing.sellerName?.isNotEmpty == true
                        ? listing.sellerName![0].toUpperCase()
                        : '?',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.sellerName ?? 'Warga',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.grey800,
                  ),
                ),
                Text(
                  'Unit ${listing.sellerUnit ?? '-'}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          _RatingBadge(ratingAsync: ratingAsync),
        ],
      ),
    );
  }
}

// ============================================================
// RATING BADGE — Inline star rating display
// ============================================================
class _RatingBadge extends StatelessWidget {
  final AsyncValue<SellerRating?> ratingAsync;
  const _RatingBadge({required this.ratingAsync});

  @override
  Widget build(BuildContext context) {
    return ratingAsync.when(
      loading: () => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.grey400)),
      error: (_, _) => const SizedBox.shrink(),
      data: (val) {
        if (val == null) {
          return Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.grey300, size: 16),
              const SizedBox(width: 4),
              Text('Baru',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey500)),
            ],
          );
        }
        return Row(
          children: [
            const Icon(Icons.star_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Text(
              val.averageScore.toStringAsFixed(1),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800),
            ),
            Text(
              ' (${val.totalReviews})',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColors.grey500),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// DESCRIPTION SECTION
// ============================================================
class _DescriptionSection extends StatelessWidget {
  final String description;
  const _DescriptionSection({required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.grey600,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACTION BUTTONS — WhatsApp + Rating
// ============================================================
class _ActionButtons extends StatelessWidget {
  final MarketplaceListingModel listing;
  final VoidCallback? onWhatsApp;
  final VoidCallback onRate;

  const _ActionButtons({
    required this.listing,
    required this.onWhatsApp,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: listing.sellerPhone != null ? onWhatsApp : null,
          icon: const Icon(Icons.chat_rounded),
          label: Text(
            'Hubungi via WhatsApp',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.grey300,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRate,
          icon: const Icon(Icons.star_outline_rounded, size: 18),
          label: Text(
            'Beri Ulasan Penjual',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.grey600,
            side: const BorderSide(color: AppColors.grey300),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
