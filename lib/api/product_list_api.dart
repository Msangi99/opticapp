import 'dart:convert';
import 'client.dart';

/// List all purchases for Stocks page: name, limit, available (limit_status), status (payment_status).
Future<List<Map<String, dynamic>>> getPurchases() async {
  final res = await apiGet('/admin/purchases');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load purchases');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

/// List items for a purchase: model, category, imei_number.
Future<List<Map<String, dynamic>>> getPurchaseItems(int purchaseId) async {
  final res = await apiGet('/admin/purchases/$purchaseId/items');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load items');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

/// List purchases (by name) with category and model for admin Add Product.
Future<List<Map<String, dynamic>>> getPurchasesForAddProduct() async {
  final res = await apiGet('/admin/purchases/for-add-product');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load purchases');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

/// Add product by purchase (category and model from purchase).
Future<Map<String, dynamic>> addProductToListByPurchase({
  required int purchaseId,
  required String imeiNumber,
}) async {
  final res = await apiPost('/admin/product-list', {
    'purchase_id': purchaseId,
    'imei_number': imeiNumber,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201) throw Exception(data['message']?.toString() ?? 'Failed to add product');
  return data['data'] as Map<String, dynamic>;
}

Future<Map<String, dynamic>> addProductToList({
  required int stockId,
  required int categoryId,
  required String model,
  required String imeiNumber,
}) async {
  final res = await apiPost('/admin/product-list', {
    'stock_id': stockId,
    'category_id': categoryId,
    'model': model,
    'imei_number': imeiNumber,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201) throw Exception(data['message']?.toString() ?? 'Failed to add product');
  return data['data'] as Map<String, dynamic>;
}

Future<Map<String, dynamic>> getDeviceByImei(String imei) async {
  final path = '/agent/product-list/by-imei/${Uri.encodeComponent(imei)}';
  final res = await apiGet(path);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Device not found');
  return data['data'] as Map<String, dynamic>;
}

Future<Map<String, dynamic>> sellDevice({
  required int productListId,
  required String customerName,
  required double sellingPrice,
}) async {
  final res = await apiPost('/agent/sell', {
    'product_list_id': productListId,
    'customer_name': customerName,
    'selling_price': sellingPrice,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201) throw Exception(data['message']?.toString() ?? 'Sale failed');
  return data['data'] as Map<String, dynamic>;
}
