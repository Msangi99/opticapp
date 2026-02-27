import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL for Laravel API. Change for production.
const String baseUrl = 'https://opticedgeafrica.net/api'; // Android emulator -> localhost

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
  final t = token ?? await getStoredToken();
  return http.get(
    Uri.parse('$baseUrl$path'),
    headers: {
      'Accept': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    },
  );
}

Future<http.Response> apiPost(String path, Map<String, dynamic> body, {String? token}) async {
  final t = token ?? await getStoredToken();
  return http.post(
    Uri.parse('$baseUrl$path'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    },
    body: jsonEncode(body),
  );
}
