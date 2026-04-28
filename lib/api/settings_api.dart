import 'dart:convert';
import 'client.dart';

Future<Map<String, dynamic>> getSettings() async {
  final res = await apiGet('/admin/settings');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to load settings');
  final inner = data?['data'];
  if (inner is Map) return Map<String, dynamic>.from(inner as Map);
  return {};
}

Future<Map<String, dynamic>> updateSettings(Map<String, String> settings) async {
  final res = await apiPut('/admin/settings', {'settings': settings});
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) throw Exception(data?['message']?.toString() ?? 'Failed to update settings');
  final inner = data?['data'];
  if (inner is Map) return Map<String, dynamic>.from(inner as Map);
  return {};
}

Future<Map<String, dynamic>> getSettingsRoles() async {
  final res = await apiGet('/admin/settings/roles');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load roles');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> createSettingsRole({
  required String name,
  String? description,
}) async {
  final res = await apiPost('/admin/settings/roles', {
    'name': name,
    if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to create role');
  }
}

Future<List<String>> getRolePermissions(int roleId) async {
  final res = await apiGet('/admin/settings/roles/$roleId/permissions');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to load role permissions');
  }
  final payload = data?['data'] as Map<String, dynamic>? ?? {};
  final list = payload['granted'];
  if (list is! List) return [];
  return list.map((e) => e.toString()).toList();
}

Future<void> updateRolePermissions({
  required int roleId,
  required List<String> permissions,
}) async {
  final res = await apiPut('/admin/settings/roles/$roleId/permissions', {
    'permissions': permissions,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Failed to update permissions');
  }
}
