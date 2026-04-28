import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getAdminAgentTransfers({String? status, int perPage = 50}) async {
  final q = status != null && status.isNotEmpty ? '?status=$status&per_page=$perPage' : '?per_page=$perPage';
  final res = await apiGet('/admin/agent-transfers$q');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load transfers');
  }
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<int> getPendingAdminAgentTransfersCount() async {
  final list = await getAdminAgentTransfers(status: 'pending', perPage: 200);
  return list.length;
}

Future<Map<String, dynamic>> getAdminAgentTransferDetail(int id) async {
  final res = await apiGet('/admin/agent-transfers/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load transfer');
  }
  return (data?['data'] as Map<String, dynamic>?) ?? {};
}

Future<void> approveAdminAgentTransfer(int id, {String? adminNote}) async {
  final res = await apiPost('/admin/agent-transfers/$id/approve', {
    if (adminNote != null && adminNote.trim().isNotEmpty) 'admin_note': adminNote.trim(),
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Approve failed');
  }
}

Future<void> rejectAdminAgentTransfer(int id, {String? adminNote}) async {
  final res = await apiPost('/admin/agent-transfers/$id/reject', {
    if (adminNote != null && adminNote.trim().isNotEmpty) 'admin_note': adminNote.trim(),
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Reject failed');
  }
}
