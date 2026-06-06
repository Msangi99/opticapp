import 'dart:convert';
import 'client.dart';

Future<Map<String, dynamic>> getReports() async {
  final res = await apiGet('/admin/reports');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load reports');
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getReportBranchDetail(int branchId) async {
  final res = await apiGet('/admin/reports/branches/$branchId');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load branch report');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<String> getAgentStockExportUrl({
  String? dateFrom,
  String? dateTo,
  int? branchId,
}) async {
  final base = await resolveBaseUrl();
  final q = <String>[];
  if (dateFrom != null) q.add('date_from=$dateFrom');
  if (dateTo != null) q.add('date_to=$dateTo');
  if (branchId != null) q.add('branch_id=$branchId');
  final qs = q.isEmpty ? '' : '?${q.join('&')}';
  return '$base/admin/reports/agent-stock-export$qs';
}
