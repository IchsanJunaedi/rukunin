import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../core/supabase/supabase_client.dart';

// ─────────────────────────────────────────
//  WARNA LOKAL (tidak konflik dengan AppColors)
// ─────────────────────────────────────────
class _C {
  static const Color dark       = AppColors.surface;       // #0D0D0D
  static const Color bg         = AppColors.grey100;       // #F4F4F4
  static const Color yellow1    = Color(0xFFFFF9C4);
  static const Color yellow2    = AppColors.primary;       // #FFC107
  static const Color yellow3    = Color(0xFFFF8F00);
  static const Color statGreen  = Color(0xFF22C55E);
  static const Color statRed    = Color(0xFFEF4444);
  static const Color statBlue   = Color(0xFF3B82F6);
  static const Color textMuted  = AppColors.grey500;
  static const Color iconInactive = AppColors.grey400;
}

// ─────────────────────────────────────────
//  PROVIDER (tidak diubah)
// ─────────────────────────────────────────
final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return {};

  final profile = await client
      .from('profiles')
      .select('community_id, full_name, communities(name, rw_number, community_code)')
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

  final sudahBayar        = invoices.where((i) => i['status'] == 'paid').length;
  final menungguVerifikasi = invoices.where((i) => i['status'] == 'awaiting_verification').length;
  final belumBayar        = invoices.where((i) => i['status'] == 'pending' || i['status'] == 'overdue').length;
  final totalTagihan      = invoices.fold(0.0, (sum, i) => sum + (i['amount'] as num).toDouble());
  final totalTerkumpul    = invoices
      .where((i) => i['status'] == 'paid')
      .fold(0.0, (sum, i) => sum + (i['amount'] as num).toDouble());

  return {
    'admin_name'          : profile['full_name'] ?? 'Admin',
    'rw_name'             : (profile['communities'] as Map?)?['name'] ?? 'RT/RW',
    'community_code'      : (profile['communities'] as Map?)?['community_code'] ?? '',
    'total_unit'          : invoices.length,
    'sudah_bayar'         : sudahBayar,
    'menunggu_verifikasi' : menungguVerifikasi,
    'belum_bayar'         : belumBayar,
    'total_tagihan'       : totalTagihan,
    'total_terkumpul'     : totalTerkumpul,
  };
});

// ─────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: data.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _C.yellow2),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: _C.statRed, size: 48),
                const SizedBox(height: 12),
                Text('Gagal memuat data', style: GoogleFonts.plusJakartaSans(color: _C.dark)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (d) => CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────
            SliverToBoxAdapter(child: _Header(d: d)),

            // ── Konten ──────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Kas summary
                  _KasSummaryCard(
                    terkumpul: (d['total_terkumpul'] as num?)?.toDouble() ?? 0,
                    tagihan:   (d['total_tagihan']   as num?)?.toDouble() ?? 0,
                  ),
                  const SizedBox(height: 14),

                  // Kode komunitas
                  _CommunityCodeCard(code: d['community_code']?.toString() ?? '-'),
                  const SizedBox(height: 14),

                  // Statistik 2×2
                  _StatGrid(
                    totalUnit:   d['total_unit']           as int? ?? 0,
                    sudahBayar:  d['sudah_bayar']          as int? ?? 0,
                    belumBayar:  d['belum_bayar']          as int? ?? 0,
                    tungguVerif: d['menunggu_verifikasi']  as int? ?? 0,
                  ),
                  const SizedBox(height: 20),

                  // Aksi cepat
                  const _AksiCepat(),

                  // Spacer bawah untuk navbar
                  const SizedBox(height: 110),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  HEADER
// ════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final Map<String, dynamic> d;
  const _Header({required this.d});

  @override
  Widget build(BuildContext context) {
    final firstName = (d['admin_name']?.toString() ?? 'Admin').split(' ').first;
    final initial   = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A';

    return Container(
      color: _C.dark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: greeting + avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hei, $firstName 👋',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/admin/profil'),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [_C.yellow1, _C.yellow3],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _C.dark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        firstName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // RW name
          RichText(
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: '${d['rw_name'] ?? 'Dashboard'} '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_C.yellow1, _C.yellow2],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ADMIN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _C.dark,
                        letterSpacing: 0.8,
                      ),
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

// ════════════════════════════════════════════════════════
//  KAS SUMMARY CARD (yellow gradient)
// ════════════════════════════════════════════════════════
class _KasSummaryCard extends StatelessWidget {
  final double terkumpul;
  final double tagihan;
  const _KasSummaryCard({required this.terkumpul, required this.tagihan});

  String _fmt(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    final s = v.toInt().toString();
    final buf = StringBuffer('Rp ');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pct = tagihan > 0 ? (terkumpul / tagihan).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.yellow1, _C.yellow2, _C.yellow3],
        ),
        boxShadow: [
          BoxShadow(
            color: _C.yellow2.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40, right: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -25, left: 30,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL TERKUMPUL',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _C.dark.withValues(alpha: 0.45),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _fmt(terkumpul),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: _C.dark,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: _C.dark.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(_C.dark),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(pct * 100).toInt()}% dari target',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _C.dark.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _fmt(tagihan),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _C.dark.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  COMMUNITY CODE CARD
// ════════════════════════════════════════════════════════
class _CommunityCodeCard extends StatelessWidget {
  final String code;
  const _CommunityCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.dark,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          top: BorderSide(color: _C.yellow1.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _C.yellow1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.yellow1.withValues(alpha: 0.18)),
            ),
            child: const Icon(Icons.key_rounded, color: _C.yellow1, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KODE KOMUNITAS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.35),
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _C.yellow1,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Bagikan ke warga agar bisa bergabung',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kode $code disalin!',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  backgroundColor: _C.yellow2,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.yellow1, _C.yellow2]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Salin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.dark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  STAT GRID 2×2
// ════════════════════════════════════════════════════════
class _StatGrid extends StatelessWidget {
  final int totalUnit, sudahBayar, belumBayar, tungguVerif;
  const _StatGrid({
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
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          number: totalUnit.toString(),
          label: 'Total Unit',
          icon: Icons.home_rounded,
          accentColor: _C.yellow2,
          iconBg: const Color(0xFFFFF8DC),
          iconColor: _C.yellow3,
        ),
        _StatCard(
          number: sudahBayar.toString(),
          label: 'Sudah Bayar',
          icon: Icons.check_circle_rounded,
          accentColor: _C.statGreen,
          iconBg: const Color(0xFFE9F9EE),
          iconColor: _C.statGreen,
        ),
        _StatCard(
          number: belumBayar.toString(),
          label: 'Belum Bayar',
          icon: Icons.warning_rounded,
          accentColor: _C.statRed,
          iconBg: const Color(0xFFFFEDEC),
          iconColor: _C.statRed,
        ),
        _StatCard(
          number: tungguVerif.toString(),
          label: 'Tunggu Verif',
          icon: Icons.access_time_rounded,
          accentColor: _C.statBlue,
          iconBg: const Color(0xFFE5F4FD),
          iconColor: _C.statBlue,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final Color accentColor, iconBg, iconColor;

  const _StatCard({
    required this.number,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Accent bar top
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.5)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: iconColor, size: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    number,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _C.dark,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _C.textMuted,
                      fontWeight: FontWeight.w500,
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

// ════════════════════════════════════════════════════════
//  AKSI CEPAT
// ════════════════════════════════════════════════════════
class _AksiCepat extends StatelessWidget {
  const _AksiCepat();

  static const _actions = [
    (Icons.person_add_rounded,                'Warga Baru',    '/admin/warga/tambah'),
    (Icons.receipt_long_rounded,              'Buat Tagihan',  '/admin/tagihan/buat'),
    (Icons.account_balance_wallet_rounded,    'Pengeluaran',   '/admin/pengeluaran'),
    (Icons.campaign_rounded,                  'Pengumuman',    '/admin/pengumuman'),
    (Icons.account_balance_rounded,           'Rekening RW',   '/admin/pengaturan-rek'),
    (Icons.settings_rounded,                  'Profil RW',     '/admin/pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _C.dark,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 14,
          childAspectRatio: 0.82,
          children: _actions
              .map((a) => _AksiButton(icon: a.$1, label: a.$2, route: a.$3))
              .toList(),
        ),
      ],
    );
  }
}

class _AksiButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  const _AksiButton({required this.icon, required this.label, required this.route});

  @override
  State<_AksiButton> createState() => _AksiButtonState();
}

class _AksiButtonState extends State<_AksiButton>
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        context.push(widget.route);
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Column(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: _C.dark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: 27,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Center(child: Icon(widget.icon, color: _C.yellow1, size: 22)),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _C.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
