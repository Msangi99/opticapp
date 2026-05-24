import 'dart:convert';
import 'client.dart';

Future<Map<String, dynamic>> getDashboardData({
  String? startDate,
  String? endDate,
}) async {
  final q = <String>[];
  if (startDate != null && startDate.isNotEmpty) q.add('start_date=$startDate');
  if (endDate != null && endDate.isNotEmpty) q.add('end_date=$endDate');
  final suffix = q.isEmpty ? '' : '?${q.join('&')}';
  final res = await apiGet('/admin/dashboard$suffix');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load dashboard data');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}
