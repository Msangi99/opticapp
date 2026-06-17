import 'dart:convert';
import 'client.dart';

String _prefix(String apiPrefix) =>
    apiPrefix == 'team-leader' ? '/team-leader' : '/agent';

Future<List<Map<String, dynamic>>> getRecordSaleAvailableProducts(
  String apiPrefix,
) async {
  final res = await apiGet('${_prefix(apiPrefix)}/product-list/available');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load available products');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<Map<String, dynamic>> getRecordSaleDeviceByImei(
  String apiPrefix,
  String imei,
) async {
  final path =
      '${_prefix(apiPrefix)}/product-list/by-imei/${Uri.encodeComponent(imei)}';
  final res = await apiGet(path);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Device not found');
  }
  return data['data'] as Map<String, dynamic>;
}

Future<Map<String, dynamic>> getRecordSaleConfig(String apiPrefix) async {
  final res = await apiGet('${_prefix(apiPrefix)}/sale-config');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load sale config');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> sellRecordSaleCredit({
  required String apiPrefix,
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
  final res = await apiPost('${_prefix(apiPrefix)}/sell-credit', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201) {
    throw Exception(data['message']?.toString() ?? 'Credit sale failed');
  }
  return data['data'] as Map<String, dynamic>;
}

Future<List<Map<String, dynamic>>> getRecordSaleCategories(
  String apiPrefix,
) async {
  final res = await apiGet('${_prefix(apiPrefix)}/catalog/categories');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load categories');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getRecordSaleBranches(
  String apiPrefix,
) async {
  final res = await apiGet('${_prefix(apiPrefix)}/branches');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load branches');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getRecordSaleProductsInCategory(
  String apiPrefix,
  int categoryId,
) async {
  final res =
      await apiGet('${_prefix(apiPrefix)}/catalog/categories/$categoryId/products');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load products');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<void> submitRecordSaleCustomerNeed({
  required String apiPrefix,
  required int categoryId,
  required int productId,
  required String customerName,
  required String customerPhone,
  int? branchId,
}) async {
  final body = <String, dynamic>{
    'category_id': categoryId,
    'product_id': productId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
  };
  if (branchId != null) body['branch_id'] = branchId;
  final res = await apiPost('${_prefix(apiPrefix)}/customer-needs', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201) {
    throw Exception(data['message']?.toString() ?? 'Submit failed');
  }
}

Future<List<Map<String, dynamic>>> getRecordSaleCustomerNeeds(
  String apiPrefix,
) async {
  final res = await apiGet('${_prefix(apiPrefix)}/customer-needs');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load leads');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<Map<String, dynamic>> getRecordSaleCustomerNeedDetail(
  String apiPrefix,
  int id,
) async {
  final res = await apiGet('${_prefix(apiPrefix)}/customer-needs/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load lead detail');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<List<Map<String, dynamic>>> getRecordSaleCredits(String apiPrefix) async {
  final res = await apiGet('${_prefix(apiPrefix)}/credits');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load credits');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<Map<String, dynamic>> getRecordSaleCreditDetail(
  String apiPrefix,
  int id,
) async {
  final res = await apiGet('${_prefix(apiPrefix)}/credits/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load credit detail');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}
