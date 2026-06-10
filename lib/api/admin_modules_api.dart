import 'dart:convert';
import 'client.dart';

Map<String, dynamic> _jsonMap(dynamic res) {
  // res is http.Response from client.dart
  final data = jsonDecode(res.body);
  if (data is Map<String, dynamic>) return data;
  return {};
}

Future<List<Map<String, dynamic>>> _list(String path) async {
  final res = await apiGet(path);
  final data = _jsonMap(res);
  if (res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Request failed');
  }
  final list = data['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

// IMEI
Future<List<Map<String, dynamic>>> searchImei(String q) async {
  final res = await apiGet('/admin/imei-search?q=${Uri.encodeQueryComponent(q)}');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Search failed');
  return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
}

Future<Map<String, dynamic>> getImeiItem(int id) async {
  final res = await apiGet('/admin/imei-items/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Not found');
  return data['data'] as Map<String, dynamic>? ?? {};
}

/// All IMEI devices registered in one stock bucket.
Future<Map<String, dynamic>> getStockItems(int stockId) async {
  final res = await apiGet('/admin/stocks/$stockId/items');
  final data = _jsonMap(res);
  if (res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Failed to load IMEIs');
  }
  final list = data['data'];
  final stock = data['stock'];
  return {
    'items': list is List
        ? list.map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[],
    'stock_name': stock is Map ? stock['name']?.toString() : null,
  };
}

// Passthrough
Future<List<Map<String, dynamic>>> getPassthroughSales() => _list('/admin/passthrough-sales');

Future<Map<String, dynamic>> getPassthroughSale(int id) async {
  final res = await apiGet('/admin/passthrough-sales/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Not found');
  return data['data'] as Map<String, dynamic>? ?? {};
}

// Agent credits (admin)
Future<Map<String, dynamic>> getAdminAgentCredits({String? period}) async {
  final res = await apiGet('/admin/agent-credits');
  final data = _jsonMap(res);
  if (res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Failed to load agent credits');
  }
  return data;
}

Future<Map<String, dynamic>> getAdminAgentCredit(int id) async {
  final res = await apiGet('/admin/agent-credits/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Not found');
  return data['data'] as Map<String, dynamic>;
}

Future<void> payAdminAgentCredit({
  required int agentCreditId,
  required String paidDate,
  required double amount,
  int? paymentOptionId,
}) async {
  final res = await apiPost('/admin/agent-credits/pay', {
    'agent_credit_id': agentCreditId,
    'paid_date': paidDate,
    'amount': amount,
    if (paymentOptionId != null) 'payment_option_id': paymentOptionId,
  });
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Payment failed');
}

// Leads report
Future<Map<String, dynamic>> getLeadsReport({String period = 'week'}) async {
  final res = await apiGet('/admin/customer-needs?period=$period');
  return _jsonMap(res);
}

// Tenant
Future<Map<String, dynamic>> getTenantProfile() async {
  final res = await apiGet('/admin/tenant');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Failed');
  return data['data'] as Map<String, dynamic>;
}

Future<void> updateTenantProfile({
  required String name,
  required String slug,
  String? brandName,
}) async {
  final res = await apiPut('/admin/tenant', {
    'name': name,
    'slug': slug,
    'brand_name': brandName,
  });
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

// Organization
Future<Map<String, dynamic>> getOrganizationTree() async {
  final res = await apiGet('/admin/organization-tree');
  final data = _jsonMap(res);
  if (res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Failed to load organization tree');
  }
  return data;
}

Future<List<Map<String, dynamic>>> getPayables() => _list('/admin/payables');
Future<List<Map<String, dynamic>>> getShopRecords() => _list('/admin/shop-records');
Future<List<Map<String, dynamic>>> getPayoutRows() => _list('/admin/payout');

Future<List<Map<String, dynamic>>> getStockReceipts(int stockId) async {
  final res = await apiGet('/admin/stocks/$stockId/receipts');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Failed');
  final list = data['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

// Products
Future<List<Map<String, dynamic>>> getProducts({int? categoryId}) async {
  final q = categoryId != null ? '?category_id=$categoryId' : '';
  return _list('/admin/products$q');
}

Future<void> createProduct({
  required int categoryId,
  required String name,
  String? description,
}) async {
  final res = await apiPost('/admin/products', {
    'category_id': categoryId,
    'name': name,
    if (description != null) 'description': description,
  });
  final data = _jsonMap(res);
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Create failed');
  }
}

Future<void> deleteProduct(int id) async {
  final res = await apiDelete('/admin/products/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Delete failed');
}

Future<List<Map<String, dynamic>>> getProductImeiList(int productId) async {
  final res = await apiGet('/admin/products/$productId/imei');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Failed');
  return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
}

// Branches CRUD
Future<void> createBranch(String name) async {
  final res = await apiPost('/admin/branches', {'name': name});
  final data = _jsonMap(res);
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Create failed');
  }
}

Future<void> updateBranch(int id, String name) async {
  final res = await apiPut('/admin/branches/$id', {'name': name});
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<void> deleteBranch(int id) async {
  final res = await apiDelete('/admin/branches/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Delete failed');
}

// Categories CRUD
Future<void> createCategory(String name) async {
  final res = await apiPost('/admin/categories', {'name': name});
  final data = _jsonMap(res);
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Create failed');
  }
}

Future<void> updateCategory(int id, String name) async {
  final res = await apiPut('/admin/categories/$id', {'name': name});
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<void> deleteCategory(int id) async {
  final res = await apiDelete('/admin/categories/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Delete failed');
}

// Admin profile
Future<Map<String, dynamic>> getAdminProfile() async {
  final res = await apiGet('/admin/profile');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Failed');
  return data['data'] as Map<String, dynamic>;
}

Future<void> updateAdminProfile({required String name, required String email}) async {
  final res = await apiPut('/admin/profile', {'name': name, 'email': email});
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<void> updateAdminPassword({
  required String currentPassword,
  required String password,
  required String passwordConfirmation,
}) async {
  final res = await apiPut('/admin/profile/password', {
    'current_password': currentPassword,
    'password': password,
    'password_confirmation': passwordConfirmation,
  });
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<void> updateProduct(int id, {required String name, String? description}) async {
  final res = await apiPut('/admin/products/$id', {
    'name': name,
    if (description != null) 'description': description,
  });
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<void> bulkSelcomPayout() async {
  final res = await apiPost('/admin/payout/bulk-selcom', {});
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Payout failed');
}

Future<void> updateAdminAgentCredit(int id, Map<String, dynamic> body) async {
  final res = await apiPut('/admin/agent-credits/$id', body);
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<void> deleteAdminAgentCredit(int id) async {
  final res = await apiDelete('/admin/agent-credits/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Delete failed');
}

Future<void> payRemainingAdminAgentCredit(int id) async {
  final res = await apiPost('/admin/agent-credits/$id/pay-remaining', {});
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Payment failed');
}

Future<List<Map<String, dynamic>>> getRegions() => _list('/admin/regions');

Future<void> createRegion(String name) async {
  final res = await apiPost('/admin/regions', {'name': name});
  final data = _jsonMap(res);
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Create failed');
  }
}

Future<void> updateRegion(int id, String name) async {
  final res = await apiPut('/admin/regions/$id', {'name': name});
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Update failed');
}

Future<void> deleteRegion(int id) async {
  final res = await apiDelete('/admin/regions/$id');
  final data = _jsonMap(res);
  if (res.statusCode != 200) throw Exception(data['message']?.toString() ?? 'Delete failed');
}

Future<Map<String, dynamic>> subscribeTenant(String packageSlug, String paymentPhone) async {
  final res = await apiPost('/admin/tenant/subscribe/$packageSlug', {
    'payment_phone': paymentPhone,
  });
  final data = _jsonMap(res);
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(data['message']?.toString() ?? 'Subscription failed');
  }
  return data['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getTenantSubscriptionStatus(int intentId) async {
  final res = await apiGet('/admin/tenant/subscribe/intent/$intentId/status');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to check status');
  }
  return map ?? {};
}

Future<Map<String, dynamic>> getSelcomPayoutStatus(int selcompayId) async {
  final res = await apiGet('/admin/payout/selcom/$selcompayId/status');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to check payout status');
  }
  return map ?? {};
}
