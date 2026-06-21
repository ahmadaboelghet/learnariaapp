class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String titleAr;
  final String bodyAr;
  final DateTime timestamp;
  final String category; // 'grade', 'attendance', 'payment', 'system'
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.titleAr,
    required this.bodyAr,
    required this.timestamp,
    required this.category,
    this.isRead = false,
  });
}
