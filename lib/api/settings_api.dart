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
