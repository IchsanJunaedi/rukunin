import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/community_contact_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('CommunityContactModel', () {
    test('fromMap parses all fields correctly', () {
      final model = CommunityContactModel.fromMap(communityContactMap);
      expect(model.id, 'cc-1');
      expect(model.nama, 'Ahmad Ridwan');
      expect(model.jabatan, 'Ketua RT');
      expect(model.phone, '08111222333');
      expect(model.urutan, 1);
      expect(model.photoUrl, isNull);
    });

    test('initials returns two uppercase letters from two-word name', () {
      final model = CommunityContactModel.fromMap(communityContactMap); // 'Ahmad Ridwan'
      expect(model.initials, 'AR');
    });

    test('initials handles single-word name (two chars)', () {
      final model = CommunityContactModel.fromMap({...communityContactMap, 'nama': 'Ahmad'});
      expect(model.initials, 'AH');
    });

    test('toMap includes conditional photo_url when set', () {
      final model = CommunityContactModel.fromMap({
        ...communityContactMap,
        'photo_url': 'https://example.com/photo.jpg',
      });
      final map = model.toMap();
      expect(map['photo_url'], 'https://example.com/photo.jpg');
    });

    test('toMap omits photo_url when null', () {
      final model = CommunityContactModel.fromMap(communityContactMap);
      final map = model.toMap();
      expect(map.containsKey('photo_url'), isFalse);
    });
  });
}
