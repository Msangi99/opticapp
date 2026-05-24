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

Future<void> returnDevicesToTeamLeader(List<int> productListIds) async {
  final res = await apiPost('/agent/return-devices', {
    'product_list_ids': productListIds,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Return failed');
  }
}
