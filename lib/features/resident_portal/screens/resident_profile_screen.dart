import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/supabase/supabase_client.dart';
import 'package:go_router/go_router.dart';
import '../providers/resident_invoices_provider.dart';

class ResidentProfileScreen extends ConsumerStatefulWidget {
  const ResidentProfileScreen({super.key});

  @override
  ConsumerState<ResidentProfileScreen> createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends ConsumerState<ResidentProfileScreen> {
  bool _isUploading = false;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    await client.auth.signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  Future<void> _pickAndUploadPhoto(String currentUserId) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      // Limit 2MB
      if (bytes.length > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ukuran foto maksimal 2MB'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      setState(() => _isUploading = true);
      final client = ref.read(supabaseClientProvider);

      // Pastikan bucket avatars ada (opsional jika sudah ada)
      try {
        await client.storage.createBucket('avatars');
      } catch (_) {}

      final ext = file.name.split('.').last;
      // Beri nama unik agar cache network refresh
      final path = '$currentUserId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(upsert: true, contentType: file.mimeType ?? 'image/jpeg'),
      );

      final publicUrl = client.storage.from('avatars').getPublicUrl(path);
      await client.from('profiles').update({'photo_url': publicUrl}).eq('id', currentUserId);

      ref.invalidate(currentResidentProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui! ✅'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah foto: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentResidentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Akun Saya'),
        actions: [
          IconButton(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Data profil tidak ditemukan'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentResidentProfileProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primary,
                            backgroundImage: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                                ? NetworkImage(profile.photoUrl!)
                                : null,
                            child: _isUploading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : (profile.photoUrl == null || profile.photoUrl!.isEmpty)
                                    ? Text(
                                        profile.initials,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploading ? null : () => _pickAndUploadPhoto(profile.id),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.fullName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: profile.isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile.isActive ? 'Warga Tetap' : 'Belum Registrasi Penuh',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: profile.isActive ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Info Rumah
                Text(
                  'Info Hunian & Kontak',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
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
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.home_work_rounded, 'Alamat', profile.alamatLengkap),
                      const Divider(height: 24, color: AppColors.grey200),
                      _buildProfileItem(Icons.phone_android_rounded, 'No. Handphone', profile.phone ?? '-'),
                      const Divider(height: 24, color: AppColors.grey200),
                      _buildProfileItem(Icons.badge_rounded, 'NIK', profile.nik ?? '-'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Info Kendaraan
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
                    GestureDetector(
                      onTap: () => _showEditVehicleSheet(
                        context,
                        profile.motorcycleCount,
                        profile.carCount,
                        profile.id,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
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
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.directions_car_rounded, 'Mobil', '${profile.carCount} Unit'),
                      const Divider(height: 24, color: AppColors.grey200),
                      _buildProfileItem(Icons.two_wheeler_rounded, 'Motor', '${profile.motorcycleCount} Unit'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Transparansi
                Text(
                  'Transparansi Lingkungan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // TODO: push ke Read-Only Laporan Kas di masa mendatang
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Halaman Laporan Kas sedang dalam penyiapan data...')),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF10B981), size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Laporan Keuangan RT',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.grey800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Lihat ringkasan kas bulan ini',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Pusat Bantuan
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.help_outline_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Pusat Bantuan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey800,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.grey400),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _logout(context, ref),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar dari Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat profil: $e')),
      ),
    );
  }

  Future<void> _showEditVehicleSheet(
    BuildContext context,
    int initialMotorcycle,
    int initialCar,
    String userId,
  ) async {
    int motorcycle = initialMotorcycle;
    int car = initialCar;

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
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
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
                onDecrement: () => setModalState(() { if (motorcycle > 0) motorcycle--; }),
                onIncrement: () => setModalState(() { if (motorcycle < 10) motorcycle++; }),
              ),
              const SizedBox(height: 16),
              _vehicleStepper(
                icon: Icons.directions_car_rounded,
                label: 'Mobil',
                value: car,
                onDecrement: () => setModalState(() { if (car > 0) car--; }),
                onIncrement: () => setModalState(() { if (car < 10) car++; }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _saveVehicle(userId, motorcycle, car);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Simpan',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
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
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: AppColors.grey500,
        ),
        Text(
          '$value',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: AppColors.primary,
        ),
      ],
    );
  }

  Future<void> _saveVehicle(String userId, int motorcycle, int car) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('profiles').update({
        'motorcycle_count': motorcycle,
        'car_count': car,
      }).eq('id', userId);
      ref.invalidate(currentResidentProfileProvider);
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
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
}
