import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getOrders() async {
  final res = await apiGet('/admin/orders');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load orders');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<int> getPendingOrdersCount() async {
  final list = await getOrders();
  return list.where((o) => (o['status']?.toString().toLowerCase() ?? '') == 'pending').length;
}

Future<Map<String, dynamic>> getOrder(int orderId) async {
  final res = await apiGet('/admin/orders/$orderId');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode == 404) {
    throw Exception(data?['message']?.toString() ?? 'Order not found');
  }
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load order');
  }
  final payload = data?['data'];
  if (payload is! Map) {
    throw Exception('Invalid order response');
  }
  return Map<String, dynamic>.from(payload);
}
