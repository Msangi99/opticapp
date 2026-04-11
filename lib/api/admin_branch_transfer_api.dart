import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getBranchTransferItems({
  int? branchId,
  bool unassigned = false,
}) async {
  final params = <String, String>{};
  if (unassigned) {
    params['unassigned'] = '1';
  } else if (branchId != null) {
    params['branch_id'] = '$branchId';
  } else {
    throw Exception('Select a branch or unassigned');
  }
  final q = params.entries.map((e) => '${e.key}=${e.value}').join('&');
  final res = await apiGet('/admin/branch-transfer/items?$q');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load devices');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<void> postBranchTransfer({
  required int toBranchId,
  int? fromBranchId,
  required bool unassigned,
  required List<int> productListIds,
}) async {
  final body = <String, dynamic>{
    'to_branch_id': toBranchId,
    'product_list_ids': productListIds,
    'unassigned': unassigned,
  };
  if (!unassigned && fromBranchId != null) {
    body['from_branch_id'] = fromBranchId;
  }
  final res = await apiPost('/admin/branch-transfer', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Transfer failed');
  }
}

Future<List<Map<String, dynamic>>> getBranchTransferLogs() async {
  final res = await apiGet('/admin/branch-transfer/logs?per_page=50');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load logs');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}
