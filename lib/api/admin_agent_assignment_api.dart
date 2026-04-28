import 'dart:convert';

import 'client.dart';

Future<List<Map<String, dynamic>>> getProductsForAssign() async {
  final res = await apiGet('/admin/agents/products-for-assign');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load products');
  }
  final list = map?['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> getAssignableImeisForAgent(int productId) async {
  final res = await apiGet('/admin/agents/assignable-imeis?product_id=$productId');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load devices');
  }
  final list = map?['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

class ValidateImeiAssignResult {
  const ValidateImeiAssignResult({
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

Future<ValidateImeiAssignResult> validateImeiForAssignment({
  required int productId,
  required String imei,
}) async {
  final res = await apiPost('/admin/agents/assignments/validate-imei', {
    'product_id': productId,
    'imei': imei,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode == 200 && map?['valid'] == true) {
    final data = map!['data'];
    if (data is Map<String, dynamic>) {
      final id = data['product_list_id'];
      final int? lid = id is int ? id : (id is num ? id.toInt() : int.tryParse(id.toString()));
      return ValidateImeiAssignResult(
        ok: true,
        productListId: lid,
        imeiNumber: data['imei_number']?.toString(),
      );
    }
  }
  final msg = map?['message']?.toString() ?? 'IMEI does not match an assignable device for this product.';
  return ValidateImeiAssignResult(ok: false, message: msg);
}

Future<int> postAssignProductsToAgent({
  required int agentId,
  required int productId,
  required List<int> productListIds,
}) async {
  final res = await apiPost('/admin/agents/assignments', {
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
