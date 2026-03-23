import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/expenses/models/expense_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ExpenseModel', () {
    test('fromMap parses all fields correctly', () {
      final model = ExpenseModel.fromMap(expenseMap);
      expect(model.id, 'exp-1');
      expect(model.communityId, 'com-1');
      expect(model.amount, 250000.0);
      expect(model.category, 'Kebersihan');
      expect(model.description, 'Bayar tukang sampah');
    });

    test('fromMap handles null category with empty string fallback', () {
      final model = ExpenseModel.fromMap({...expenseMap, 'category': null});
      expect(model.category, '');
    });

    test('fromMap handles null receipt_url', () {
      final model = ExpenseModel.fromMap({...expenseMap, 'receipt_url': null});
      expect(model.receiptUrl, isNull);
    });

    test('toMap includes required fields', () {
      final model = ExpenseModel.fromMap(expenseMap);
      final map = model.toMap();
      expect(map['amount'], 250000.0);
      expect(map['category'], 'Kebersihan');
      expect(map['description'], 'Bayar tukang sampah');
      expect(map.containsKey('receipt_url'), isTrue);
    });
  });
}
