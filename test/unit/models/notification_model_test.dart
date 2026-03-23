import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:rukunin/features/notifications/models/notification_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('NotificationModel', () {
    test('fromMap parses all fields correctly', () {
      final model = NotificationModel.fromMap(notificationMap);
      expect(model.id, 'notif-1');
      expect(model.type, 'payment');
      expect(model.title, 'Tagihan Bulan Maret');
      expect(model.isRead, isFalse);
    });

    test('fromMap handles null body', () {
      final model = NotificationModel.fromMap({
        ...notificationMap,
        'body': null,
      });
      expect(model.body, isNull);
    });

    test('isRead defaults to false when null', () {
      final model = NotificationModel.fromMap({
        ...notificationMap,
        'is_read': null,
      });
      expect(model.isRead, isFalse);
    });

    test('isRead is true when set', () {
      final model = NotificationModel.fromMap({
        ...notificationMap,
        'is_read': true,
      });
      expect(model.isRead, isTrue);
    });

    test('icon returns receipt icon for payment type', () {
      final model = NotificationModel.fromMap(notificationMap);
      expect(model.icon, isA<IconData>());
    });

    test('icon returns notifications icon for unknown type', () {
      final model = NotificationModel.fromMap({
        ...notificationMap,
        'type': 'unknown',
      });
      expect(model.icon, Icons.notifications_rounded);
    });
  });
}
