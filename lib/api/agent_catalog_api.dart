import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getAgentCategories() async {
  final res = await apiGet('/agent/catalog/categories');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load categories');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getAgentProductsInCategory(int categoryId) async {
  final res = await apiGet('/agent/catalog/categories/$categoryId/products');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load products');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<void> submitAgentCustomerNeed({
  required int categoryId,
  required int productId,
}) async {
  final res = await apiPost('/agent/customer-needs', {
    'category_id': categoryId,
    'product_id': productId,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201) {
    throw Exception(data['message']?.toString() ?? 'Submit failed');
  }
}
