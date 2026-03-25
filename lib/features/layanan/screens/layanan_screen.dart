import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/tokens.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/community_contact_model.dart';
import '../models/letter_request_model.dart';
import '../models/complaint_model.dart';
import '../providers/layanan_provider.dart';

// ── Admin phone provider ──────────────────────────────────────
final _adminPhoneProvider = FutureProvider.autoDispose<String?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;
  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();
  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return null;
  final community = await client
      .from('communities')
      .select('admin_phone')
      .eq('id', communityId)
      .maybeSingle();
  return community?['admin_phone'] as String?;
});

// ── Helper ────────────────────────────────────────────────────
Color _statusColor(String status) => switch (status) {
  'pending'                     => RukuninColors.warning,
  'verified' || 'completed' || 'resolved' => RukuninColors.success,
  'rejected'                    => RukuninColors.error,
  _                             => RukuninColors.darkTextTertiary,
};

Future<void> _launchWhatsApp(String phone) async {
  final uri = Uri.parse('https://wa.me/$phone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ── Main Screen ───────────────────────────────────────────────
class LayananScreen extends ConsumerStatefulWidget {
  const LayananScreen({super.key});

  @override
  ConsumerState<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends ConsumerState<LayananScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: const Text('Layanan & Pengaduan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
          indicatorColor: RukuninColors.brandGreen,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Surat'),
            Tab(text: 'Pengaduan'),
            Tab(text: 'Kontak'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SuratTab(),
          _PengaduanTab(),
          _KontakTab(),
        ],
      ),
    );
  }
}

// ── Tab Surat ─────────────────────────────────────────────────
class _SuratTab extends ConsumerWidget {
  const _SuratTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestsAsync = ref.watch(myLetterRequestsProvider);
    final adminPhoneAsync = ref.watch(_adminPhoneProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myLetterRequestsProvider),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section: Permohonan Aktif
          Text(
            'Permohonan Aktif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          requestsAsync.when(
            data: (requests) {
              final active = requests.where((r) => r.isActive).toList();
              if (active.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Belum ada permohonan aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: active
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RequestCard(
                            request: e.value,
                            index: e.key,
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'Error: $e',
              style: GoogleFonts.plusJakartaSans(color: RukuninColors.error),
            ),
          ),

          const SizedBox(height: 28),

          // Section: Buat Permohonan Baru
          Text(
            'Buat Permohonan Baru',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const _NewRequestGrid(),

          const SizedBox(height: 24),

          // Banner: Butuh bantuan?
          adminPhoneAsync.when(
            data: (phone) => _HelpBanner(phone: phone),
            loading: () => const _HelpBanner(phone: null),
            error: (e, _) => const _HelpBanner(phone: null),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Tab Pengaduan ─────────────────────────────────────────────
class _PengaduanTab extends ConsumerWidget {
  const _PengaduanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final complaintsAsync = ref.watch(myComplaintsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myComplaintsProvider),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RukuninColors.brandGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 0,
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () =>
                context.push('/resident/layanan/pengaduan-baru'),
            child: const Text('Buat Pengaduan Baru'),
          ),
          const SizedBox(height: 24),
          complaintsAsync.when(
            data: (complaints) {
              if (complaints.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada pengaduan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: complaints
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ComplaintCard(complaint: c),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'Error: $e',
              style: GoogleFonts.plusJakartaSans(color: RukuninColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _RequestCard ──────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final LetterRequestModel request;
  final int index;

  const _RequestCard({required this.request, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final number = 'SRT-${(index + 1).toString().padLeft(3, '0')}';
    final dateStr =
        DateFormat('d MMM y', 'id').format(request.createdAt);
    final color = _statusColor(request.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.typeLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: request.progressPercent,
              backgroundColor: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _ComplaintCard ────────────────────────────────────────────
class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;

  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr =
        DateFormat('d MMM y', 'id').format(complaint.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: complaint.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  complaint.categoryLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RukuninColors.darkTextSecondary : RukuninColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── _StatusBadge ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  String get _label => switch (status) {
    'pending'   => 'Menunggu',
    'verified'  => 'Surat Siap',
    'completed' => 'Selesai',
    'rejected'  => 'Ditolak',
    'resolved'  => 'Selesai',
    _           => status,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── _NewRequestGrid ───────────────────────────────────────────
class _NewRequestGrid extends StatelessWidget {
  const _NewRequestGrid();

  static const _items = [
    (
      icon: Icons.home_work_outlined,
      label: 'Domisili',
      type: 'domisili',
    ),
    (
      icon: Icons.badge_outlined,
      label: 'KTP / KK',
      type: 'ktp_kk',
    ),
    (
      icon: Icons.local_police_outlined,
      label: 'Pengantar',
      type: 'skck',
    ),
    (
      icon: Icons.description_outlined,
      label: 'Lainnya',
      type: 'custom',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: _items
          .map((item) => _GridItem(
                icon: item.icon,
                label: item.label,
                type: item.type,
              ))
          .toList(),
    );
  }
}

class _GridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String type;

  const _GridItem({
    required this.icon,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () =>
          context.push('/resident/layanan/permohonan?type=$type'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: RukuninColors.brandGreen, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Kontak ────────────────────────────────────────────────
class _KontakTab extends ConsumerWidget {
  const _KontakTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactsAsync = ref.watch(communityContactsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(communityContactsProvider),
      child: contactsAsync.when(
        data: (contacts) => contacts.isEmpty
            ? _buildEmpty(isDark)
            : _buildList(contacts, isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: GoogleFonts.plusJakartaSans(color: RukuninColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder),
              const SizedBox(height: 12),
              Text(
                'Belum ada informasi kontak',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<CommunityContactModel> contacts, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hubungi pengurus komunitas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...contacts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _KontakCard(contact: c),
            )),
      ],
    );
  }
}

// ── Kartu kontak untuk resident ───────────────────────────────
class _KontakCard extends StatelessWidget {
  final CommunityContactModel contact;

  const _KontakCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(isDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.jabatan,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 0,
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => _launchWhatsApp(contact.phone),
            icon: const Icon(Icons.chat_outlined, size: 14),
            label: const Text('Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    if (contact.photoUrl != null) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2,
        backgroundImage: CachedNetworkImageProvider(contact.photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: RukuninColors.brandGreen.withValues(alpha: 0.15),
      child: Text(
        contact.initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: RukuninColors.brandGreen,
        ),
      ),
    );
  }
}

// ── _HelpBanner ───────────────────────────────────────────────
class _HelpBanner extends StatelessWidget {
  final String? phone;

  const _HelpBanner({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: RukuninColors.brandGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Butuh bantuan?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hubungi admin via WhatsApp',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: RukuninColors.brandGreen,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 0,
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: phone != null ? () => _launchWhatsApp(phone!) : null,
            child: const Text('Chat Admin'),
          ),
        ],
      ),
    );
  }
}
