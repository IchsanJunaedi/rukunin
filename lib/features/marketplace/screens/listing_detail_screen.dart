import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';
import '../../../app/tokens.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratingAsync = ref.watch(sellerRatingProvider(listing.sellerId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isSeller = currentUserId == listing.sellerId;

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
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
                Navigator.of(context).pop();
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
                    onWhatsApp: () => _openWhatsApp(context, listing.sellerPhone!, listing.title),
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

  Future<void> _openWhatsApp(BuildContext context, String phone, String title) async {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int score = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
          title: Text(
            'Beri Ulasan Penjual',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sudah beli barang ini?\nBeri rating untuk ${listing.sellerName ?? 'penjual'}!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    iconSize: 36,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      index < score ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < score ? RukuninColors.warning : (isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
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
                  hintStyle: GoogleFonts.poppins(fontSize: 13),
                  filled: true,
                  fillColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
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
                  style: GoogleFonts.poppins(
                      color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
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
                        backgroundColor: RukuninColors.success));
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RukuninColors.brandGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        title: Text('Hapus Iklan?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Iklan "${listing.title}" akan dihapus secara permanen.',
          style: GoogleFonts.poppins(fontSize: 14, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final rootNav = Navigator.of(context);
              try {
                await ref.read(marketplaceServiceProvider).deleteListing(listing.id);
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
              backgroundColor: RukuninColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmSold(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        title: Text('Tandai Iklan Terjual?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Iklan "${listing.title}" akan ditandai sebagai terjual dan tidak akan muncul lagi di halaman Marketplace. Aksi ini tidak dapat dibatalkan.',
          style: GoogleFonts.poppins(fontSize: 14, color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final rootNav = Navigator.of(context);
              try {
                await ref.read(marketplaceServiceProvider).markAsSold(listing.id);
                nav.pop();
                rootNav.pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Iklan berhasil ditandai terjual! ✅'),
                        backgroundColor: RukuninColors.success),
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
              backgroundColor: RukuninColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tandai Terjual'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// IMAGE HERO APP BAR
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? RukuninColors.darkSurface
          : RukuninColors.lightSurface,
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
                    Icon(Icons.edit_rounded, size: 18, color: Theme.of(context).brightness == Brightness.dark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
                    const SizedBox(width: 10),
                    Text('Edit Iklan', style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sold',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 18, color: RukuninColors.success),
                    const SizedBox(width: 10),
                    Text('Tandai Terjual',
                        style: GoogleFonts.poppins(fontSize: 14, color: RukuninColors.success)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, size: 18, color: RukuninColors.error),
                    const SizedBox(width: 10),
                    Text('Hapus Iklan',
                        style: GoogleFonts.poppins(fontSize: 14, color: RukuninColors.error)),
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
                                  ? RukuninColors.brandGreen
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
      child: Icon(Icons.image_outlined, size: 80, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
    );
  }
}

// ============================================================
// LISTING HEADER
// ============================================================
class _ListingHeader extends StatelessWidget {
  final MarketplaceListingModel listing;
  const _ListingHeader({required this.listing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.formattedPrice,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: RukuninColors.brandGreen,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          listing.title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                listing.categoryLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RukuninColors.brandGreen,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: listing.isAvailable
                    ? RukuninColors.success.withValues(alpha: 0.1)
                    : RukuninColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                listing.isAvailable ? 'Stok: ${listing.stock}' : 'Habis',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: listing.isAvailable ? RukuninColors.success : RukuninColors.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// METADATA ROW
// ============================================================
class _MetadataRow extends StatelessWidget {
  final MarketplaceListingModel listing;
  const _MetadataRow({required this.listing});

  @override
  Widget build(BuildContext context) {
    final imageCount = listing.images.length;
    final days = DateTime.now().difference(listing.createdAt).inDays;
    final dateLabel = days == 0 ? 'Hari ini' : days == 1 ? 'Kemarin' : '$days hari lalu';

    return Row(
      children: [
        _StatusChip(status: listing.status),
        const SizedBox(width: 8),
        _MetaChip(icon: Icons.access_time_rounded, label: dateLabel),
        const SizedBox(width: 8),
        if (imageCount > 0) _MetaChip(icon: Icons.photo_library_outlined, label: '$imageCount Foto'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
          )),
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
    final isAvailable = status == 'active';
    final bgColor = isAvailable
        ? RukuninColors.success.withValues(alpha: 0.1)
        : RukuninColors.error.withValues(alpha: 0.1);
    final textColor = isAvailable ? RukuninColors.success : RukuninColors.error;
    final icon = isAvailable ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;
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
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }
}

// ============================================================
// SELLER CARD
// ============================================================
class _SellerCard extends StatelessWidget {
  final MarketplaceListingModel listing;
  final AsyncValue<SellerRating?> ratingAsync;
  const _SellerCard({required this.listing, required this.ratingAsync});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: RukuninColors.brandGreen.withValues(alpha: 0.15),
            backgroundImage: listing.sellerPhotoUrl != null && listing.sellerPhotoUrl!.isNotEmpty
                ? NetworkImage(listing.sellerPhotoUrl!)
                : null,
            child: (listing.sellerPhotoUrl == null || listing.sellerPhotoUrl!.isEmpty)
                ? Text(
                    listing.sellerName?.isNotEmpty == true
                        ? listing.sellerName![0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      color: RukuninColors.brandGreen,
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
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Unit ${listing.sellerUnit ?? '-'}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
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
// RATING BADGE
// ============================================================
class _RatingBadge extends StatelessWidget {
  final AsyncValue<SellerRating?> ratingAsync;
  const _RatingBadge({required this.ratingAsync});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ratingAsync.when(
      loading: () => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder)),
      error: (_, _) => const SizedBox.shrink(),
      data: (val) {
        if (val == null) {
          return Row(
            children: [
              Icon(Icons.star_rounded, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder, size: 16),
              const SizedBox(width: 4),
              Text('Baru',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary)),
            ],
          );
        }
        return Row(
          children: [
            const Icon(Icons.star_rounded, color: RukuninColors.warning, size: 16),
            const SizedBox(width: 4),
            Text(
              val.averageScore.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary),
            ),
            Text(
              ' (${val.totalReviews})',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACTION BUTTONS
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        if (listing.isAvailable)
        ElevatedButton.icon(
          onPressed: listing.sellerPhone != null ? onWhatsApp : null,
          icon: const Icon(Icons.chat_rounded),
          label: Text(
            'Hubungi via WhatsApp',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (listing.isAvailable) const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRate,
          icon: const Icon(Icons.star_outline_rounded, size: 18),
          label: Text(
            'Beri Ulasan Penjual',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
            side: BorderSide(color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
