import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
  final res = await apiGet('/admin/users?role=$role');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load users');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getCustomers() => getUsersByRole('customer');
Future<List<Map<String, dynamic>>> getDealers() => getUsersByRole('dealer');
Future<List<Map<String, dynamic>>> getAgents() => getUsersByRole('agent');
