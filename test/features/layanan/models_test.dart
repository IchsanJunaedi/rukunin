import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/letter_request_model.dart';
import 'package:rukunin/features/layanan/models/complaint_model.dart';
import 'package:rukunin/features/layanan/models/community_contact_model.dart';

void main() {
  group('LetterRequestModel', () {
    final baseMap = {
      'id': 'req-1',
      'community_id': 'com-1',
      'resident_id': 'res-1',
      'letter_type': 'domisili',
      'purpose': 'Melamar kerja',
      'notes': null,
      'status': 'pending',
      'admin_notes': null,
      'letter_id': null,
      'form_data': {'nik': '3201xxx', 'ttl': 'Jakarta, 01-01-1990', 'gender': 'Laki-laki', 'agama': 'Islam', 'keperluan': 'Melamar kerja'},
      'applicant_name': 'Budi Santoso',
      'created_at': '2026-03-25T10:00:00.000Z',
      'updated_at': '2026-03-25T10:00:00.000Z',
      'profiles': {'full_name': 'Budi Santoso', 'unit_number': '12'},
    };

    test('fromMap parses new fields correctly', () {
      final model = LetterRequestModel.fromMap(baseMap);
      expect(model.id, 'req-1');
      expect(model.applicantName, 'Budi Santoso');
      expect(model.formData, isNotNull);
      expect(model.formData!['nik'], '3201xxx');
    });

    test('fromMap handles null form_data and applicant_name', () {
      final map = {...baseMap, 'form_data': null, 'applicant_name': null};
      final model = LetterRequestModel.fromMap(map);
      expect(model.formData, isNull);
      expect(model.applicantName, isNull);
    });

    test('progressPercent reflects new status flow', () {
      expect(LetterRequestModel.fromMap({...baseMap, 'status': 'pending'}).progressPercent, 0.25);
      expect(LetterRequestModel.fromMap({...baseMap, 'status': 'verified'}).progressPercent, 0.9);
      expect(LetterRequestModel.fromMap({...baseMap, 'status': 'completed'}).progressPercent, 1.0);
      expect(LetterRequestModel.fromMap({...baseMap, 'status': 'rejected'}).progressPercent, 0.0);
    });

    test('isActive returns true for pending and verified', () {
      expect(LetterRequestModel.fromMap({...baseMap, 'status': 'pending'}).isActive, true);
      expect(LetterRequestModel.fromMap({...baseMap, 'status': 'verified'}).isActive, true);
      expect(LetterRequestModel.fromMap({...baseMap, 'status': 'completed'}).isActive, false);
      expect(LetterRequestModel.fromMap({...baseMap, 'status': 'rejected'}).isActive, false);
    });

    test('typeLabel returns correct label', () {
      expect(LetterRequestModel.fromMap(baseMap).typeLabel, 'Keterangan Domisili');
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
