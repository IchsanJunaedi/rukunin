import 'package:flutter_test/flutter_test.dart';
import 'package:rukunin/features/invoices/models/invoice_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('InvoiceModel', () {
    test('fromJson parses all fields correctly', () {
      final model = InvoiceModel.fromJson(invoiceMap);
      expect(model.id, 'inv-1');
      expect(model.communityId, 'com-1');
      expect(model.residentId, 'res-1');
      expect(model.billingTypeId, 'bt-1');
      expect(model.amount, 150000.0);
      expect(model.month, 3);
      expect(model.year, 2026);
      expect(model.dueDate, DateTime.parse('2026-03-31'));
      expect(model.status, 'pending');
      expect(model.billingTypeName, 'Iuran Bulanan');
    });

    test('fromJson handles null optional fields', () {
      final model = InvoiceModel.fromJson({
        ...invoiceMap,
        'payment_link': null,
        'payment_token': null,
        'wa_sent_at': null,
        'billing_types': null,
      });
      expect(model.paymentLink, isNull);
      expect(model.paymentToken, isNull);
      expect(model.waSentAt, isNull);
      expect(model.billingTypeName, 'Iuran'); // default fallback
    });

    test('fromJson parses wa_sent_at as DateTime when present', () {
      final model = InvoiceModel.fromJson({
        ...invoiceMap,
        'wa_sent_at': '2026-03-05T10:00:00.000Z',
      });
      expect(model.waSentAt, isNotNull);
      expect(model.waSentAt!.year, 2026);
    });

    test('fromJson falls back gracefully on missing amount', () {
      final model = InvoiceModel.fromJson({
        ...invoiceMap,
        'amount': null,
      });
      expect(model.amount, 0.0);
    });
  });
}
