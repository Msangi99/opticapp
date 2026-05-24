import 'dart:convert';

import 'client.dart';

Future<Map<String, dynamic>> getUserProfileForRole(String rolePrefix) async {
  final res = await apiGet('/$rolePrefix/profile');
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to load profile');
  }
  return map?['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> updateUserProfileForRole({
  required String rolePrefix,
  required String name,
  required String email,
}) async {
  final res = await apiPut('/$rolePrefix/profile', {
    'name': name,
    'email': email,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to update profile');
  }
  final user = map?['data'];
  if (user is Map<String, dynamic>) {
    await setStoredUser(user);
  }
  return user as Map<String, dynamic>? ?? {};
}

Future<void> updateUserPasswordForRole({
  required String rolePrefix,
  required String currentPassword,
  required String password,
  required String passwordConfirmation,
}) async {
  final res = await apiPut('/$rolePrefix/profile/password', {
    'current_password': currentPassword,
    'password': password,
    'password_confirmation': passwordConfirmation,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to update password');
  }
}
