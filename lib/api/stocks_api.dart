import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getStocks() async {
  final res = await apiGet('/admin/stocks');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load stocks');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getStocksUnderLimit() async {
  final res = await apiGet('/admin/stocks/under-limit');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load stocks');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getModelsForStock(int stockId) async {
  final res = await apiGet('/admin/stocks/$stockId/models');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load models');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<void> createStock(String name, int stockLimit) async {
  final res = await apiPost('/admin/stocks', {'name': name, 'stock_limit': stockLimit});
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201) throw Exception(data['message']?.toString() ?? 'Failed to create stock');
}
