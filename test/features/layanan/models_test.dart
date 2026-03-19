import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/letter_request_model.dart';
import 'package:rukunin/features/layanan/models/complaint_model.dart';

void main() {
  group('LetterRequestModel', () {
    final map = {
      'id': 'req-1',
      'community_id': 'com-1',
      'resident_id': 'res-1',
      'letter_type': 'domisili',
      'purpose': 'Melamar kerja',
      'notes': null,
      'status': 'pending',
      'admin_notes': null,
      'letter_id': null,
      'created_at': '2026-03-19T10:00:00.000Z',
      'updated_at': '2026-03-19T10:00:00.000Z',
      'profiles': {'full_name': 'Budi Santoso', 'unit_number': '12'},
    };

    test('fromMap parses correctly', () {
      final model = LetterRequestModel.fromMap(map);
      expect(model.id, 'req-1');
      expect(model.letterType, 'domisili');
      expect(model.status, 'pending');
      expect(model.residentName, 'Budi Santoso');
    });

    test('progressPercent returns correct value', () {
      expect(LetterRequestModel.fromMap({...map, 'status': 'pending'}).progressPercent, 0.25);
      expect(LetterRequestModel.fromMap({...map, 'status': 'in_progress'}).progressPercent, 0.60);
      expect(LetterRequestModel.fromMap({...map, 'status': 'ready'}).progressPercent, 0.85);
      expect(LetterRequestModel.fromMap({...map, 'status': 'completed'}).progressPercent, 1.0);
      expect(LetterRequestModel.fromMap({...map, 'status': 'rejected'}).progressPercent, 0.0);
    });

    test('isActive returns true only for non-terminal statuses', () {
      expect(LetterRequestModel.fromMap({...map, 'status': 'pending'}).isActive, true);
      expect(LetterRequestModel.fromMap({...map, 'status': 'completed'}).isActive, false);
      expect(LetterRequestModel.fromMap({...map, 'status': 'rejected'}).isActive, false);
    });
  });

  group('ComplaintModel', () {
    final map = {
      'id': 'cmp-1',
      'community_id': 'com-1',
      'resident_id': 'res-1',
      'title': 'Jalan berlubang',
      'description': 'Di depan blok A ada lubang besar',
      'category': 'infrastruktur',
      'status': 'pending',
      'admin_notes': null,
      'photo_url': null,
      'created_at': '2026-03-19T10:00:00.000Z',
      'updated_at': '2026-03-19T10:00:00.000Z',
      'profiles': {'full_name': 'Siti Rahayu', 'unit_number': '5'},
    };

    test('fromMap parses correctly', () {
      final model = ComplaintModel.fromMap(map);
      expect(model.id, 'cmp-1');
      expect(model.category, 'infrastruktur');
      expect(model.status, 'pending');
    });

    test('categoryLabel returns correct label', () {
      expect(ComplaintModel.fromMap({...map, 'category': 'infrastruktur'}).categoryLabel, 'Infrastruktur');
      expect(ComplaintModel.fromMap({...map, 'category': 'keamanan'}).categoryLabel, 'Keamanan');
    });
  });
}
