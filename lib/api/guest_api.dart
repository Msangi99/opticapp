import 'dart:convert';

import 'package:http/http.dart' as http;

import 'client.dart';

Future<List<dynamic>> getPublicPackages() async {
  final res = await apiGet('/public/packages', token: null);
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(map['message']?.toString() ?? 'Failed to load packages');
  }
  return map['data'] as List<dynamic>? ?? [];
}

Future<Map<String, dynamic>> createVendorSubscribeIntent({
  required String packageSlug,
  required String vendorName,
  String? brandName,
  required String adminName,
  required String email,
  required String phone,
  required String password,
  required String passwordConfirmation,
}) async {
  final res = await apiPost('/public/vendor-subscribe/intent', {
    'package_slug': packageSlug,
    'vendor_name': vendorName,
    if (brandName != null && brandName.isNotEmpty) 'brand_name': brandName,
    'admin_name': adminName,
    'email': email,
    'phone': phone,
    'password': password,
    'password_confirmation': passwordConfirmation,
  }, token: null);
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 201 && res.statusCode != 200) {
    throw Exception(map['message']?.toString() ?? 'Registration failed');
  }
  return map;
}

Future<Map<String, dynamic>> startVendorPayment({
  required int intentId,
  String? paymentPhone,
}) async {
  final res = await apiPost('/public/vendor-subscribe/intent/$intentId/pay', {
    if (paymentPhone != null) 'payment_phone': paymentPhone,
  }, token: null);
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(map['message']?.toString() ?? 'Payment failed');
  }
  return map;
}

Future<Map<String, dynamic>> pollVendorSubscribeStatus(int intentId) async {
  final res = await apiGet('/public/vendor-subscribe/intent/$intentId/status', token: null);
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<String> resetPasswordWithToken({
  required String token,
  required String email,
  required String password,
  required String passwordConfirmation,
}) async {
  final res = await apiPost('/password/reset', {
    'token': token,
    'email': email,
    'password': password,
    'password_confirmation': passwordConfirmation,
  }, token: null);
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(map['message']?.toString() ?? 'Reset failed');
  }
  return map['message']?.toString() ?? 'Password reset.';
}

Future<String> sendEmailVerification() async {
  final res = await apiPost('/email/verification-notification', {});
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(map['message']?.toString() ?? 'Failed to send verification');
  }
  return map['message']?.toString() ?? 'Verification email sent.';
}

Future<String> verifyEmailWithHash({required int userId, required String hash}) async {
  final res = await apiPost('/email/verify/$userId/$hash', {});
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(map['message']?.toString() ?? 'Verification failed');
  }
  return map['message']?.toString() ?? 'Email verified.';
}

Future<String> resolveWebBaseUrl() async {
  final api = await resolveBaseUrl();
  if (api.endsWith('/api')) {
    return api.substring(0, api.length - 4);
  }
  return api;
}

Future<Map<String, dynamic>> runDbSetupAction(String action, String pass) async {
  final base = await resolveWebBaseUrl();
  final path = action == 'setup' ? '/db/setup/run' : '/db/$action';
  final url = Uri.parse('$base$path?pass=${Uri.encodeComponent(pass)}');
  final response = await http.get(url, headers: {'Accept': 'application/json'});
  dynamic map;
  try {
    map = jsonDecode(response.body);
  } catch (_) {
    throw Exception(response.body.isNotEmpty ? response.body : 'DB action failed');
  }
  if (response.statusCode != 200) {
    throw Exception(map is Map ? map['message']?.toString() ?? 'DB action failed' : 'DB action failed');
  }
  return map is Map<String, dynamic> ? map : {'raw': map};
}
