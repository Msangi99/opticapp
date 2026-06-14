import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> listTeamLeaderReturnRequestsIncoming() async {
  final res = await apiGet('/team-leader/return-requests/incoming?per_page=50');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load return requests');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> listTeamLeaderReturnRequestsOutgoing() async {
  final res = await apiGet('/team-leader/return-requests/outgoing?per_page=50');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load return requests');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<void> acceptTeamLeaderReturnIncoming(int returnId, {String? note}) async {
  final body = <String, dynamic>{};
  if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();
  final res = await apiPost('/team-leader/return-requests/incoming/$returnId/accept', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Accept failed');
  }
}

Future<void> declineTeamLeaderReturnIncoming(int returnId, {String? note}) async {
  final body = <String, dynamic>{};
  if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();
  final res = await apiPost('/team-leader/return-requests/incoming/$returnId/decline', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Decline failed');
  }
}

Future<void> cancelTeamLeaderReturnOutgoing(int returnId) async {
  final res = await apiPost('/team-leader/return-requests/outgoing/$returnId/cancel', {});
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Cancel failed');
  }
}
