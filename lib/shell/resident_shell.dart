import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';

class ResidentShell extends StatelessWidget {
  final Widget child;
  const ResidentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/resident/pengumuman')) {
      currentIndex = 1;
    } else if (location.startsWith('/resident/layanan')) {
      currentIndex = 2;
    } else if (location.startsWith('/resident/marketplace')) {
      currentIndex = 3;
    } else if (location.startsWith('/resident/tagihan')) {
      currentIndex = 4;
    } else if (location.startsWith('/resident/akun')) {
      currentIndex = 5;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go('/resident'),
                ),
                _NavItem(
                  icon: Icons.campaign_rounded,
                  label: 'Info RT',
                  isSelected: currentIndex == 1,
                  onTap: () => context.go('/resident/pengumuman'),
                ),
                _NavItem(
                  icon: Icons.article_outlined,
                  label: 'Layanan',
                  isSelected: currentIndex == 2,
                  onTap: () => context.go('/resident/layanan'),
                ),
                _NavItem(
                  icon: Icons.storefront_rounded,
                  label: 'Pasar',
                  isSelected: currentIndex == 3,
                  onTap: () => context.go('/resident/marketplace'),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Tagihan',
                  isSelected: currentIndex == 4,
                  onTap: () => context.go('/resident/tagihan'),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Akun',
                  isSelected: currentIndex == 5,
                  onTap: () => context.go('/resident/akun'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.grey400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
