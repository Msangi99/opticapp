import 'dart:convert';
import 'client.dart';

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

List<Map<String, dynamic>> _stocksFromPurchases(List<Map<String, dynamic>> purchases) {
  return purchases.map((p) {
    final limit = _parseInt(p['quantity'] ?? p['limit']) ?? 0;
    final added = _parseInt(p['added']) ?? 0;
    final complete = limit > 0 && added >= limit;
    return {
      'id': p['id'],
      'name': p['name']?.toString() ?? 'Purchase #${p['id']}',
      'stock_limit': limit,
      'stock_quantity': limit,
      'quantity': added,
      'added': added,
      'under_limit': !complete,
      'status': complete ? 'complete' : 'pending',
      'from_purchase': true,
    };
  }).toList();
}

Future<List<Map<String, dynamic>>> getStocks() async {
  final res = await apiGet('/admin/stocks');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load stocks');
  final list = data?['data'];
  if (list is List && list.isNotEmpty) {
    return list.cast<Map<String, dynamic>>();
  }

  // Mirror web admin: when Stock records are empty, rows come from stock purchases.
  final purchasesRes = await apiGet('/admin/purchases');
  final purchasesData = jsonDecode(purchasesRes.body) as Map<String, dynamic>?;
  if (purchasesRes.statusCode != 200) {
    throw Exception(purchasesData?['message']?.toString() ?? 'Failed to load stocks');
  }
  final purchases = purchasesData?['data'];
  if (purchases is! List || purchases.isEmpty) return [];
  return _stocksFromPurchases(purchases.cast<Map<String, dynamic>>());
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

Future<Map<String, dynamic>> getStockDetail(int id) async {
  final res = await apiGet('/admin/stocks/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getStockItems(int stockId) async {
  final res = await apiGet('/admin/stocks/$stockId/items');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load IMEIs');
  final list = data?['data'];
  final stock = data?['stock'] as Map<String, dynamic>?;
  return {
    'items': list is List ? list.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[],
    'stock_name': stock?['name'],
  };
}
