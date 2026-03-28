import 'dart:convert';
import 'client.dart';

/// List all payment options (channels) for admin.
Future<List<Map<String, dynamic>>> getPaymentOptions() async {
  final res = await apiGet('/admin/payment-options');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load payment options');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

/// Payment channels for agents (e.g. down payment on credit sales).
Future<List<Map<String, dynamic>>> getAgentPaymentOptions() async {
  final res = await apiGet('/agent/payment-options');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load payment options');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}
