import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/residents/models/resident_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ResidentModel', () {
    test('fromMap parses all fields correctly', () {
      final model = ResidentModel.fromMap(residentMap);
      expect(model.id, 'res-1');
      expect(model.fullName, 'Budi Santoso');
      expect(model.unitNumber, '12');
      expect(model.status, 'active');
      expect(model.motorcycleCount, 1);
      expect(model.carCount, 0);
    });

    test('fromMap handles null optional fields', () {
      final model = ResidentModel.fromMap({
        ...residentMap,
        'community_id': null,
        'unit_number': null,
        'phone': null,
        'nik': null,
        'email': null,
        'photo_url': null,
        'rt_number': null,
        'block': null,
      });
      expect(model.communityId, isNull);
      expect(model.unitNumber, isNull);
      expect(model.phone, isNull);
    });

    test('status defaults to active when null', () {
      final model = ResidentModel.fromMap({...residentMap, 'status': null});
      expect(model.status, 'active');
    });

    test('isActive returns true for active status', () {
      final model = ResidentModel.fromMap(residentMap);
      expect(model.isActive, isTrue);
    });

    test('isActive returns false for non-active status', () {
      final model = ResidentModel.fromMap({...residentMap, 'status': 'inactive'});
      expect(model.isActive, isFalse);
    });

    test('initials returns two uppercase letters from first two words', () {
      final model = ResidentModel.fromMap(residentMap); // 'Budi Santoso'
      expect(model.initials, 'BS');
    });

    test('initials handles single word name', () {
      final model = ResidentModel.fromMap({...residentMap, 'full_name': 'Ahmad'});
      expect(model.initials, 'A');
    });

    test('alamatLengkap includes block, unit, rt', () {
      final model = ResidentModel.fromMap(residentMap);
      expect(model.alamatLengkap, contains('A'));
      expect(model.alamatLengkap, contains('12'));
      expect(model.alamatLengkap, contains('2'));
    });
  });
}
