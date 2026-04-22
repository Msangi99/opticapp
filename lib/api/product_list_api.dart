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

/// Add many IMEIs for one purchase (from barcode photos, etc.).
Future<Map<String, dynamic>> addProductBatchByPurchase({
  required int purchaseId,
  required List<String> imeiNumbers,
}) async {
  final res = await apiPost('/admin/product-list/batch', {
    'purchase_id': purchaseId,
    'imei_numbers': imeiNumbers,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Failed to add products');
  }
  return data;
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
  int? paymentOptionId,
}) async {
  final body = <String, dynamic>{
    'product_list_id': productListId,
    'customer_name': customerName,
    'selling_price': sellingPrice,
  };
  if (paymentOptionId != null) {
    body['payment_option_id'] = paymentOptionId;
  }
  final res = await apiPost('/agent/sell', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201) throw Exception(data['message']?.toString() ?? 'Sale failed');
  return data['data'] as Map<String, dynamic>;
}

/// Credit sale (full amount on credit). Optional [customerPhone], [description].
Future<Map<String, dynamic>> sellDeviceCredit({
  required int productListId,
  required String customerName,
  required double sellingPrice,
  String? customerPhone,
  String? kinName,
  String? kinPhone,
  String? description,
}) async {
  final body = <String, dynamic>{
    'product_list_id': productListId,
    'customer_name': customerName,
    'selling_price': sellingPrice,
    'down_payment': 0,
  };
  if (customerPhone != null && customerPhone.trim().isNotEmpty) {
    body['customer_phone'] = customerPhone.trim();
  }
  if (kinName != null && kinName.trim().isNotEmpty) {
    body['kin_name'] = kinName.trim();
  }
  if (kinPhone != null && kinPhone.trim().isNotEmpty) {
    body['kin_phone'] = kinPhone.trim();
  }
  if (description != null && description.trim().isNotEmpty) {
    body['description'] = description.trim();
  }
  final res = await apiPost('/agent/sell-credit', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201) {
    throw Exception(data['message']?.toString() ?? 'Credit sale failed');
  }
  return data['data'] as Map<String, dynamic>;
}
