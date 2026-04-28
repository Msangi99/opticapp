import 'dart:convert';
import 'client.dart';

/// Other active agents eligible as transfer recipients (agent auth; mirrors web transfer form).
Future<List<Map<String, dynamic>>> getAgentTransferRecipients() async {
  final res = await apiGet('/agent/transfer-recipients');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load agents');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getTransferableImeis(int productId) async {
  final res = await apiGet('/agent/transferable-imeis?product_id=$productId');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load devices');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<Map<String, dynamic>> createAgentTransfer({
  required int toAgentId,
  required List<int> productListIds,
  String? message,
}) async {
  final body = <String, dynamic>{
    'to_agent_id': toAgentId,
    'product_list_ids': productListIds,
  };
  if (message != null && message.trim().isNotEmpty) {
    body['message'] = message.trim();
  }
  final res = await apiPost('/agent/transfers', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201) {
    throw Exception(data?['message']?.toString() ?? 'Transfer request failed');
  }
  return data ?? {};
}

Future<List<Map<String, dynamic>>> listAgentTransfers() async {
  final res = await apiGet('/agent/transfers?per_page=50');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load transfers');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<Map<String, dynamic>> getAgentTransferDetail(int transferId) async {
  final res = await apiGet('/agent/transfers/$transferId');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load transfer detail');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> cancelAgentTransfer(int transferId) async {
  final res = await apiPost('/agent/transfers/$transferId/cancel', {});
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Cancel failed');
  }
}
