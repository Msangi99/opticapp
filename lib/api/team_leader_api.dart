import 'dart:convert';

import 'client.dart';

/// Team leader dashboard overview (agents, assignments, IMEI stats).
Future<Map<String, dynamic>> getTeamLeaderDashboard() async {
  final res = await apiGet('/team-leader/dashboard');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load dashboard');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getTeamLeaderTeamInventory({
  int? agentId,
  int? productId,
  String status = 'all',
  String? q,
  int page = 1,
  int perPage = 35,
}) async {
  final params = <String, String>{
    'page': '$page',
    'per_page': '$perPage',
    'status': status,
  };
  if (agentId != null) params['agent_id'] = '$agentId';
  if (productId != null) params['product_id'] = '$productId';
  if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();

  final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
  final res = await apiGet('/team-leader/team-inventory?$query');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load inventory');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getTeamLeaderAssignFormData() async {
  final res = await apiGet('/team-leader/assign-agent/form-data');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load form data');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<List<Map<String, dynamic>>> getTeamLeaderAssignableImeis(int productId) async {
  final res = await apiGet('/team-leader/assign-agent/assignable-imeis?product_id=$productId');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load devices');
  }
  final list = map?['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

class ValidateImeiResult {
  const ValidateImeiResult({
    required this.ok,
    this.productListId,
    this.imeiNumber,
    this.message,
  });

  final bool ok;
  final int? productListId;
  final String? imeiNumber;
  final String? message;
}

Future<ValidateImeiResult> validateTeamLeaderAssignImei({
  required int productId,
  required String imei,
}) async {
  final res = await apiPost('/team-leader/assign-agent/validate-imei', {
    'product_id': productId,
    'imei': imei,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode == 200 && map?['valid'] == true) {
    final data = map!['data'];
    if (data is Map<String, dynamic>) {
      final id = data['product_list_id'];
      final int? lid = id is int ? id : (id is num ? id.toInt() : int.tryParse(id.toString()));
      return ValidateImeiResult(ok: true, productListId: lid, imeiNumber: data['imei_number']?.toString());
    }
  }
  return ValidateImeiResult(ok: false, message: map?['message']?.toString() ?? 'IMEI not found for this product.');
}

Future<int> postTeamLeaderAssignAgent({
  required int agentId,
  required int productId,
  required List<int> productListIds,
}) async {
  final res = await apiPost('/team-leader/assign-agent', {
    'agent_id': agentId,
    'product_id': productId,
    'product_list_ids': productListIds,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode == 201) {
    final data = map?['data'];
    if (data is Map<String, dynamic>) {
      final n = data['assigned_count'];
      if (n is int) return n;
      if (n is num) return n.toInt();
    }
    return productListIds.length;
  }
  throw Exception(map?['message']?.toString() ?? res.body);
}

Future<List<Map<String, dynamic>>> getTeamLeaderReturnProducts() async {
  final res = await apiGet('/team-leader/return-devices/form-data');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load products');
  }
  final data = map?['data'];
  if (data is Map<String, dynamic>) {
    final list = data['products'];
    if (list is List) return list.cast<Map<String, dynamic>>();
  }
  return [];
}

Future<List<Map<String, dynamic>>> getTeamLeaderReturnableImeis(int productId) async {
  final res = await apiGet('/team-leader/return-devices/assignable-imeis?product_id=$productId');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load devices');
  }
  final list = map?['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

Future<int> postTeamLeaderReturnDevices({
  required int productId,
  required List<int> productListIds,
}) async {
  final res = await apiPost('/team-leader/return-devices', {
    'product_id': productId,
    'product_list_ids': productListIds,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode == 200 || res.statusCode == 201) {
    final data = map?['data'];
    if (data is Map<String, dynamic>) {
      final n = data['items_count'] ?? data['returned_count'];
      if (n is int) return n;
      if (n is num) return n.toInt();
    }
    return productListIds.length;
  }
  throw Exception(map?['message']?.toString() ?? res.body);
}
