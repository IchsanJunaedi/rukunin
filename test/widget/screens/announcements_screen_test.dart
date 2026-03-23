import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/announcements/screens/announcements_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('AnnouncementsScreen (admin) renders without crash with empty list', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(announcements: []),
        child: const MaterialApp(home: AnnouncementsScreen(isAdmin: true)),
      ),
    );
    await tester.pumpAndSettle();

    // Screen renders — no crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
