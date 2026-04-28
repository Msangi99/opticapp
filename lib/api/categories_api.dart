import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getCategories() async {
  final res = await apiGet('/admin/categories');
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Failed to load categories');
  final list = data['data'] as List<dynamic>;
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getCategoriesWithCounts() async {
  final res = await apiGet('/admin/categories?with_counts=1');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load categories');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

/// Models (catalog products) belonging to a category. Uses `GET /admin/categories/{id}/models`.
Future<List<Map<String, dynamic>>> getCategoryModels(int categoryId) async {
  final res = await apiGet('/admin/categories/$categoryId/models');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode == 404) {
    throw Exception(data?['message']?.toString() ?? 'Category not found');
  }
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load models');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}
