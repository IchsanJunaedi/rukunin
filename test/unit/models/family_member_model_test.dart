import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/residents/models/family_member.dart';
import '../../helpers/test_data.dart';

void main() {
  group('FamilyMember', () {
    test('fromMap parses all fields correctly', () {
      final member = FamilyMember.fromMap(familyMemberMap);
      expect(member.id, 'fm-1');
      expect(member.fullName, 'Siti Aminah');
      expect(member.nik, '3275010101010002');
      expect(member.relationship, 'Istri');
    });

    test('fromMap handles null id and resident_id', () {
      final member = FamilyMember.fromMap({
        ...familyMemberMap,
        'id': null,
        'resident_id': null,
      });
      expect(member.id, isNull);
      expect(member.residentId, isNull);
    });

    test('fromMap handles null nik', () {
      final member = FamilyMember.fromMap({
        ...familyMemberMap,
        'nik': null,
      });
      expect(member.nik, isNull);
    });

    test('toMap converts empty nik string to null', () {
      final member = FamilyMember.fromMap({...familyMemberMap, 'nik': ''});
      final map = member.toMap();
      expect(map['nik'], isNull);
    });

    test('toMap preserves non-empty nik', () {
      final member = FamilyMember.fromMap(familyMemberMap);
      final map = member.toMap();
      expect(map['nik'], '3275010101010002');
    });

    test('toMap omits id when null', () {
      final member = FamilyMember.fromMap({...familyMemberMap, 'id': null});
      final map = member.toMap();
      expect(map.containsKey('id'), isFalse);
    });
  });
}
