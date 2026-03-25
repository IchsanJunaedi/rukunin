import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/letter_request_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('LetterRequestModel', () {
    test('fromMap parses all fields correctly', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.id, 'req-1');
      expect(model.letterType, 'domisili');
      expect(model.status, 'pending');
      expect(model.residentName, 'Budi Santoso');
    });

    test('fromMap handles null profiles', () {
      final model = LetterRequestModel.fromMap({...letterRequestMap, 'profiles': null});
      expect(model.residentName, isNull);
      expect(model.residentUnit, isNull);
    });

    test('typeLabel returns Indonesian label', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.typeLabel, 'Keterangan Domisili');
    });

    test('statusLabel returns Indonesian label', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.statusLabel, 'Menunggu Verifikasi');
    });

    test('isActive is true for pending', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.isActive, isTrue);
    });

    test('isActive is false for completed', () {
      final model = LetterRequestModel.fromMap({...letterRequestMap, 'status': 'completed'});
      expect(model.isActive, isFalse);
    });

    test('progressPercent is 0.25 for pending', () {
      final model = LetterRequestModel.fromMap(letterRequestMap);
      expect(model.progressPercent, 0.25);
    });

    test('progressPercent is 1.0 for completed', () {
      final model = LetterRequestModel.fromMap({...letterRequestMap, 'status': 'completed'});
      expect(model.progressPercent, 1.0);
    });
  });
}
