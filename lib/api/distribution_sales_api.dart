import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getDistributionSales() async {
  final res = await apiGet('/admin/distribution-sales');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load distribution sales');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<Map<String, dynamic>> getDistributionSaleDetails(int id) async {
  final res = await apiGet('/admin/distribution-sales/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load distribution details');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> createDistributionSale(Map<String, dynamic> body) async {
  final res = await apiPost('/admin/distribution-sales', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(data?['message']?.toString() ?? 'Create failed');
  }
}

Future<void> updateDistributionSale(int id, Map<String, dynamic> body) async {
  final res = await apiPut('/admin/distribution-sales/$id', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Update failed');
}

Future<void> deleteDistributionSale(int id) async {
  final res = await apiDelete('/admin/distribution-sales/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Delete failed');
}

Future<Map<String, dynamic>> getDistributionFormData() async {
  final res = await apiGet('/admin/distribution-sales/form-data');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<List<Map<String, dynamic>>> getDistributionModelsForPurchase(int purchaseId) async {
  final res = await apiGet('/admin/distribution-sales/purchases/$purchaseId/models');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  return (data?['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
}

Future<List<Map<String, dynamic>>> getDistributionAssignableImeis({
  required int purchaseId,
  required int productId,
}) async {
  final res = await apiGet('/admin/distribution-sales/assignable-imeis?purchase_id=$purchaseId&product_id=$productId');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  return (data?['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
}

Future<void> registerDistributionImeis({
  required int purchaseId,
  required int catalogProductId,
  required String imeiNumbers,
}) async {
  final res = await apiPost('/admin/distribution-sales/register-imeis', {
    'purchase_id': purchaseId,
    'catalog_product_id': catalogProductId,
    'imei_numbers': imeiNumbers,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Register failed');
}
