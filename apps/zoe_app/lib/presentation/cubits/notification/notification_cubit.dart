/// NotificationCubit — central de notificações in-app.
///
/// Referência: ARCHITECTURE.md §2.6: Notificações (Push + In-App)
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../domain/entities/notification.dart';

part 'notification_state.dart';

class NotificationCubit extends HydratedCubit<NotificationState> {
  NotificationCubit() : super(const NotificationState(notifications: []));

  void addNotification(AppNotification notification) {
    final updated = [notification, ...state.notifications];
    emit(NotificationState(notifications: updated));
  }

  void markAsRead(String notificationId) {
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();
    emit(NotificationState(notifications: updated));
  }

  void markAllAsRead() {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    emit(NotificationState(notifications: updated));
  }

  void removeNotification(String notificationId) {
    final updated = state.notifications
        .where((n) => n.id != notificationId)
        .toList();
    emit(NotificationState(notifications: updated));
  }

  void clearAll() {
    emit(const NotificationState(notifications: []));
  }

  @override
  NotificationState? fromJson(Map<String, dynamic> json) {
    try {
      final list = (json['notifications'] as List? ?? [])
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      return NotificationState(notifications: list);
    } catch (_) {
      return const NotificationState(notifications: []);
    }
  }

  @override
  Map<String, dynamic>? toJson(NotificationState state) {
    return {
      'notifications': state.notifications.map((n) => n.toJson()).toList(),
    };
  }
}
