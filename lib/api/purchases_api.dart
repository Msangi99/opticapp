import 'dart:convert';
import 'client.dart';

Map<String, dynamic> _jsonMap(dynamic res) {
  final data = jsonDecode(res.body);
  if (data is Map<String, dynamic>) return data;
  return {};
}

Future<List<Map<String, dynamic>>> getPurchases() async {
  final res = await apiGet('/admin/purchases');
  final data = _jsonMap(res);
  if (res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Failed to load purchases');
  }
  final list = data['data'];
  if (list == null || list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

Future<void> createPurchase(Map<String, dynamic> body) async {
  final res = await apiPost('/admin/purchases', body);
  final data = _jsonMap(res);
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(data['message']?.toString() ?? 'Create failed');
  }
}

Future<void> updatePurchase(int id, Map<String, dynamic> body) async {
  final res = await apiPut('/admin/purchases/$id', body);
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<void> deletePurchase(int id) async {
  final res = await apiDelete('/admin/purchases/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Delete failed');
}

Future<void> deletePurchaseItem(int purchaseId, int itemId) async {
  final res = await apiDelete('/admin/purchases/$purchaseId/items/$itemId');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Delete failed');
}

Future<void> updateAllProductPrices() async {
  final res = await apiPost('/admin/purchases/update-prices', {});
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<String> getPurchaseExportUrl({String? dateFrom, String? dateTo}) async {
  final base = await resolveBaseUrl();
  final q = <String>[];
  if (dateFrom != null) q.add('date_from=$dateFrom');
  if (dateTo != null) q.add('date_to=$dateTo');
  final qs = q.isEmpty ? '' : '?${q.join('&')}';
  return '$base/admin/purchases/export-csv$qs';
}

Future<int> downloadPurchaseCsvBytes({String? dateFrom, String? dateTo}) async {
  final q = <String>[];
  if (dateFrom != null) q.add('date_from=$dateFrom');
  if (dateTo != null) q.add('date_to=$dateTo');
  final qs = q.isEmpty ? '' : '?${q.join('&')}';
  final res = await apiGet('/admin/purchases/export-csv$qs');
  if (res.statusCode != 200) {
    final data = _jsonMap(res);
    throw Exception(data['message']?.toString() ?? 'Export failed');
  }
  return res.bodyBytes.length;
}

Future<List<Map<String, dynamic>>> getPurchaseReceipts() async {
  final res = await apiGet('/admin/purchases/receipts');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Failed');
  return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
}

Future<List<Map<String, dynamic>>> getPurchaseImagesGallery() async {
  final res = await apiGet('/admin/purchases/images-gallery');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Failed');
  return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
}

Future<void> createPassthrough(Map<String, dynamic> body) async {
  final res = await apiPost('/admin/passthrough-sales', body);
  final data = _jsonMap(res);
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(data['message']?.toString() ?? 'Create failed');
  }
}

Future<void> updatePassthrough(int id, Map<String, dynamic> body) async {
  final res = await apiPut('/admin/passthrough-sales/$id', body);
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<void> deletePassthrough(int id) async {
  final res = await apiDelete('/admin/passthrough-sales/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Delete failed');
}
