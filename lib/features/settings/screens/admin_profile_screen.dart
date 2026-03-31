import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
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
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Admin RT / RW',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
                icon: Icons.people_rounded,
                iconColor: const Color(0xFF6366F1),
                title: 'Pengaturan RT/RW',
                subtitle: 'Info komunitas & kontak',
                onTap: () => context.go('/admin/pengaturan'),
              ),
              Divider(height: 1, color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2, indent: 56),
              _buildMenuItem(
                context,
                isDark: isDark,
                icon: Icons.account_balance_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Pengaturan Rekening',
                subtitle: 'Rekening bank & QRIS',
                onTap: () => context.push('/admin/pengaturan-rek'),
              ),
              Divider(height: 1, color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2, indent: 56),
              _buildMenuItem(
                context,
                isDark: isDark,
                icon: Icons.category_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Jenis Iuran',
                subtitle: 'Kelola kategori iuran warga',
                onTap: () => context.go('/admin/pengaturan-iuran'),
              ),
              Divider(height: 1, color: isDark ? RukuninColors.darkSurface2 : RukuninColors.lightSurface2, indent: 56),
              _buildMenuItem(
                context,
                isDark: isDark,
                icon: Icons.money_off_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Pengeluaran',
                subtitle: 'Catat & lihat pengeluaran kas',
                onTap: () => context.go('/admin/pengeluaran'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Pusat Bantuan
          Container(
            decoration: BoxDecoration(
              color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/bantuan'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: RukuninColors.brandGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.help_outline_rounded,
                            color: RukuninColors.brandGreen, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Pusat Bantuan',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Tombol Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: RukuninColors.error,
                side: BorderSide(color: RukuninColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'Keluar dari Akun Admin',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
      decoration: BoxDecoration(
        color: isDark ? RukuninColors.darkSurface : RukuninColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? RukuninColors.darkTextPrimary : RukuninColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? RukuninColors.darkTextTertiary : RukuninColors.lightTextTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
