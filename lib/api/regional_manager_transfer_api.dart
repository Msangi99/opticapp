import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> listRegionalManagerTransfers() async {
  final res = await apiGet('/regional-manager/transfers?per_page=50');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load transfers');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<Map<String, dynamic>> getRegionalManagerTransferDetail(int transferId) async {
  final res = await apiGet('/regional-manager/transfers/$transferId');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load transfer detail');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> acceptRegionalManagerTransfer(int transferId, {String? note}) async {
  final body = <String, dynamic>{};
  if (note != null && note.trim().isNotEmpty) {
    body['note'] = note.trim();
  }
  final res = await apiPost('/regional-manager/transfers/$transferId/accept', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Accept failed');
  }
  return data ?? {};
}

Future<Map<String, dynamic>> declineRegionalManagerTransfer(int transferId, {String? note}) async {
  final body = <String, dynamic>{};
  if (note != null && note.trim().isNotEmpty) {
    body['note'] = note.trim();
  }
  final res = await apiPost('/regional-manager/transfers/$transferId/decline', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Decline failed');
  }
  return data ?? {};
}
