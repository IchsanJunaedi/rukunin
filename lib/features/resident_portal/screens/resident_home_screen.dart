import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/tokens.dart';
import '../../../app/components.dart';
import '../providers/resident_invoices_provider.dart';

class ResidentHomeScreen extends ConsumerWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentResidentProfileProvider);
    final totalPending = ref.watch(residentTotalPendingInvoicesProvider);
    final invoicesAsync = ref.watch(residentInvoicesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      RukuninColors.brandGreen.withValues(alpha: 0.08),
                      RukuninColors.brandGreen.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 300,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      RukuninColors.brandTeal.withValues(alpha: 0.06),
                      RukuninColors.brandTeal.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
          RefreshIndicator(
            color: RukuninColors.brandGreen,
            onRefresh: () async {
              ref.invalidate(currentResidentProfileProvider);
              ref.invalidate(residentInvoicesProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ResidentHeader(profileAsync: profileAsync),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TagihanHeroCard(totalPending: totalPending),
                      const SizedBox(height: 14),
                      _KasBanner(onTap: () => context.push('/resident/kas')),
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'Tagihan Terkini',
                        actionLabel: 'Lihat semua',
                        onAction: () => context.push('/resident/tagihan'),
                      ),
                      const SizedBox(height: 12),
                      invoicesAsync.when(
                        loading: () => Column(
                          children: List.generate(
                              2, (_) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InvoiceCardSkeleton(),
                              )),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 16, color: RukuninColors.error),
                              const SizedBox(width: 8),
                              Text(
                                'Gagal memuat tagihan',
                                style: RukuninFonts.pjs(
                                    fontSize: 13, color: RukuninColors.error),
                              ),
                            ],
                          ),
                        ),
                        data: (invoices) {
                          if (invoices.isEmpty) {
                            return const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'Belum ada tagihan',
                              description:
                                  'Tagihan dari pengurus akan muncul di sini.',
                            );
                          }
                          return Column(
                            children: invoices.take(3).map((inv) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _InvoiceItem(inv: inv),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentHeader extends StatelessWidget {
  final AsyncValue profileAsync;
  const _ResidentHeader({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RukuninColors.brandGradient,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 28,
      ),
      child: profileAsync.when(
        loading: () => Row(
          children: [
            ShimmerBox(width: 46, height: 46, borderRadius: 100),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerBox.line(width: 80),
              const SizedBox(height: 6),
              ShimmerBox.line(width: 140),
            ]),
          ],
        ),
        error: (e, _) => const SizedBox(),
        data: (profile) => Row(
          children: [
            GradientAvatar(
              initials: profile?.initials ?? '?',
              imageUrl: profile?.photoUrl,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${profile?.fullName?.split(' ').first ?? 'Warga'} 👋',
                    style: RukuninFonts.pjs(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    profile?.alamatLengkap ?? '',
                    style: RukuninFonts.pjs(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
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

class _TagihanHeroCard extends StatelessWidget {
  final double totalPending;
  const _TagihanHeroCard({required this.totalPending});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lunas = totalPending == 0;
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SISA TAGIHAN',
                style: RukuninFonts.pjs(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? RukuninColors.darkTextTertiary
                      : RukuninColors.lightTextTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              StatusBadge(
                lunas ? 'Lunas' : 'Perlu Dibayar',
                status: lunas ? BadgeStatus.success : BadgeStatus.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(totalPending),
            style: RukuninFonts.pjs(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              height: 1.0,
              color: lunas
                  ? RukuninColors.success
                  : (isDark
                      ? RukuninColors.darkTextPrimary
                      : RukuninColors.lightTextPrimary),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: lunas
                  ? RukuninColors.success.withValues(alpha: 0.08)
                  : RukuninColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  lunas
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: lunas
                      ? RukuninColors.success
                      : RukuninColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lunas
                        ? 'Semua tagihan bulan ini lunas ✨'
                        : 'Harap segera dilunasi sebelum jatuh tempo',
                    style: RukuninFonts.pjs(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: lunas
                          ? RukuninColors.success
                          : RukuninColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KasBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _KasBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bannerContent = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                RukuninColors.brandGreen.withValues(alpha: 0.15),
                RukuninColors.brandTeal.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_outlined,
              color: RukuninColors.brandGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transparansi Kas Lingkungan',
                style: RukuninFonts.pjs(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? RukuninColors.darkTextPrimary
                      : RukuninColors.lightTextPrimary,
                ),
              ),
              Text(
                'Lihat pemasukan & pengeluaran RW',
                style: RukuninFonts.pjs(
                  fontSize: 12,
                  color: isDark
                      ? RukuninColors.darkTextSecondary
                      : RukuninColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isDark
              ? RukuninColors.darkTextTertiary
              : RukuninColors.lightTextTertiary,
        ),
      ],
    );

    if (isDark) {
      return GlassCard(
        onTap: onTap,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: bannerContent,
      );
    }

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: bannerContent,
    );
  }
}

class _InvoiceItem extends StatelessWidget {
  final dynamic inv;
  const _InvoiceItem({required this.inv});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final monthName =
        DateFormat('MMMM yyyy', 'id_ID').format(DateTime(inv.year, inv.month));

    final (statusLabel, statusBadge, accentColor) = switch (inv.status) {
      'paid' => ('Lunas', BadgeStatus.success, RukuninColors.success),
      'awaiting_verification' =>
        ('Verifikasi', BadgeStatus.info, RukuninColors.info),
      'overdue' => ('Terlambat', BadgeStatus.error, RukuninColors.error),
      _ => ('Belum Bayar', BadgeStatus.warning, RukuninColors.warning),
    };

    return SurfaceCard(
      accentColor: accentColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.billingTypeName,
                  style: RukuninFonts.pjs(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? RukuninColors.darkTextPrimary
                        : RukuninColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Periode $monthName',
                  style: RukuninFonts.pjs(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? RukuninColors.darkTextSecondary
                        : RukuninColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                StatusBadge(statusLabel, status: statusBadge, small: true),
              ],
            ),
          ),
          Text(
            fmt.format(inv.amount),
            style: RukuninFonts.pjs(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? RukuninColors.darkTextPrimary
                  : RukuninColors.lightTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
