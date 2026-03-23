import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/announcements/models/announcement_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('AnnouncementModel', () {
    test('fromMap parses all fields correctly', () {
      final model = AnnouncementModel.fromMap(announcementMap);
      expect(model.id, 'ann-1');
      expect(model.title, 'Rapat Warga');
      expect(model.type, 'info');
      expect(model.createdAt.year, 2026);
      expect(model.createdAt.month, 3);
    });

    test('fromMap handles null created_by', () {
      final model = AnnouncementModel.fromMap({...announcementMap, 'created_by': null});
      expect(model.createdBy, isNull);
    });

    test('type defaults to info when null', () {
      final model = AnnouncementModel.fromMap({...announcementMap, 'type': null});
      expect(model.type, 'info');
    });

    test('toMap includes community_id, title, body, type', () {
      final model = AnnouncementModel.fromMap(announcementMap);
      final map = model.toMap();
      expect(map['community_id'], 'com-1');
      expect(map['title'], 'Rapat Warga');
      expect(map['type'], 'info');
    });
  });
}
