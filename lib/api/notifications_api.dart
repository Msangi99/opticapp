import 'dart:convert';
import 'client.dart';

class AppNotificationItem {
  AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.route,
    this.entityType,
    this.entityId,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? route;
  final String? entityType;
  final int? entityId;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isUnread => readAt == null;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      route: json['route']?.toString(),
      entityType: json['entity_type']?.toString(),
      entityId: json['entity_id'] is int
          ? json['entity_id'] as int
          : int.tryParse('${json['entity_id']}'),
      readAt: json['read_at'] != null ? DateTime.tryParse('${json['read_at']}') : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
    );
  }
}

Future<List<AppNotificationItem>> fetchNotifications({int page = 1}) async {
  final res = await apiGet('/notifications?per_page=30&page=$page');
  final decoded = jsonDecode(res.body);
  if (res.statusCode != 200) {
    throw Exception(_messageFromBody(decoded));
  }
  final data = decoded['data'];
  if (data is! List) return [];
  return data
      .whereType<Map>()
      .map((e) => AppNotificationItem.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

Future<int> fetchUnreadNotificationCount() async {
  final res = await apiGet('/notifications/unread-count');
  final decoded = jsonDecode(res.body);
  if (res.statusCode != 200) {
    return 0;
  }
  final data = decoded['data'];
  if (data is Map) {
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }
  return 0;
}

Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
  final res = await apiPost('/device-tokens', {
    'token': token,
    'platform': platform,
  });
  if (res.statusCode != 200) {
    final decoded = jsonDecode(res.body);
    throw Exception(_messageFromBody(decoded));
  }
}

Future<void> unregisterDeviceToken({String? token}) async {
  final path = (token != null && token.isNotEmpty)
      ? '/device-tokens?token=${Uri.encodeComponent(token)}'
      : '/device-tokens';
  await apiDelete(path);
}

Future<void> markNotificationRead(String id) async {
  final res = await apiPost('/notifications/$id/read', {});
  if (res.statusCode != 200) {
    final decoded = jsonDecode(res.body);
    throw Exception(_messageFromBody(decoded));
  }
}

Future<void> markAllNotificationsRead() async {
  final res = await apiPost('/notifications/read-all', {});
  if (res.statusCode != 200) {
    final decoded = jsonDecode(res.body);
    throw Exception(_messageFromBody(decoded));
  }
}

String _messageFromBody(dynamic decoded) {
  if (decoded is Map && decoded['message'] != null) {
    return decoded['message'].toString();
  }
  return 'Notification request failed';
}
