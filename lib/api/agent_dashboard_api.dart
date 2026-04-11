import 'dart:convert';
import 'client.dart';

/// Get agent dashboard data: assignments, stats, and recent sales.
Future<Map<String, dynamic>> getAgentDashboardData() async {
  final res = await apiGet('/agent/dashboard');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load dashboard data');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

/// IMEI-level lists for overview cards: `assigned`, `remaining`, `sold`.
Future<Map<String, dynamic>> getAgentDashboardInventory() async {
  final res = await apiGet('/agent/dashboard/inventory');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load inventory');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

/// Devices assigned to this agent (admin) that are still unsold.
Future<List<Map<String, dynamic>>> getAvailableProducts() async {
  final res = await apiGet('/agent/product-list/available');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load available products');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}
