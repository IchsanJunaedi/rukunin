import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/letter_request_model.dart';
import 'package:rukunin/features/layanan/models/complaint_model.dart';
import 'package:rukunin/features/layanan/models/community_contact_model.dart';

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

  group('CommunityContactModel', () {
    final map = {
      'id': 'con-1',
      'community_id': 'com-1',
      'nama': 'Pak Budi',
      'jabatan': 'Ketua RW',
      'phone': '628123456789',
      'photo_url': null,
      'urutan': 0,
      'created_at': '2026-03-23T08:00:00.000Z',
      'updated_at': '2026-03-23T08:00:00.000Z',
    };

    test('fromMap parses correctly', () {
      final model = CommunityContactModel.fromMap(map);
      expect(model.id, 'con-1');
      expect(model.communityId, 'com-1');
      expect(model.nama, 'Pak Budi');
      expect(model.jabatan, 'Ketua RW');
      expect(model.phone, '628123456789');
      expect(model.photoUrl, isNull);
      expect(model.urutan, 0);
    });

    test('fromMap handles photo_url', () {
      final model = CommunityContactModel.fromMap({
        ...map,
        'photo_url': 'https://example.com/photo.jpg',
      });
      expect(model.photoUrl, 'https://example.com/photo.jpg');
    });

    test('initials returns first two letters of name', () {
      expect(CommunityContactModel.fromMap(map).initials, 'PB');
      expect(
        CommunityContactModel.fromMap({...map, 'nama': 'Budi'}).initials,
        'BU',
      );
    });
  });
}
