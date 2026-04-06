import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/tokens.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../notifications/providers/notifications_provider.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RukuninColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    final email = user?.email ?? '-';

    return Scaffold(
      backgroundColor: isDark ? RukuninColors.darkBg : RukuninColors.lightBg,
      appBar: AppBar(
        title: const Text('Profil RW'),
        actions: [
          // Bell icon dengan badge unread count
          Stack(
            children: [
              IconButton(
                onPressed: () => context.push('/admin/notifikasi'),
                icon: const Icon(Icons.notifications_outlined),
              ),
              ref.watch(unreadCountProvider).maybeWhen(
                data: (count) => count > 0
                    ? Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: RukuninColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox(),
                orElse: () => const SizedBox(),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar & Info Akun
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: RukuninColors.brandGreen,
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'Administrator',
                  style: RukuninFonts.pjs(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: RukuninFonts.pjs(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Admin RT / RW',
                    style: RukuninFonts.pjs(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: RukuninColors.brandGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Menu Pengaturan
          Text(
            'Pengaturan',
            style: RukuninFonts.pjs(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            isDark: isDark,
            children: [
              _buildMenuItem(
                context,
                isDark: isDark,
                icon: Icons.people_outline_rounded,
                title: 'Pengaturan RT/RW',
                subtitle: 'Info komunitas & kontak',
                onTap: () => context.go('/admin/pengaturan'),
              ),
              _buildDivider(isDark),
              _buildMenuItem(
                context,
                isDark: isDark,
                icon: Icons.account_balance_outlined,
                title: 'Pengaturan Rekening',
                subtitle: 'Rekening bank & QRIS',
                onTap: () => context.push('/admin/pengaturan-rek'),
              ),
              _buildDivider(isDark),
              _buildMenuItem(
                context,
                isDark: isDark,
                icon: Icons.category_outlined,
                title: 'Jenis Iuran',
                subtitle: 'Kelola kategori iuran warga',
                onTap: () => context.go('/admin/pengaturan-iuran'),
              ),
              _buildDivider(isDark),
              _buildMenuItem(
                context,
                isDark: isDark,
                icon: Icons.money_off_outlined,
                title: 'Pengeluaran',
                subtitle: 'Catat & lihat pengeluaran kas',
                onTap: () => context.go('/admin/pengeluaran'),
              ),
              _buildDivider(isDark),
              _buildMenuItem(
                context,
                isDark: isDark,
                icon: Icons.help_outline_rounded,
                title: 'Pusat Bantuan',
                subtitle: 'Layanan dukungan & FAQ',
                onTap: () => context.push('/bantuan'),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Tombol Logout
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: RukuninColors.error,
                backgroundColor: RukuninColors.error.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'Keluar dari Akun Admin',
                style: RukuninFonts.pjs(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuCard({required bool isDark, required List<Widget> children}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightCardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? null : RukuninShadow.card,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? RukuninColors.darkBorder : RukuninColors.lightBorder,
      indent: 64,
      endIndent: 20,
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final textColor = isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RukuninColors.brandGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: RukuninColors.brandGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: RukuninFonts.pjs(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: RukuninFonts.pjs(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: textColor, size: 16),
          ],
        ),
      ),
    );
  }
}
