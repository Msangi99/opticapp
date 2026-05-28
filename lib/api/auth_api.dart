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
  // Includes tenant_id and brand_name when the user belongs to a vendor tenant.
  final user = data['user'] as Map<String, dynamic>;
  await setStoredToken(token);
  await setStoredUser(user);
  return user;
}

Future<void> registerCustomer({
  required String name,
  required String email,
  required String password,
  required String passwordConfirmation,
}) async {
  final res = await apiPost('/register', {
    'name': name,
    'email': email,
    'password': password,
    'password_confirmation': passwordConfirmation,
  }, token: null);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Registration failed');
  }
  final token = data['token'] as String?;
  final user = data['user'] as Map<String, dynamic>?;
  if (token != null && user != null) {
    await setStoredToken(token);
    await setStoredUser(user);
  }
}

Future<String> registerAgent({
  required String name,
  required String email,
  required String password,
  required String passwordConfirmation,
  String? phone,
}) async {
  final res = await apiPost('/register/agent', {
    'name': name,
    'email': email,
    'password': password,
    'password_confirmation': passwordConfirmation,
    if (phone != null && phone.isNotEmpty) 'phone': phone,
  }, token: null);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Registration failed');
  }
  return data['message']?.toString() ?? 'Registration submitted.';
}

Future<String> registerDealer({
  required String name,
  required String email,
  required String password,
  required String passwordConfirmation,
  required String businessName,
  String? phone,
}) async {
  final res = await apiPost('/register/dealer', {
    'name': name,
    'email': email,
    'password': password,
    'password_confirmation': passwordConfirmation,
    'business_name': businessName,
    if (phone != null && phone.isNotEmpty) 'phone': phone,
  }, token: null);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Registration failed');
  }
  return data['message']?.toString() ?? 'Registration submitted.';
}

Future<String> forgotPassword(String email) async {
  final res = await apiPost('/password/forgot', {'email': email}, token: null);
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(data['message']?.toString() ?? 'Request failed');
  }
  return data['message']?.toString() ?? 'Check your email for reset instructions.';
}
