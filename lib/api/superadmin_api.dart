import 'dart:convert';

import 'client.dart';

Future<Map<String, dynamic>> getSuperadminDashboard() async {
  final res = await apiGet('/superadmin/dashboard');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load dashboard');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getSuperadminTenants({int page = 1, int perPage = 20}) async {
  final res = await apiGet('/superadmin/tenants?page=$page&per_page=$perPage');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load vendors');
  }
  return map ?? {};
}

Future<Map<String, dynamic>> getSuperadminTenant(int id) async {
  final res = await apiGet('/superadmin/tenants/$id');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load vendor');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<List<Map<String, dynamic>>> getSuperadminTenantFormData() async {
  final res = await apiGet('/superadmin/tenants/form-data');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load form data');
  }
  final data = map?['data'];
  if (data is Map<String, dynamic>) {
    final list = data['packages'];
    if (list is List) return list.cast<Map<String, dynamic>>();
  }
  return [];
}

Future<Map<String, dynamic>> createSuperadminTenant(Map<String, dynamic> body) async {
  final res = await apiPost('/superadmin/tenants', body);
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> updateSuperadminTenant(int id, Map<String, dynamic> body) async {
  final res = await apiPut('/superadmin/tenants/$id', body);
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> suspendSuperadminTenant(int id) async {
  final res = await apiPost('/superadmin/tenants/$id/suspend', {});
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to suspend vendor');
  }
}

Future<List<Map<String, dynamic>>> getSuperadminPackages() async {
  final res = await apiGet('/superadmin/packages');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load packages');
  }
  final list = map?['data'];
  if (list is List) return list.cast<Map<String, dynamic>>();
  return [];
}

Future<Map<String, dynamic>> createSuperadminPackage(Map<String, dynamic> body) async {
  final res = await apiPost('/superadmin/packages', body);
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> updateSuperadminPackage(int id, Map<String, dynamic> body) async {
  final res = await apiPut('/superadmin/packages/$id', body);
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> deleteSuperadminPackage(int id) async {
  final res = await apiDelete('/superadmin/packages/$id');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to delete package');
  }
}

Future<Map<String, dynamic>> getSuperadminSubscriptionProfits() async {
  final res = await apiGet('/superadmin/subscription-profits');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load subscription data');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getSuperadminCommandCenter() async {
  final res = await apiGet('/superadmin/command-center');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load command center');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<String> executeSuperadminCommand({
  required String command,
  bool force = false,
  bool seed = false,
}) async {
  final res = await apiPost('/superadmin/command-center/execute', {
    'command': command,
    'force': force,
    'seed': seed,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Command failed');
  }
  return map?['message']?.toString() ?? 'Command finished.';
}

Future<String> migrateSuperadminPath(String migration) async {
  final res = await apiPost('/superadmin/command-center/migrate-path', {'migration': migration});
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Migration failed');
  }
  return map?['message']?.toString() ?? 'Migration finished.';
}

Future<String> seedSuperadminClass(String seederClass, {bool force = false}) async {
  final res = await apiPost('/superadmin/command-center/seed-class', {
    'seeder_class': seederClass,
    'force': force,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Seeder failed');
  }
  return map?['message']?.toString() ?? 'Seeder finished.';
}

Future<String> emptySuperadminTable(String table) async {
  final res = await apiPost('/superadmin/command-center/empty-table', {'table': table});
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Empty table failed');
  }
  return map?['message']?.toString() ?? 'Table emptied.';
}

Future<List<Map<String, dynamic>>> getSuperadminRegions({int page = 1}) async {
  final res = await apiGet('/superadmin/regions?page=$page');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load regions');
  }
  final list = map?['data'];
  if (list is List) return list.cast<Map<String, dynamic>>();
  return [];
}

Future<Map<String, dynamic>> createSuperadminRegion(String name) async {
  final res = await apiPost('/superadmin/regions', {'name': name});
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> updateSuperadminRegion(int id, String name) async {
  final res = await apiPut('/superadmin/regions/$id', {'name': name});
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> deleteSuperadminRegion(int id) async {
  final res = await apiDelete('/superadmin/regions/$id');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to delete region');
  }
}

Future<List<Map<String, dynamic>>> getSuperadminBrands({int page = 1}) async {
  final res = await apiGet('/superadmin/brands?page=$page');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load brands');
  }
  final list = map?['data'];
  if (list is List) return list.cast<Map<String, dynamic>>();
  return [];
}

Future<Map<String, dynamic>> createSuperadminBrand(String name) async {
  final res = await apiPost('/superadmin/brands', {'name': name});
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> updateSuperadminBrand(int id, String name) async {
  final res = await apiPut('/superadmin/brands/$id', {'name': name});
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> deleteSuperadminBrand(int id) async {
  final res = await apiDelete('/superadmin/brands/$id');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to delete brand');
  }
}

Future<List<Map<String, dynamic>>> getSuperadminModels({String? search, int page = 1}) async {
  final q = search != null && search.trim().isNotEmpty ? '&search=${Uri.encodeQueryComponent(search.trim())}' : '';
  final res = await apiGet('/superadmin/models?page=$page$q');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load models');
  }
  final list = map?['data'];
  if (list is List) return list.cast<Map<String, dynamic>>();
  return [];
}

Future<List<Map<String, dynamic>>> getSuperadminModelFormData() async {
  final res = await apiGet('/superadmin/models/form-data');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load brands');
  }
  final data = map?['data'];
  if (data is Map<String, dynamic>) {
    final list = data['brands'];
    if (list is List) return list.cast<Map<String, dynamic>>();
  }
  return [];
}

Future<Map<String, dynamic>> createSuperadminModel(Map<String, dynamic> body) async {
  final res = await apiPost('/superadmin/models', body);
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> updateSuperadminModel(int id, Map<String, dynamic> body) async {
  final res = await apiPut('/superadmin/models/$id', body);
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> deleteSuperadminModel(int id) async {
  final res = await apiDelete('/superadmin/models/$id');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to delete model');
  }
}

Future<Map<String, dynamic>> getSuperadminSettings() async {
  final res = await apiGet('/superadmin/settings');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load settings');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> updateSuperadminSettings(Map<String, dynamic> body) async {
  final res = await apiPut('/superadmin/settings', body);
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? res.body);
  }
}

Future<Map<String, dynamic>> testSuperadminSelcom() async {
  final res = await apiPost('/superadmin/settings/test-selcom', {});
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200 && res.statusCode != 422) {
    throw Exception(map?['message']?.toString() ?? 'Selcom test failed');
  }
  return map ?? {};
}

Future<Map<String, dynamic>> trackSuperadminExtension(String extension) async {
  final res = await apiPost('/superadmin/command-center/extension-track', {
    'extension': extension,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to track extension');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> untrackSuperadminExtension(String extension) async {
  final res = await apiPost('/superadmin/command-center/extension-untrack', {
    'extension': extension,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to untrack extension');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> runSuperadminCommand(String command, {bool force = false, bool seed = false}) async {
  final q = '?force=${force ? 1 : 0}&seed=${seed ? 1 : 0}';
  final res = await apiGet('/superadmin/command-center/run/$command$q');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Command failed');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}
