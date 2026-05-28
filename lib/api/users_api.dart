import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
  final res = await apiGet('/admin/users?role=$role');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load users');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return (list as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getCustomers() => getUsersByRole('customer');
Future<List<Map<String, dynamic>>> getDealers() => getUsersByRole('dealer');
Future<List<Map<String, dynamic>>> getAgents() => getUsersByRole('agent');
Future<List<Map<String, dynamic>>> getTeamLeaders() => getUsersByRole('teamleader');
Future<List<Map<String, dynamic>>> getRegionalManagers() => getUsersByRole('regional_manager');
Future<List<Map<String, dynamic>>> getSubadmins() => getUsersByRole('subadmin');

Future<Map<String, dynamic>> getUserDetail(int id) async {
  final res = await apiGet('/admin/users/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> activateUser(int id) async {
  final res = await apiPost('/admin/users/$id/activate', {});
  _checkUserAction(res);
}

Future<void> deactivateUser(int id) async {
  final res = await apiPost('/admin/users/$id/deactivate', {});
  _checkUserAction(res);
}

Future<void> approveDealer(int id) async {
  final res = await apiPost('/admin/users/$id/approve-dealer', {});
  _checkUserAction(res);
}

Future<void> rejectDealer(int id) async {
  final res = await apiPost('/admin/users/$id/reject-dealer', {});
  _checkUserAction(res);
}

void _checkUserAction(dynamic res) {
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Action failed');
  }
}
