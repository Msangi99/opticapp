import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'shop_scaffold.dart';

class ShopProductDetailScreen extends StatefulWidget {
  const ShopProductDetailScreen({
    super.key,
    required this.productId,
    this.apiPrefix = 'customer',
    this.mode = ShopPortalMode.customer,
    this.publicBrowse = false,
  });

  final int productId;
  final String apiPrefix;
  final ShopPortalMode mode;
  final bool publicBrowse;

  @override
  State<ShopProductDetailScreen> createState() => _ShopProductDetailScreenState();
}

class _ShopProductDetailScreenState extends State<ShopProductDetailScreen> {
  late final ShopApi _api = ShopApi(apiPrefix: widget.apiPrefix);
  Map<String, dynamic>? _product;
  bool _loading = true;
  bool _adding = false;
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
      final res = await _api.getProduct(widget.productId, public: widget.publicBrowse);
      if (!mounted) return;
      setState(() {
        _product = res['data'] as Map<String, dynamic>?;
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

  Future<void> _addToCart() async {
    if (widget.publicBrowse) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    setState(() => _adding = true);
    try {
      await _api.addToCart(productId: widget.productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final content = _loading
        ? const AdminPageLoading()
        : _error != null
            ? AdminPageError(message: _error!)
            : p == null
                ? const AdminPageEmpty(icon: Icons.error_outline, title: 'Product not found')
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: shopProductImage(p['image_url']?.toString(), height: 220),
                        ),
                        const SizedBox(height: 16),
                        Text(p['name']?.toString() ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(formatTzs((p['price'] as num?) ?? 0), style: const TextStyle(color: kShopBrandOrange, fontSize: 20, fontWeight: FontWeight.w800)),
                        if (p['description'] != null) ...[
                          const SizedBox(height: 16),
                          Text(p['description'].toString()),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _adding ? null : _addToCart,
                          style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange, padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(widget.publicBrowse ? 'Sign in to purchase' : (_adding ? 'Adding…' : 'Add to cart')),
                        ),
                      ],
                    ),
                  );

    if (widget.publicBrowse) {
      return Scaffold(
        appBar: AppBar(title: Text(p?['name']?.toString() ?? 'Product')),
        body: content,
      );
    }

    return ShopScaffold(
      title: p?['name']?.toString() ?? 'Product',
      mode: widget.mode,
      showDrawer: false,
      body: content,
    );
  }
}
