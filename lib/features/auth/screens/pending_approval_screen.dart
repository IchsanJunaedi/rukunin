import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/tokens.dart';
import '../providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Color(0xFFFFC107),
                  size: 48,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Menunggu\nPersetujuan',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Akun kamu sudah terdaftar dan sedang menunggu persetujuan dari admin RT/RW.\n\nSetelah disetujui, kamu bisa login kembali dan menggunakan semua fitur Rukunin.',
                textAlign: TextAlign.center,
                style: RukuninFonts.pjs(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.6,
                ),
              ),

              const Spacer(flex: 3),

              // Cek Status button
              _CheckStatusButton(),

              const SizedBox(height: 12),

              // Sign out
              GestureDetector(
                onTap: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      'Keluar',
                      style: RukuninFonts.pjs(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckStatusButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CheckStatusButton> createState() => _CheckStatusButtonState();
}

class _CheckStatusButtonState extends ConsumerState<_CheckStatusButton> {
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) context.go('/login');
        return;
      }

      final profile = await client
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .maybeSingle();

      final status = profile?['status'] as String?;

      if (!mounted) return;
      if (status == 'active') {
        context.go('/resident');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Akunmu belum disetujui. Hubungi admin RT/RW-mu.',
              style: RukuninFonts.pjs(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal cek status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _checking ? null : _checkStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color: _checking
              ? const Color(0xFFFFC107).withValues(alpha: 0.6)
              : const Color(0xFFFFC107),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: _checking
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF0D0D0D),
                  ),
                )
              : Text(
                  'Cek Status & Masuk →',
                  style: RukuninFonts.pjs(
                    color: const Color(0xFF0D0D0D),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
