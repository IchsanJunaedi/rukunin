import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/supabase/supabase_client.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  int _motorcycleCount = 0;
  int _carCount = 0;
  bool _loadingVehicle = true;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loadingVehicle = false);
      return;
    }
    final profile = await client
        .from('profiles')
        .select('motorcycle_count, car_count')
        .eq('id', userId)
        .maybeSingle();
    if (mounted) {
      setState(() {
        _motorcycleCount = (profile?['motorcycle_count'] as int?) ?? 0;
        _carCount = (profile?['car_count'] as int?) ?? 0;
        _loadingVehicle = false;
      });
    }
  }

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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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

  Future<void> _saveVehicle(int motorcycle, int car) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('profiles').update({
        'motorcycle_count': motorcycle,
        'car_count': car,
      }).eq('id', userId);
      setState(() {
        _motorcycleCount = motorcycle;
        _carCount = car;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data kendaraan berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showEditVehicleSheet(BuildContext context) async {
    int motorcycle = _motorcycleCount;
    int car = _carCount;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Kendaraan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: 24),
              _vehicleStepper(
                icon: Icons.two_wheeler_rounded,
                label: 'Motor',
                value: motorcycle,
                onDecrement: () =>
                    setModalState(() { if (motorcycle > 0) motorcycle--; }),
                onIncrement: () =>
                    setModalState(() { if (motorcycle < 10) motorcycle++; }),
              ),
              const SizedBox(height: 16),
              _vehicleStepper(
                icon: Icons.directions_car_rounded,
                label: 'Mobil',
                value: car,
                onDecrement: () =>
                    setModalState(() { if (car > 0) car--; }),
                onIncrement: () =>
                    setModalState(() { if (car < 10) car++; }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _saveVehicle(motorcycle, car);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Simpan',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleStepper({
    required IconData icon,
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: AppColors.grey500,
        ),
        Text(
          '$value',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w800),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: AppColors.primary,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    final email = user?.email ?? '-';

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Profil RW'),
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
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'Administrator',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Admin RT / RW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey800,
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            children: [
              _buildMenuItem(
                context,
                icon: Icons.people_rounded,
                iconColor: const Color(0xFF6366F1),
                title: 'Pengaturan RT/RW',
                subtitle: 'Info komunitas & kontak',
                onTap: () => context.go('/admin/pengaturan'),
              ),
              const Divider(height: 1, color: AppColors.grey200, indent: 56),
              _buildMenuItem(
                context,
                icon: Icons.account_balance_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Pengaturan Rekening',
                subtitle: 'Rekening bank & QRIS',
                onTap: () => context.push('/admin/pengaturan-rek'),
              ),
              const Divider(height: 1, color: AppColors.grey200, indent: 56),
              _buildMenuItem(
                context,
                icon: Icons.category_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Jenis Iuran',
                subtitle: 'Kelola kategori iuran warga',
                onTap: () => context.go('/admin/pengaturan-iuran'),
              ),
              const Divider(height: 1, color: AppColors.grey200, indent: 56),
              _buildMenuItem(
                context,
                icon: Icons.money_off_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Pengeluaran',
                subtitle: 'Catat & lihat pengeluaran kas',
                onTap: () => context.go('/admin/pengeluaran'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Kendaraan Terdaftar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kendaraan Terdaftar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
              if (!_loadingVehicle)
                GestureDetector(
                  onTap: () => _showEditVehicleSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: _loadingVehicle
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildProfileItem(
                          Icons.two_wheeler_rounded, 'Motor', '$_motorcycleCount Unit'),
                      const Divider(height: 24, color: AppColors.grey200),
                      _buildProfileItem(
                          Icons.directions_car_rounded, 'Mobil', '$_carCount Unit'),
                    ],
                  ),
          ),

          const SizedBox(height: 48),

          // Tombol Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'Keluar dari Akun Admin',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.grey400, size: 20),
          ],
        ),
      ),
    );
  }
}
