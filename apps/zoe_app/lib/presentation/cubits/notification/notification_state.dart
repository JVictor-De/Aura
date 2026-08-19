part of 'notification_cubit.dart';

class NotificationState {
  final List<AppNotification> notifications;

  const NotificationState({required this.notifications});

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
}
