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

Future<Map<String, dynamic>> getPaymentOptionDetail(int id) async {
  final res = await apiGet('/admin/payment-options/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load payment option');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> createPaymentOption({
  required String type,
  required String name,
}) async {
  final res = await apiPost('/admin/payment-options', {
    'type': type,
    'name': name,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to create payment option');
  }
}

Future<void> updatePaymentOption({
  required int id,
  required String type,
  required String name,
  double? addAmount,
}) async {
  final res = await apiPut('/admin/payment-options/$id', {
    'type': type,
    'name': name,
    if (addAmount != null) 'add_amount': addAmount,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to update payment option');
  }
}

Future<void> deletePaymentOption(int id) async {
  final res = await apiDelete('/admin/payment-options/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to delete payment option');
  }
}

Future<void> shrinkPaymentOptionBalance({
  required int id,
  required double shrinkAmount,
}) async {
  final res = await apiPatch('/admin/payment-options/$id/shrink-balance', {
    'shrink_amount': shrinkAmount,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to shrink balance');
  }
}

Future<void> togglePaymentOptionVisibility(int id) async {
  final res = await apiPatch('/admin/payment-options/$id/toggle-visibility', {});
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to update visibility');
  }
}

Future<void> createPaymentTransfer({
  required int fromChannelId,
  required int toChannelId,
  required double amount,
  String? description,
}) async {
  final res = await apiPost('/admin/payment-options/transfers', {
    'from_channel_id': fromChannelId,
    'to_channel_id': toChannelId,
    'amount': amount,
    if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to create transfer');
  }
}

Future<List<Map<String, dynamic>>> getPaymentTransferHistory({
  String? fromDate,
  String? toDate,
}) async {
  final q = <String>[];
  if (fromDate != null && fromDate.isNotEmpty) q.add('from_date=$fromDate');
  if (toDate != null && toDate.isNotEmpty) q.add('to_date=$toDate');
  final suffix = q.isEmpty ? '' : '?${q.join('&')}';
  final res = await apiGet('/admin/payment-options/transfers/history$suffix');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load transfer history');
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
