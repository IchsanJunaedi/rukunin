import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/screens/admin_contacts_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('AdminContactsScreen renders FAB and empty state', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(contacts: []),
        child: const MaterialApp(home: AdminContactsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Belum ada kontak'), findsOneWidget);
  });
}
