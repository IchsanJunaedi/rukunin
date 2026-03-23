import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/marketplace/screens/marketplace_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('MarketplaceScreen shows empty state when no listings', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(listings: []),
        child: const MaterialApp(home: MarketplaceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada yang jualan nih!'), findsOneWidget);
  });
}
