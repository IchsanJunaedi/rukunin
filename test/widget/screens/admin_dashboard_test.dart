import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/dashboard/screens/admin_dashboard_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('AdminDashboardScreen renders Aksi Cepat section', (tester) async {
    tester.view.physicalSize = const Size(1080, 3840);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(dashboardData: {
          'admin_name': 'Admin Test',
          'rw_name': 'RW 01',
          'community_code': 'ABC123',
          'total_unit': 20,
          'sudah_bayar': 5,
          'menunggu_verifikasi': 2,
          'belum_bayar': 13,
          'total_tagihan': 3000000.0,
          'total_terkumpul': 500000.0,
        }),
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aksi Cepat'), findsOneWidget);
    expect(find.text('Admin'), findsAtLeastNWidgets(1)); // first word of admin_name
  });
}
