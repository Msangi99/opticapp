import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Default API root when no custom URL is saved (full path including `/api`).
const String kInternalApiBaseUrl = 'https://opticedgeafrica.net/api';

const String _prefsKeyApiBaseUrlOverride = 'api_base_url_override';

String _normalizeApiBaseUrl(String url) {
  var s = url.trim();
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// Tenant subdomains like optic-edge-africa.opticedgeafrica.net are no longer used.
bool isLegacyTenantApiBaseUrl(String url) {
  final uri = Uri.tryParse(_normalizeApiBaseUrl(url));
  final host = uri?.host ?? '';
  if (host.isEmpty || host == 'opticedgeafrica.net') return false;
  return host.endsWith('.opticedgeafrica.net');
}

/// Resolved URL used for every request: saved override if non-empty, otherwise [kInternalApiBaseUrl].
Future<String> resolveBaseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_prefsKeyApiBaseUrlOverride);
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return kInternalApiBaseUrl;
  final normalized = _normalizeApiBaseUrl(trimmed);
  if (isLegacyTenantApiBaseUrl(normalized)) {
    await prefs.remove(_prefsKeyApiBaseUrlOverride);
    return kInternalApiBaseUrl;
  }
  return normalized;
}

/// Clears override when [url] is null or blank so [kInternalApiBaseUrl] is used.
Future<void> setApiBaseUrlOverride(String? url) async {
  final prefs = await SharedPreferences.getInstance();
  final t = url?.trim();
  if (t == null || t.isEmpty) {
    await prefs.remove(_prefsKeyApiBaseUrlOverride);
  } else {
    await prefs.setString(_prefsKeyApiBaseUrlOverride, _normalizeApiBaseUrl(t));
  }
}

Future<String?> getApiBaseUrlOverride() async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getString(_prefsKeyApiBaseUrlOverride);
  if (s == null || s.trim().isEmpty) return null;
  return _normalizeApiBaseUrl(s);
}

Future<String?> getStoredToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Future<void> setStoredToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}

Future<void> clearStoredAuth() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  await prefs.remove('user');
  await prefs.remove(_prefsKeyApiBaseUrlOverride);
}

Future<Map<String, dynamic>?> getStoredUser() async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getString('user');
  if (s == null) return null;
  try {
    return jsonDecode(s) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Future<void> setStoredUser(Map<String, dynamic> user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user', jsonEncode(user));
}

Future<http.Response> apiGet(String path, {String? token}) async {
  final base = await resolveBaseUrl();
  final t = token ?? await getStoredToken();
  return http.get(
    Uri.parse('$base$path'),
    headers: {
      'Accept': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    },
  );
}

Future<http.Response> apiPost(String path, Map<String, dynamic> body, {String? token}) async {
  final base = await resolveBaseUrl();
  final t = token ?? await getStoredToken();
  return http.post(
    Uri.parse('$base$path'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    },
    body: jsonEncode(body),
  );
}

Future<http.Response> apiPut(String path, Map<String, dynamic> body, {String? token}) async {
  final base = await resolveBaseUrl();
  final t = token ?? await getStoredToken();
  return http.put(
    Uri.parse('$base$path'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    },
    body: jsonEncode(body),
  );
}

Future<http.Response> apiDelete(String path, {String? token}) async {
  final base = await resolveBaseUrl();
  final t = token ?? await getStoredToken();
  return http.delete(
    Uri.parse('$base$path'),
    headers: {
      'Accept': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    },
  );
}

Future<http.Response> apiPatch(String path, Map<String, dynamic> body, {String? token}) async {
  final base = await resolveBaseUrl();
  final t = token ?? await getStoredToken();
  return http.patch(
    Uri.parse('$base$path'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    },
    body: jsonEncode(body),
  );
}
