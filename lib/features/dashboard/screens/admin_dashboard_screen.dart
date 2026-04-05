import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/tokens.dart';
import '../../../app/components.dart';
import '../../../core/supabase/supabase_client.dart';

// ─── Provider ────────────────────────────────────────────────────────────────
final dashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return {};

  final profile = await client
      .from('profiles')
      .select(
          'community_id, full_name, communities(name, rw_number, community_code)')
      .eq('id', userId)
      .maybeSingle();

  if (profile == null) return {};
  final communityId = profile['community_id'] as String?;
  if (communityId == null) return {};

  final now = DateTime.now();
  final invoices = await client
      .from('invoices')
      .select('status, amount')
      .eq('community_id', communityId)
      .eq('month', now.month)
      .eq('year', now.year);

  final sudahBayar = invoices.where((i) => i['status'] == 'paid').length;
  final menungguVerifikasi =
      invoices.where((i) => i['status'] == 'awaiting_verification').length;
  final belumBayar = invoices
      .where((i) => i['status'] == 'pending' || i['status'] == 'overdue')
      .length;
  final totalTagihan = invoices.fold(
      0.0, (sum, i) => sum + (i['amount'] as num).toDouble());
  final totalTerkumpul = invoices
      .where((i) => i['status'] == 'paid')
      .fold(0.0, (sum, i) => sum + (i['amount'] as num).toDouble());

  return {
    'admin_name': profile['full_name'] ?? 'Admin',
    'rw_name': (profile['communities'] as Map?)?['name'] ?? 'RT/RW',
    'community_code':
        (profile['communities'] as Map?)?['community_code'] ?? '',
    'total_unit': invoices.length,
    'sudah_bayar': sudahBayar,
    'menunggu_verifikasi': menungguVerifikasi,
    'belum_bayar': belumBayar,
    'total_tagihan': totalTagihan,
    'total_terkumpul': totalTerkumpul,
  };
});

// ─────────────────────────────────────────────────────────────────────────────
//  ADMIN DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      body: data.when(
        loading: () => _buildSkeleton(context),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat data',
            description: e.toString(),
            ctaLabel: 'Coba lagi',
            onCta: () => ref.invalidate(dashboardProvider),
          ),
        ),
        data: (d) => _buildContent(context, ref, d),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _SkeletonHeader()),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ShimmerBox(width: double.infinity, height: 140, borderRadius: 20),
              const SizedBox(height: 14),
              ShimmerBox(width: double.infinity, height: 72, borderRadius: 16),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: ShimmerBox(width: double.infinity, height: 90, borderRadius: 16)),
                const SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: double.infinity, height: 90, borderRadius: 16)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ShimmerBox(width: double.infinity, height: 90, borderRadius: 16)),
                const SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: double.infinity, height: 90, borderRadius: 16)),
              ]),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, Map<String, dynamic> d) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _DashboardHeader(d: d)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _KasHeroCard(
                terkumpul: (d['total_terkumpul'] as num?)?.toDouble() ?? 0,
                tagihan: (d['total_tagihan'] as num?)?.toDouble() ?? 0,
              ),
              const SizedBox(height: 14),
              _CommunityCodeTile(code: d['community_code']?.toString() ?? '-'),
              const SizedBox(height: 20),
              SectionHeader(title: 'Tagihan Bulan Ini'),
              const SizedBox(height: 12),
              _StatsGrid(
                totalUnit: d['total_unit'] as int? ?? 0,
                sudahBayar: d['sudah_bayar'] as int? ?? 0,
                belumBayar: d['belum_bayar'] as int? ?? 0,
                tungguVerif: d['menunggu_verifikasi'] as int? ?? 0,
              ),
              const SizedBox(height: 24),
              SectionHeader(title: 'Aksi Cepat'),
              const SizedBox(height: 12),
              _QuickActions(),
              const SizedBox(height: 24),
              SectionHeader(title: 'Layanan Warga'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.task_outlined,
                      label: 'Permohonan\nSurat',
                      onTap: () => context.push('/admin/layanan-requests'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.feedback_outlined,
                      label: 'Pengaduan\nWarga',
                      onTap: () => context.push('/admin/pengaduan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SkeletonHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: RukuninColors.brandGreen,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 80, height: 14, borderRadius: 4),
              ShimmerBox(width: 100, height: 32, borderRadius: 100),
            ],
          ),
          const SizedBox(height: 16),
          ShimmerBox(width: 200, height: 28, borderRadius: 8),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final Map<String, dynamic> d;
  const _DashboardHeader({required this.d});

  @override
  Widget build(BuildContext context) {
    final name = d['admin_name']?.toString() ?? 'Admin';
    final firstName = name.split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A';

    return Container(
      decoration: const BoxDecoration(
        gradient: RukuninColors.brandGradient,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang,',
                    style: RukuninFonts.pjs(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    firstName,
                    style: RukuninFonts.pjs(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/admin/profil'),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: RukuninFonts.pjs(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            d['rw_name']?.toString() ?? 'Dashboard',
            style: RukuninFonts.pjs(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kas Hero Card ─────────────────────────────────────────────────────────────

class _KasHeroCard extends StatelessWidget {
  final double terkumpul;
  final double tagihan;
  const _KasHeroCard({required this.terkumpul, required this.tagihan});

  String _fmt(double v) {
    if (v >= 1000000) {
      return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    }
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(v);
  }

  @override
  Widget build(BuildContext context) {
    final pct = tagihan > 0 ? (terkumpul / tagihan).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
          width: 0.5,
        ),
        boxShadow: RukuninShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL TERKUMPUL',
                style: RukuninFonts.pjs(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? RukuninColors.darkTextTertiary
                      : RukuninColors.lightTextTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: RukuninColors.brandGradient,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${(pct * 100).toInt()}%',
                  style: RukuninFonts.pjs(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                RukuninColors.brandGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              _fmt(terkumpul),
              style: RukuninFonts.pjs(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: isDark
                  ? RukuninColors.darkSurface2
                  : RukuninColors.lightSurface2,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  RukuninColors.brandGreen),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target bulan ini',
                style: RukuninFonts.pjs(
                  fontSize: 12,
                  color: isDark
                      ? RukuninColors.darkTextTertiary
                      : RukuninColors.lightTextTertiary,
                ),
              ),
              Text(
                _fmt(tagihan),
                style: RukuninFonts.pjs(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? RukuninColors.darkTextSecondary
                      : RukuninColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Community Code Tile ───────────────────────────────────────────────────────

class _CommunityCodeTile extends StatelessWidget {
  final String code;
  const _CommunityCodeTile({required this.code});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  RukuninColors.brandGreen.withValues(alpha: 0.15),
                  RukuninColors.brandTeal.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.key_rounded,
                color: RukuninColors.brandGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KODE KOMUNITAS',
                  style: RukuninFonts.pjs(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? RukuninColors.darkTextTertiary
                        : RukuninColors.lightTextTertiary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      RukuninColors.brandGradient.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    code,
                    style: RukuninFonts.pjs(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              HapticFeedback.lightImpact();
              showToast(context, 'Kode $code disalin!');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: RukuninColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Salin',
                style: RukuninFonts.pjs(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int totalUnit, sudahBayar, belumBayar, tungguVerif;
  const _StatsGrid({
    required this.totalUnit,
    required this.sudahBayar,
    required this.belumBayar,
    required this.tungguVerif,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        _DashStatCard(label: 'Total Unit',        value: totalUnit.toString(),    icon: Icons.domain_outlined),
        _DashStatCard(label: 'Sudah Bayar',       value: sudahBayar.toString(),   icon: Icons.verified_outlined),
        _DashStatCard(label: 'Belum Bayar',       value: belumBayar.toString(),   icon: Icons.hourglass_bottom_rounded),
        _DashStatCard(label: 'Perlu Verifikasi',  value: tungguVerif.toString(),  icon: Icons.rate_review_outlined),
      ],
    );
  }
}

class _DashStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DashStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: RukuninColors.brandGreen.withValues(alpha: isDark ? 0.22 : 0.14),
          width: 1.0,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: RukuninColors.brandGreen.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: RukuninColors.brandGreen.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  RukuninColors.brandGreen.withValues(alpha: isDark ? 0.20 : 0.13),
                  RukuninColors.brandTeal.withValues(alpha: isDark ? 0.12 : 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: RukuninColors.brandGreen),
          ),
          const Spacer(),
          ShaderMask(
            shaderCallback: (bounds) =>
                RukuninColors.brandGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              value,
              style: RukuninFonts.pjs(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: RukuninFonts.pjs(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? RukuninColors.darkTextPrimary
                  : RukuninColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  static const _items = [
    (Icons.how_to_reg_outlined,               'Warga Baru',       '/admin/warga/tambah'),
    (Icons.receipt_long_outlined,             'Buat Tagihan',     '/admin/tagihan/buat'),
    (Icons.savings_outlined,                  'Pengeluaran',      '/admin/pengeluaran'),
    (Icons.history_rounded,                   'Riwayat Bayar',    '/admin/riwayat-pembayaran'),
    (Icons.add_alert_outlined,                'Pengumuman',       '/admin/pengumuman'),
    (Icons.poll_outlined,                     'Polling',          '/admin/polling'),
    (Icons.contact_phone_outlined,            'Info Kontak',      '/admin/layanan/kontak'),
    (Icons.account_balance_outlined,          'Rekening',         '/admin/pengaturan-rek'),
    (Icons.tune_outlined,                     'Profil RW',        '/admin/pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 14,
      childAspectRatio: 0.85,
      children: _items
          .map((a) => _ActionBtn(icon: a.$1, label: a.$2, route: a.$3))
          .toList(),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  const _ActionBtn({
    required this.icon, required this.label,
    required this.route,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) { _ctrl.reverse(); HapticFeedback.selectionClick(); },
      onTapUp: (_) { _ctrl.forward(); context.push(widget.route); },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RukuninColors.brandGreen.withValues(alpha: isDark ? 0.18 : 0.12),
                    RukuninColors.brandTeal.withValues(alpha: isDark ? 0.10 : 0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: RukuninColors.brandGreen.withValues(alpha: isDark ? 0.22 : 0.18),
                  width: 1.0,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: RukuninColors.brandGreen.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Icon(
                widget.icon,
                color: RukuninColors.brandGreen,
                size: 24,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: RukuninFonts.pjs(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? RukuninColors.darkTextPrimary
                    : RukuninColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service Card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon, required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  RukuninColors.brandGreen.withValues(alpha: isDark ? 0.18 : 0.12),
                  RukuninColors.brandTeal.withValues(alpha: isDark ? 0.10 : 0.07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: RukuninColors.brandGreen.withValues(alpha: isDark ? 0.22 : 0.18),
                width: 1.0,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: RukuninColors.brandGreen.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Icon(
              icon,
              color: RukuninColors.brandGreen,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: RukuninFonts.pjs(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? RukuninColors.darkTextPrimary
                  : RukuninColors.lightTextPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
