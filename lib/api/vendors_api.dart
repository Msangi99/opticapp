import 'dart:convert';
import 'client.dart';

List<Map<String, dynamic>> _parseList(dynamic res) {
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Request failed');
  }
  final list = data?['data'];
  if (list is! List) return [];
  return list.cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> getVendors() async {
  final res = await apiGet('/admin/vendors');
  return _parseList(res);
}

Future<Map<String, dynamic>> getVendor(int id) async {
  final res = await apiGet('/admin/vendors/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Not found');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> createVendor({
  required String name,
  String? phone,
  String? email,
  String? officeName,
  String? location,
}) async {
  final res = await apiPost('/admin/vendors', {
    'name': name,
    if (phone != null && phone.isNotEmpty) 'phone': phone,
    if (email != null && email.isNotEmpty) 'email': email,
    if (officeName != null && officeName.isNotEmpty) 'office_name': officeName,
    if (location != null && location.isNotEmpty) 'location': location,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Create failed');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> updateVendor({
  required int id,
  required String name,
  String? phone,
  String? email,
  String? officeName,
  String? location,
}) async {
  final res = await apiPut('/admin/vendors/$id', {
    'name': name,
    'phone': phone,
    'email': email,
    'office_name': officeName,
    'location': location,
  });
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Update failed');
  }
  return data?['data'] as Map<String, dynamic>? ?? {};
}

Future<void> deleteVendor(int id) async {
  final res = await apiDelete('/admin/vendors/$id');
  final data = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(data?['message']?.toString() ?? 'Delete failed');
  }
}
