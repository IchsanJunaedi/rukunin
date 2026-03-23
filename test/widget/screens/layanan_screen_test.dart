import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/screens/layanan_screen.dart';
import '../../helpers/mock_providers.dart';

void main() {
  testWidgets('LayananScreen renders three tabs: Surat, Pengaduan, Kontak', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(),
        child: const MaterialApp(home: LayananScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Surat'), findsOneWidget);
    expect(find.text('Pengaduan'), findsOneWidget);
    expect(find.text('Kontak'), findsOneWidget);
  });
}
