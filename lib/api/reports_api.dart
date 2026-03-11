import 'dart:convert';
import 'client.dart';

Future<Map<String, dynamic>> getReports() async {
  final res = await apiGet('/admin/reports');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load reports');
  return data?['data'] as Map<String, dynamic>? ?? {};
}
