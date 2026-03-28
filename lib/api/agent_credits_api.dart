import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getAgentCredits() async {
  final res = await apiGet('/agent/credits');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load credits');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

/// Record an installment payment on a credit sale.
Future<Map<String, dynamic>> payAgentCreditInstallment({
  required int agentCreditId,
  required double amount,
  required int paymentOptionId,
  String? paidDate,
}) async {
  final body = <String, dynamic>{
    'amount': amount,
    'payment_option_id': paymentOptionId,
  };
  if (paidDate != null && paidDate.isNotEmpty) body['paid_date'] = paidDate;
  final res = await apiPost('/agent/credits/$agentCreditId/pay', body);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Payment failed');
  }
  return data['data'] as Map<String, dynamic>? ?? data;
}
