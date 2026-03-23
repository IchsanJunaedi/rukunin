import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/layanan/models/complaint_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ComplaintModel', () {
    test('fromMap parses all fields correctly', () {
      final model = ComplaintModel.fromMap(complaintMap);
      expect(model.id, 'cmp-1');
      expect(model.title, 'Lampu Jalan Mati');
      expect(model.category, 'infrastruktur');
      expect(model.status, 'pending');
      expect(model.residentName, 'Budi Santoso');
      expect(model.residentUnit, '12');
    });

    test('fromMap handles null profiles', () {
      final model = ComplaintModel.fromMap({...complaintMap, 'profiles': null});
      expect(model.residentName, isNull);
      expect(model.residentUnit, isNull);
    });

    test('category defaults to lainnya when null', () {
      final model = ComplaintModel.fromMap({...complaintMap, 'category': null});
      expect(model.category, 'lainnya');
    });

    test('categoryLabel returns Indonesian label', () {
      final model = ComplaintModel.fromMap(complaintMap);
      expect(model.categoryLabel, 'Infrastruktur');
    });

    test('statusLabel returns Indonesian label for pending', () {
      final model = ComplaintModel.fromMap(complaintMap);
      expect(model.statusLabel, 'Menunggu');
    });

    test('isOpen is true for pending status', () {
      final model = ComplaintModel.fromMap(complaintMap);
      expect(model.isOpen, isTrue);
    });

    test('isOpen is false for resolved status', () {
      final model = ComplaintModel.fromMap({...complaintMap, 'status': 'resolved'});
      expect(model.isOpen, isFalse);
    });
  });
}
