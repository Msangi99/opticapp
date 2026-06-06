import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'shop_product_detail_screen.dart';
import 'shop_scaffold.dart';

class ShopBrowseScreen extends StatefulWidget {
  const ShopBrowseScreen({
    super.key,
    this.apiPrefix = 'customer',
    this.mode = ShopPortalMode.customer,
    this.publicBrowse = false,
  });

  final String apiPrefix;
  final ShopPortalMode mode;
  final bool publicBrowse;

  @override
  State<ShopBrowseScreen> createState() => _ShopBrowseScreenState();
}

class _ShopBrowseScreenState extends State<ShopBrowseScreen> {
  late final ShopApi _api = ShopApi(apiPrefix: widget.apiPrefix);
  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  int? _selectedCategory;
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
      final categories = await _api.getCategories(public: widget.publicBrowse);
      final productsRes = await _api.getProducts(
        categoryId: _selectedCategory,
        public: widget.publicBrowse,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _products = productsRes['data'] as List<dynamic>? ?? [];
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

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const AdminPageLoading()
        : _error != null
            ? AdminPageError(message: _error!)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: _selectedCategory == null,
                            onSelected: (_) {
                              setState(() => _selectedCategory = null);
                              _load();
                            },
                          ),
                        ),
                        for (final c in _categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(c['name']?.toString() ?? ''),
                              selected: _selectedCategory == c['id'],
                              onSelected: (_) {
                                setState(() => _selectedCategory = c['id'] as int?);
                                _load();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _products.isEmpty
                        ? const AdminPageEmpty(icon: Icons.inventory_2_outlined, title: 'No products found')
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, i) {
                              final p = _products[i] as Map<String, dynamic>;
                              return _ProductCard(
                                product: p,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShopProductDetailScreen(
                                      productId: p['id'] as int,
                                      apiPrefix: widget.apiPrefix,
                                      mode: widget.mode,
                                      publicBrowse: widget.publicBrowse,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );

    if (widget.publicBrowse) {
      return Scaffold(
        appBar: AppBar(title: const Text('Browse products')),
        body: body,
      );
    }

    return ShopScaffold(
      title: 'Browse shop',
      mode: widget.mode,
      showDrawer: true,
      body: body,
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: shopProductImage(product['image_url']?.toString()),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatTzs((product['price'] as num?) ?? 0),
                    style: const TextStyle(color: kShopBrandOrange, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
