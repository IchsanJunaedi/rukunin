import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_admin_screen.dart';
import '../features/auth/screens/register_resident_screen.dart';
import '../features/auth/screens/pending_approval_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/screens/admin_dashboard_screen.dart';
import '../features/residents/screens/residents_screen.dart';
import '../features/residents/screens/resident_detail_screen.dart';
import '../features/residents/screens/add_edit_resident_screen.dart';
import '../features/residents/models/resident_model.dart';
import '../features/invoices/screens/invoices_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/ai_assistant/screens/ai_assistant_screen.dart';
import '../features/community/screens/community_settings_screen.dart';
import '../features/invoices/screens/billing_types_screen.dart';
import '../features/invoices/screens/create_invoice_screen.dart';
import '../features/settings/screens/payment_settings_screen.dart';
import '../features/expenses/screens/expenses_screen.dart';
import '../features/letters/screens/letters_screen.dart';
import '../features/letters/screens/create_letter_screen.dart';
import '../features/settings/screens/admin_profile_screen.dart';
import '../features/resident_portal/screens/resident_home_screen.dart';
import '../features/resident_portal/screens/resident_invoices_screen.dart';
import '../features/resident_portal/screens/resident_profile_screen.dart';
import '../features/announcements/screens/announcements_screen.dart';
import '../features/announcements/screens/create_announcement_screen.dart';
import '../features/marketplace/screens/marketplace_screen.dart';
import '../features/marketplace/screens/add_listing_screen.dart';
import '../features/marketplace/screens/listing_detail_screen.dart';
import '../features/marketplace/models/marketplace_listing_model.dart';
import '../features/resident_portal/screens/resident_kas_screen.dart';
import '../features/auth/screens/register_resident_step2_screen.dart';
import '../features/auth/models/register_step1_data.dart';
import '../features/help/screens/help_center_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/layanan/screens/layanan_screen.dart';
import '../features/layanan/screens/request_letter_screen.dart';
import '../features/layanan/screens/complaint_form_screen.dart';
import '../features/layanan/screens/admin_requests_screen.dart';
import '../features/layanan/screens/admin_complaints_screen.dart';
import '../features/layanan/screens/admin_contacts_screen.dart';
import '../shell/admin_shell.dart';
import '../shell/resident_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _adminShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'adminShell');
final _residentShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'residentShell');

class _AuthChangeNotifier extends ChangeNotifier {
  Map<String, dynamic>? cachedProfile;

  _AuthChangeNotifier({required this.onRecovery, required this.onRecoveryEnd}) {
    // Fetch profile awal saat app launch (user mungkin sudah login)
    _refreshProfile().then((_) => notifyListeners());

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        onRecovery();
      } else if (data.event == AuthChangeEvent.userUpdated ||
          data.event == AuthChangeEvent.signedOut) {
        onRecoveryEnd();
      }
      // Fetch profile dulu sebelum notify — redirect sudah punya data saat dipanggil
      await _refreshProfile();
      notifyListeners();
    });
  }

  Future<void> _refreshProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      cachedProfile = null;
      return;
    }
    try {
      cachedProfile = await Supabase.instance.client
          .from('profiles')
          .select('role, status')
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {
      // Pertahankan cache lama kalau query gagal
    }
  }

  final VoidCallback onRecovery;
  final VoidCallback onRecoveryEnd;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(
    onRecovery: () => ref.read(recoveryModeProvider.notifier).setRecovery(true),
    onRecoveryEnd: () => ref.read(recoveryModeProvider.notifier).setRecovery(false),
  );
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final loc = state.matchedLocation;

      const authPages = ['/login', '/register/admin', '/register/resident', '/register/resident/step2', '/forgot-password', '/reset-password'];

      // Halaman publik — bisa diakses oleh siapa saja, login maupun tidak
      if (loc == '/bantuan') return null;

      // Saat recovery mode aktif, user harus tetap di /reset-password
      final isRecoveryMode = ref.read(recoveryModeProvider);
      if (isRecoveryMode && loc == '/reset-password') return null;

      if (!isLoggedIn) {
        if (authPages.contains(loc)) return null;
        return '/login';
      }

      // Baca dari cache — sudah di-fetch sebelum notifyListeners dipanggil
      final profile = authNotifier.cachedProfile;

      // Profile belum siap (race condition saat registrasi) — jangan interfere
      if (profile == null) return null;

      final role = profile['role'] as String?;
      final status = profile['status'] as String?;

      // Pending user → can only access /pending-approval
      if (status == 'pending') {
        return loc == '/pending-approval' ? null : '/pending-approval';
      }

      // Active user on auth/register pages → redirect to home
      if (authPages.contains(loc)) {
        if (role == 'admin') return '/admin';
        if (role == 'resident') return '/resident';
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register/admin',
        builder: (context, state) => const RegisterAdminScreen(),
      ),
      GoRoute(
        path: '/register/resident',
        builder: (context, state) => const RegisterResidentScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/register/resident/step2',
        builder: (context, state) => RegisterResidentStep2Screen(
          step1Data: state.extra as RegisterStep1Data,
        ),
      ),
      GoRoute(
        path: '/bantuan',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/admin/profil',
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: '/admin/pengaturan-rek',
        builder: (context, state) => const PaymentSettingsScreen(),
      ),
      // Resident management routes — full-screen, no bottom nav
      GoRoute(
        path: '/admin/warga/detail',
        builder: (context, state) =>
            ResidentDetailScreen(resident: state.extra as ResidentModel),
      ),
      GoRoute(
        path: '/admin/warga/tambah',
        builder: (context, state) => const AddEditResidentScreen(),
      ),
      GoRoute(
        path: '/admin/warga/edit',
        builder: (context, state) =>
            AddEditResidentScreen(resident: state.extra as ResidentModel),
      ),

      // Notification routes — full-screen, no bottom nav
      GoRoute(
        path: '/resident/notifikasi',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/admin/notifikasi',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Routes yang di-push di luar ShellRoute agar tidak bentrok bottom nav
      GoRoute(
        path: '/resident/kas',
        builder: (context, state) => const ResidentKasScreen(),
      ),
      GoRoute(
        path: '/resident/marketplace/tambah',
        builder: (context, state) => const AddListingScreen(),
      ),
      GoRoute(
        path: '/resident/marketplace/detail',
        builder: (context, state) =>
            ListingDetailScreen(listing: state.extra as MarketplaceListingModel),
      ),

      // Admin routes
      ShellRoute(
        navigatorKey: _adminShellNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/warga',
            builder: (context, state) => const ResidentsScreen(),
          ),
          GoRoute(
            path: '/admin/tagihan',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: '/admin/tagihan/buat',
            builder: (context, state) => const CreateInvoiceScreen(),
          ),
          GoRoute(
            path: '/admin/pengeluaran',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/admin/laporan',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/admin/ai',
            builder: (context, state) => const AiAssistantScreen(),
          ),
          GoRoute(
            path: '/admin/surat',
            builder: (context, state) => const LettersScreen(),
          ),
          GoRoute(
            path: '/admin/surat/buat',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return CreateLetterScreen(
                prefilledResidentId: extra?['prefilledResidentId'] as String?,
                prefilledLetterType: extra?['prefilledLetterType'] as String?,
                prefilledPurpose: extra?['prefilledPurpose'] as String?,
                fromRequestId: extra?['fromRequestId'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/admin/pengumuman',
            builder: (context, state) => const AnnouncementsScreen(isAdmin: true),
          ),
          GoRoute(
            path: '/admin/pengumuman/buat',
            builder: (context, state) => const CreateAnnouncementScreen(),
          ),
          GoRoute(
            path: '/admin/pengaturan',
            builder: (context, state) => const CommunitySettingsScreen(),
          ),

          GoRoute(
            path: '/admin/pengaturan-iuran',
            builder: (context, state) => const BillingTypesScreen(),
          ),
        ],
      ),

      // Resident routes
      ShellRoute(
        navigatorKey: _residentShellNavigatorKey,
        builder: (context, state, child) => ResidentShell(child: child),
        routes: [
          GoRoute(
            path: '/resident',
            builder: (context, state) => const ResidentHomeScreen(),
          ),
          GoRoute(
            path: '/resident/tagihan',
            builder: (context, state) => const ResidentInvoicesScreen(),
          ),
          GoRoute(
            path: '/resident/akun',
            builder: (context, state) => const ResidentProfileScreen(),
          ),
          GoRoute(
            path: '/resident/pengumuman',
            builder: (context, state) => const AnnouncementsScreen(),
          ),
          GoRoute(
            path: '/resident/marketplace',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/resident/layanan',
            builder: (context, state) => const LayananScreen(),
          ),
        ],
      ),

      // Admin layanan full-screen routes (no bottom nav)
      GoRoute(
        path: '/admin/layanan-requests',
        builder: (context, state) => const AdminRequestsScreen(),
      ),
      GoRoute(
        path: '/admin/pengaduan',
        builder: (context, state) => const AdminComplaintsScreen(),
      ),
      GoRoute(
        path: '/admin/layanan/kontak',
        builder: (context, state) => const AdminContactsScreen(),
      ),

      // Layanan full-screen routes (no bottom nav)
      GoRoute(
        path: '/resident/layanan/permohonan',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return RequestLetterScreen(initialType: type);
        },
      ),
      GoRoute(
        path: '/resident/layanan/pengaduan-baru',
        builder: (context, state) => const ComplaintFormScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.error}')),
    ),
  );
});


