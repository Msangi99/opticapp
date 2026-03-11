import 'dart:convert';
import 'client.dart';

/// List all expenses for admin.
Future<List<Map<String, dynamic>>> getExpenses() async {
  final res = await apiGet('/admin/expenses');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load expenses');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}
