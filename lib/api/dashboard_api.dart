import 'dart:convert';
import 'client.dart';

Future<Map<String, dynamic>> getDashboardData() async {
  final res = await apiGet('/admin/dashboard');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load dashboard data');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}
