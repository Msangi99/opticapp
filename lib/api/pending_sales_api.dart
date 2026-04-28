import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getPendingSales() async {
  final res = await apiGet('/admin/pending-sales');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load pending sales');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<Map<String, dynamic>> getPendingSale(int id) async {
  final res = await apiGet('/admin/pending-sales/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load pending sale');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> savePendingSale({
  required int id,
  required int paymentOptionId,
}) async {
  final res = await apiPost('/admin/pending-sales/$id/save', {
    'payment_option_id': paymentOptionId,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to save pending sale');
  }
}
