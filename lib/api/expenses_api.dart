import 'dart:convert';
import 'package:http/http.dart' as http;
import 'client.dart';

/// List all expenses for admin.
Future<List<Map<String, dynamic>>> getExpenses() async {
  final res = await apiGet('/admin/expenses');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load expenses');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<Map<String, dynamic>> getExpense(int id) async {
  final res = await apiGet('/admin/expenses/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load expense');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> createExpense({
  required String activity,
  required double amount,
  required int paymentOptionId,
  required String date,
}) async {
  final res = await apiPost('/admin/expenses', {
    'activity': activity,
    'amount': amount,
    'payment_option_id': paymentOptionId,
    'date': date,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to create expense');
  }
}

Future<void> updateExpense({
  required int id,
  required String activity,
  required double amount,
  required int paymentOptionId,
  required String date,
}) async {
  final res = await apiPut('/admin/expenses/$id', {
    'activity': activity,
    'amount': amount,
    'payment_option_id': paymentOptionId,
    'date': date,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to update expense');
  }
}

Future<void> deleteExpense(int id) async {
  final token = await getStoredToken();
  final uri = Uri.parse('$baseUrl/admin/expenses/$id');
  final res = await http.delete(
    uri,
    headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to delete expense');
  }
}
