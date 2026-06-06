import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'shop_checkout_screen.dart';
import 'shop_scaffold.dart';

class ShopCartScreen extends StatefulWidget {
  const ShopCartScreen({
    super.key,
    this.apiPrefix = 'customer',
    this.mode = ShopPortalMode.customer,
  });

  final String apiPrefix;
  final ShopPortalMode mode;

  @override
  State<ShopCartScreen> createState() => _ShopCartScreenState();
}

class _ShopCartScreenState extends State<ShopCartScreen> {
  late final ShopApi _api = ShopApi(apiPrefix: widget.apiPrefix);
  Map<String, dynamic>? _cart;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = await _api.getCart();
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _updateQty(int itemId, int qty) async {
    if (qty < 1) return;
    await _api.updateCartItem(itemId, qty);
    await _load();
  }

  Future<void> _remove(int itemId) async {
    await _api.removeCartItem(itemId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart?['items'] as List<dynamic>? ?? [];

    return ShopScaffold(
      title: 'Cart',
      mode: widget.mode,
      showDrawer: true,
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : items.isEmpty
                  ? const AdminPageEmpty(icon: Icons.shopping_cart_outlined, title: 'Your cart is empty')
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final item = items[i] as Map<String, dynamic>;
                              final product = item['product'] as Map<String, dynamic>? ?? {};
                              return Card(
                                child: ListTile(
                                  leading: SizedBox(width: 48, child: shopProductImage(product['image_url']?.toString(), height: 48)),
                                  title: Text(product['name']?.toString() ?? ''),
                                  subtitle: Text(formatTzs((product['price'] as num?) ?? 0)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.remove), onPressed: () => _updateQty(item['id'] as int, (item['quantity'] as int) - 1)),
                                      Text('${item['quantity']}'),
                                      IconButton(icon: const Icon(Icons.add), onPressed: () => _updateQty(item['id'] as int, (item['quantity'] as int) + 1)),
                                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _remove(item['id'] as int)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Subtotal: ${formatTzs((_cart?['subtotal'] as num?) ?? 0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShopCheckoutScreen(apiPrefix: widget.apiPrefix, mode: widget.mode),
                                  ),
                                ),
                                style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange, padding: const EdgeInsets.symmetric(vertical: 14)),
                                child: const Text('Proceed to checkout'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
