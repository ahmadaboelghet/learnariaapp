import 'package:flutter_test/flutter_test.dart';
import 'package:learnaria/models/notification_item.dart';

void main() {
  group('NotificationItem Tests', () {
    test('NotificationItem initializes with isRead = false by default', () {
      final item = NotificationItem(
        id: '1',
        title: 'Title',
        body: 'Body',
        titleAr: 'العنوان',
        bodyAr: 'المحتوى',
        timestamp: DateTime.now(),
        category: 'system'
      );

      expect(item.isRead, false);
      expect(item.id, '1');
      expect(item.category, 'system');
    });

    test('NotificationItem can initialize with isRead = true', () {
      final item = NotificationItem(
        id: '2',
        title: 'Title',
        body: 'Body',
        titleAr: 'العنوان',
        bodyAr: 'المحتوى',
        timestamp: DateTime.now(),
        category: 'payment',
        isRead: true
      );

      expect(item.isRead, true);
    });
  });
}
