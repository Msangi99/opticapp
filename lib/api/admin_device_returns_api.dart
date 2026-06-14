import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> listAdminDeviceReturns({String? status}) async {
  final q = status != null && status.isNotEmpty ? '?status=$status&per_page=50' : '?per_page=50';
  final res = await apiGet('/admin/device-returns$q');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load device returns');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<void> acceptAdminDeviceReturn(int returnId, {String? note}) async {
  final body = <String, dynamic>{};
  if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();
  final res = await apiPost('/admin/device-returns/$returnId/accept', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Accept failed');
  }
}

Future<void> declineAdminDeviceReturn(int returnId, {String? note}) async {
  final body = <String, dynamic>{};
  if (note != null && note.trim().isNotEmpty) body['note'] = note.trim();
  final res = await apiPost('/admin/device-returns/$returnId/decline', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Decline failed');
  }
}
