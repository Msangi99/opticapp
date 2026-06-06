import 'dart:convert';

import 'package:http/http.dart' as http;

import 'client.dart';

/// Shop commerce API prefix: `customer`, `team-leader`, or `regional-manager`.
class ShopApi {
  ShopApi({this.apiPrefix = 'customer'});

  final String apiPrefix;

  String get _p => '/$apiPrefix';

  Future<List<dynamic>> getCategories({bool public = false}) async {
    final path = public ? '/public/categories' : '$_p/categories';
    final res = await apiGet(path, token: public ? null : null);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(map['message']?.toString() ?? 'Failed to load categories');
    }
    return map['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> getProducts({
    int? categoryId,
    String? query,
    int page = 1,
    bool public = false,
  }) async {
    final params = <String, String>{
      'page': '$page',
      if (categoryId != null) 'category_id': '$categoryId',
      if (query != null && query.isNotEmpty) 'q': query,
    };
    final path = public ? '/public/products' : '$_p/products';
    final base = await resolveBaseUrl();
    final uri = Uri.parse('$base$path').replace(queryParameters: params);
    final token = public ? null : await getStoredToken();
    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(map['message']?.toString() ?? 'Failed to load products');
    }
    return map;
  }

  Future<Map<String, dynamic>> getProduct(int id, {bool public = false}) async {
    final path = public ? '/public/products/$id' : '$_p/products/$id';
    final res = await apiGet(path);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(map['message']?.toString() ?? 'Failed to load product');
    }
    return map;
  }

  Future<Map<String, dynamic>> getCart() async {
    final res = await apiGet('$_p/cart');
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(map['message']?.toString() ?? 'Failed to load cart');
    }
    return map['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> addToCart({required int productId, int quantity = 1}) async {
    final res = await apiPost('$_p/cart', {'product_id': productId, 'quantity': quantity});
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(map['message']?.toString() ?? 'Failed to add to cart');
    }
    return map['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> updateCartItem(int itemId, int quantity) async {
    final res = await apiPatch('$_p/cart/$itemId', {'quantity': quantity});
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(map['message']?.toString() ?? 'Failed to update cart');
    }
    return map['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> removeCartItem(int itemId) async {
    final res = await apiDelete('$_p/cart/$itemId');
    if (res.statusCode != 200) {
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(map?['message']?.toString() ?? 'Failed to remove item');
    }
  }

  Future<List<dynamic>> getAddresses() async {
    final res = await apiGet('$_p/addresses');
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(map['message']?.toString() ?? 'Failed to load addresses');
    }
    return map['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> saveAddress(Map<String, dynamic> body, {int? id}) async {
    final res = id == null
        ? await apiPost('$_p/addresses', body)
        : await apiPut('$_p/addresses/$id', body);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(map['message']?.toString() ?? 'Failed to save address');
    }
    return map['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> deleteAddress(int id) async {
    final res = await apiDelete('$_p/addresses/$id');
    if (res.statusCode != 200) {
      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(map?['message']?.toString() ?? 'Failed to delete address');
    }
  }

  Future<List<dynamic>> getOrders() async {
    final res = await apiGet('$_p/orders');
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(map['message']?.toString() ?? 'Failed to load orders');
    }
    return map['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> getOrder(int id) async {
    final res = await apiGet('$_p/orders/$id');
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(map['message']?.toString() ?? 'Failed to load order');
    }
    return map['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getCheckoutPreview() async {
    final res = await apiGet('$_p/checkout');
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(map['message']?.toString() ?? 'Checkout unavailable');
    }
    return map['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> placeOrder({
    required int addressId,
    required String paymentMethod,
    String? paymentPhone,
  }) async {
    final res = await apiPost('$_p/checkout', {
      'address_id': addressId,
      'payment_method': paymentMethod,
      if (paymentPhone != null) 'payment_phone': paymentPhone,
    });
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(map['message']?.toString() ?? 'Checkout failed');
    }
    return map;
  }

  Future<Map<String, dynamic>> pollPaymentStatus(int orderId) async {
    final res = await apiGet('$_p/checkout/status/$orderId');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

Future<Map<String, dynamic>> getCustomerDashboard() async {
  final res = await apiGet('/customer/dashboard');
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(map['message']?.toString() ?? 'Failed to load dashboard');
  }
  return map['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> getCustomerProfile() async {
  final res = await apiGet('/customer/profile');
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(map['message']?.toString() ?? 'Failed to load profile');
  }
  return map['data'] as Map<String, dynamic>? ?? {};
}

Future<Map<String, dynamic>> updateCustomerProfile({
  required String name,
  required String email,
}) async {
  final res = await apiPut('/customer/profile', {'name': name, 'email': email});
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode != 200) {
    throw Exception(map['message']?.toString() ?? 'Failed to update profile');
  }
  final user = map['data'];
  if (user is Map<String, dynamic>) {
    await setStoredUser(user);
  }
  return user as Map<String, dynamic>? ?? {};
}

Future<void> updateCustomerPassword({
  required String currentPassword,
  required String password,
  required String passwordConfirmation,
}) async {
  final res = await apiPut('/customer/profile/password', {
    'current_password': currentPassword,
    'password': password,
    'password_confirmation': passwordConfirmation,
  });
  final map = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode != 200) {
    throw Exception(map?['message']?.toString() ?? 'Failed to update password');
  }
}

String formatTzs(num amount) {
  return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} TZS';
}
