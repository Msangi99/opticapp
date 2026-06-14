import 'package:flutter/foundation.dart';

import '../api/notifications_api.dart';

class NotificationsProvider extends ChangeNotifier {
  List<AppNotificationItem> items = [];
  int unreadCount = 0;
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        fetchNotifications(),
        fetchUnreadNotificationCount(),
      ]);
      items = results[0] as List<AppNotificationItem>;
      unreadCount = results[1] as int;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSilently() async {
    try {
      final results = await Future.wait([
        fetchNotifications(),
        fetchUnreadNotificationCount(),
      ]);
      items = results[0] as List<AppNotificationItem>;
      unreadCount = results[1] as int;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markRead(AppNotificationItem item) async {
    if (!item.isUnread) return;
    await markNotificationRead(item.id);
    unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
    items = items
        .map((n) => n.id == item.id
            ? AppNotificationItem(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                route: n.route,
                entityType: n.entityType,
                entityId: n.entityId,
                readAt: DateTime.now(),
                createdAt: n.createdAt,
              )
            : n)
        .toList();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await markAllNotificationsRead();
    unreadCount = 0;
    items = items
        .map((n) => AppNotificationItem(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              route: n.route,
              entityType: n.entityType,
              entityId: n.entityId,
              readAt: n.readAt ?? DateTime.now(),
              createdAt: n.createdAt,
            ))
        .toList();
    notifyListeners();
  }
}
