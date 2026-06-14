import 'dart:convert';

import 'client.dart';

/// Regional manager dashboard overview (team leaders, agents, IMEI stats).
Future<Map<String, dynamic>> getRegionalManagerDashboard() async {
  final res = await apiGet('/regional-manager/dashboard');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load dashboard');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getRegionalManagerRegionInventory({
  int? teamLeaderId,
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
  if (teamLeaderId != null) params['team_leader_id'] = '$teamLeaderId';
  if (agentId != null) params['agent_id'] = '$agentId';
  if (productId != null) params['product_id'] = '$productId';
  if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();

  final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
  final res = await apiGet('/regional-manager/region-inventory?$query');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load inventory');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getRegionalManagerAssignFormData() async {
  final res = await apiGet('/regional-manager/assign-team-leader/form-data');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load form data');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<List<Map<String, dynamic>>> getRegionalManagerAssignableImeis(int productId) async {
  final res = await apiGet('/regional-manager/assign-team-leader/assignable-imeis?product_id=$productId');
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

Future<ValidateImeiResult> validateRegionalManagerAssignImei({
  required int productId,
  required String imei,
}) async {
  final res = await apiPost('/regional-manager/assign-team-leader/validate-imei', {
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

Future<int> postRegionalManagerAssignTeamLeader({
  required int teamLeaderId,
  required int productId,
  required List<int> productListIds,
}) async {
  final res = await apiPost('/regional-manager/assign-team-leader', {
    'team_leader_id': teamLeaderId,
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

Future<List<Map<String, dynamic>>> getRegionalManagerReturnProducts() async {
  final res = await apiGet('/regional-manager/return-devices/form-data');
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

Future<List<Map<String, dynamic>>> getRegionalManagerReturnableImeis(int productId) async {
  final res = await apiGet('/regional-manager/return-devices/assignable-imeis?product_id=$productId');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load devices');
  }
  final list = map?['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

Future<int> postRegionalManagerReturnDevices({
  required int productId,
  required List<int> productListIds,
}) async {
  final res = await apiPost('/regional-manager/return-devices', {
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
