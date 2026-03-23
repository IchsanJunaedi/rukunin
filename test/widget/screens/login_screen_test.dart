import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/auth/screens/login_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('LoginScreen renders email field, password field, and Masuk ke akunmu text', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.zero,
          ),
          child: const MaterialApp(home: LoginScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Masuk ke akunmu'), findsOneWidget);
  });
}
