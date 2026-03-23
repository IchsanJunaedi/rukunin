import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/resident_portal/screens/resident_invoices_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('ResidentInvoicesScreen shows empty state when no invoices', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(residentInvoices: []),
        child: const MaterialApp(home: ResidentInvoicesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada tagihan sama sekali'), findsOneWidget);
  });
}
