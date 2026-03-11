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
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}
