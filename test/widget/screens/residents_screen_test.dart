import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/residents/screens/residents_screen.dart';
import 'package:rukunin/features/residents/models/resident_model.dart';
import '../../helpers/mock_providers.dart';

ResidentModel _buildResident() => ResidentModel.fromMap({
      'id': 'res-1',
      'community_id': 'com-1',
      'full_name': 'Budi Santoso',
      'unit_number': '12',
      'phone': null,
      'nik': null,
      'email': null,
      'status': 'active',
      'photo_url': null,
      'rt_number': null,
      'block': null,
      'motorcycle_count': 0,
      'car_count': 0,
      'created_at': '2026-01-01T00:00:00.000Z',
    });

void main() {
  testWidgets('ResidentsScreen shows search field when list is empty', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(residents: []),
        child: const MaterialApp(home: ResidentsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('ResidentsScreen shows resident name when data is present', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(residents: [_buildResident()]),
        child: const MaterialApp(home: ResidentsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
  });
}
