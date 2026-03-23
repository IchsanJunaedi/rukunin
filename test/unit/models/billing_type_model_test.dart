import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/invoices/models/billing_type_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('BillingTypeModel', () {
    test('fromMap parses all fields correctly', () {
      final model = BillingTypeModel.fromMap(billingTypeMap);
      expect(model.id, 'bt-1');
      expect(model.name, 'Iuran Bulanan');
      expect(model.amount, 150000.0);
      expect(model.billingDay, 10);
      expect(model.isActive, isTrue);
      expect(model.costPerMotorcycle, 25000.0);
      expect(model.costPerCar, 50000.0);
    });

    test('isActive defaults to true when null', () {
      final model = BillingTypeModel.fromMap({...billingTypeMap, 'is_active': null});
      expect(model.isActive, isTrue);
    });

    test('toMap includes all mutable fields', () {
      final model = BillingTypeModel.fromMap(billingTypeMap);
      final map = model.toMap();
      expect(map['name'], 'Iuran Bulanan');
      expect(map['amount'], 150000.0);
      expect(map['billing_day'], 10);
      expect(map['is_active'], isTrue);
    });
  });
}
