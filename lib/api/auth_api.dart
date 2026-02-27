import 'dart:convert';
import 'client.dart';

Future<Map<String, dynamic>> login(String email, String password) async {
  final res = await apiPost('/login', {'email': email, 'password': password}, token: null);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    final msg = data['message'] ?? data['errors']?.toString() ?? 'Login failed';
    throw Exception(msg.toString());
  }
  final token = data['token'] as String;
  final user = data['user'] as Map<String, dynamic>;
  await setStoredToken(token);
  await setStoredUser(user);
  return user;
}
