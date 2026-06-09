import 'dart:convert';
import 'client.dart';

/// List all agent sales for admin dashboard.
Future<List<Map<String, dynamic>>> getAgentSales() async {
  final res = await apiGet('/admin/agent-sales?limit=500');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load agent sales');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<void> updateAgentSaleChannel({
  required int id,
  required int paymentOptionId,
}) async {
  final res = await apiPost('/admin/agent-sales/$id/channel', {
    'payment_option_id': paymentOptionId,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to update payment channel');
  }
}

Future<void> updateAgentSaleCommission({
  required int id,
  required double commissionPaid,
}) async {
  final res = await apiPost('/admin/agent-sales/$id/commission', {
    'commission_paid': commissionPaid,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to update commission');
  }
}

Future<void> createAgentSale(Map<String, dynamic> body) async {
  final res = await apiPost('/admin/agent-sales', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(data?['message']?.toString() ?? 'Create failed');
  }
}

Future<void> convertAgentSaleToCredit(int id) async {
  final res = await apiPost('/admin/agent-sales/$id/convert-to-credit', {});
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Convert failed');
}

Future<void> deleteAgentSale(int id) async {
  final res = await apiDelete('/admin/agent-sales/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Delete failed');
}
