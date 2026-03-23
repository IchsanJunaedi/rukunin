import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rukunin/features/resident_portal/screens/resident_home_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('ResidentHomeScreen renders without crash when profile is null', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: const MaterialApp(home: ResidentHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Render success — profile is null so screen shows loading/empty state
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
