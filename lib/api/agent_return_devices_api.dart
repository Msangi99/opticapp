import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getReturnableImeis(int productId) async {
  final res = await apiGet('/agent/return-devices/assignable-imeis?product_id=$productId');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load devices');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<void> returnDevicesToTeamLeader(int productId, List<int> productListIds, {String? message}) async {
  final body = <String, dynamic>{
    'product_id': productId,
    'product_list_ids': productListIds,
  };
  if (message != null && message.trim().isNotEmpty) {
    body['message'] = message.trim();
  }
  final res = await apiPost('/agent/return-devices', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(data?['message']?.toString() ?? 'Return failed');
  }
}

Future<List<Map<String, dynamic>>> listAgentReturnRequests() async {
  final res = await apiGet('/agent/return-requests?per_page=50');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load return requests');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<void> cancelAgentReturnRequest(int returnId) async {
  final res = await apiPost('/agent/return-requests/$returnId/cancel', {});
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Cancel failed');
  }
}
