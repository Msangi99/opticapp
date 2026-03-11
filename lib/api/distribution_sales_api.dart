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
