import 'dart:convert';
import 'client.dart';

/// List all agent sales for admin dashboard.
Future<List<Map<String, dynamic>>> getAgentSales() async {
  final res = await apiGet('/admin/agent-sales');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load agent sales');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}
