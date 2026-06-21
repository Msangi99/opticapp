import 'dart:convert';
import 'client.dart';

Future<List<Map<String, dynamic>>> getUsersByRole(
  String? role, {
  String? sort,
  String? direction,
}) async {
  final params = <String, String>{};
  if (role != null && role.isNotEmpty) params['role'] = role;
  if (sort != null && sort.isNotEmpty) params['sort'] = sort;
  if (direction != null && direction.isNotEmpty) params['direction'] = direction;
  final query = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
  final res = await apiGet('/admin/users$query');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load users');
  final list = data?['data'];
  if (list == null || list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getAllUsers({
  String? sort,
  String? direction,
}) =>
    getUsersByRole(null, sort: sort, direction: direction);

Future<List<Map<String, dynamic>>> getCustomers({
  String? sort,
  String? direction,
}) =>
    getUsersByRole('customer', sort: sort, direction: direction);

Future<List<Map<String, dynamic>>> getDealers({
  String? sort,
  String? direction,
}) =>
    getUsersByRole('dealer', sort: sort, direction: direction);

Future<List<Map<String, dynamic>>> getAgents({
  String? sort,
  String? direction,
}) =>
    getUsersByRole('agent', sort: sort, direction: direction);

Future<List<Map<String, dynamic>>> getTeamLeaders({
  String? sort,
  String? direction,
}) =>
    getUsersByRole('teamleader', sort: sort, direction: direction);

Future<List<Map<String, dynamic>>> getRegionalManagers({
  String? sort,
  String? direction,
}) =>
    getUsersByRole('regional_manager', sort: sort, direction: direction);

Future<List<Map<String, dynamic>>> getSubadmins({
  String? sort,
  String? direction,
}) =>
    getUsersByRole('subadmin', sort: sort, direction: direction);

Future<Map<String, dynamic>> getUserDetail(int id) async {
  final res = await apiGet('/admin/users/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getUserCreateFormData(String role) async {
  final res = await apiGet('/admin/users/create-form-data?role=$role');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load form');
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<List<Map<String, dynamic>>> getSubadminRoles() async {
  final res = await apiGet('/admin/subadmin-roles');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  final list = data?['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

Future<Map<String, dynamic>> createUser(Map<String, dynamic> payload) async {
  final res = await apiPost('/admin/users', payload);
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Create failed');
  }
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

Future<void> resetUserPassword(int id, String password, String passwordConfirmation) async {
  final res = await apiPost('/admin/users/$id/reset-password', {
    'password': password,
    'password_confirmation': passwordConfirmation,
  });
  _checkUserAction(res);
}

Future<void> deleteUser(int id) async {
  final res = await apiDelete('/admin/users/$id');
  _checkUserAction(res);
}

Future<void> transferAgentBranch(int userId, int? branchId) async {
  final res = await apiPost('/admin/users/$userId/transfer-branch', {
    if (branchId != null) 'branch_id': branchId,
  });
  _checkUserAction(res);
}

Future<void> updateAgentTeamLeader(int userId, int? teamLeaderId) async {
  final res = await apiPut('/admin/users/$userId/team-leader', {
    if (teamLeaderId != null) 'team_leader_id': teamLeaderId,
  });
  _checkUserAction(res);
}

Future<Map<String, dynamic>> getMyPermissions() async {
  final res = await apiGet('/admin/users/my-permissions');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getAssignDevicesFormData() async {
  final res = await apiGet('/admin/regional-managers/assign-devices/form-data');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<List<Map<String, dynamic>>> getAssignDevicesModels(int purchaseId) async {
  final res = await apiGet('/admin/regional-managers/assign-devices/purchases/$purchaseId/models');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  final list = data?['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

Future<Map<String, dynamic>> getAssignDevicesImeis({
  required int purchaseId,
  required int productId,
}) async {
  final res = await apiGet(
    '/admin/regional-managers/assign-devices/assignable-imeis?purchase_id=$purchaseId&product_id=$productId',
  );
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed');
  return data ?? {};
}

Future<void> storeAssignDevices({
  required int regionalManagerId,
  required int purchaseId,
  required int productId,
  required List<int> productListIds,
}) async {
  final res = await apiPost('/admin/regional-managers/assign-devices', {
    'regional_manager_id': regionalManagerId,
    'purchase_id': purchaseId,
    'product_id': productId,
    'product_list_ids': productListIds,
  });
  _checkUserAction(res);
}

void _checkUserAction(dynamic res) {
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(data?['message']?.toString() ?? 'Action failed');
  }
}
