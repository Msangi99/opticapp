import 'dart:convert';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  List<Map<String, dynamic>> _imeis = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) return;
    final productId = args['id'] as int?;
    if (productId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _fetchProduct(productId),
        _list('/admin/products/$productId/imeis'),
      ]);
      if (!mounted) return;
      setState(() {
        _product = results[0] as Map<String, dynamic>?;
        _imeis = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<Map<String, dynamic>?> _fetchProduct(int id) async {
    try {
      final list = await _list('/admin/products?per_page=100');
      return list.cast<Map<String, dynamic>?>().firstWhere(
        (p) => p?['id'] == id,
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _list(String path) async {
    final res = await apiGet(path);
    final data = jsonDecode(res.body);
    if (data is Map && data['data'] is List) return (data['data'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final name = _product?['name']?.toString() ?? 'Product';

    return AdminScaffold(
      title: name,
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AdminSectionCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          if (_product?['description'] != null)
                            Text(_product!['description'].toString(), style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('IMEI / Serial Numbers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (_imeis.isEmpty)
                      const AdminPageEmpty(icon: Icons.qr_code, title: 'No IMEIs for this product')
                    else
                      ...List.generate(_imeis.length, (i) {
                        final imei = _imeis[i];
                        final status = imei['status']?.toString() ?? 'available';
                        final isSold = status == 'sold';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: AdminSectionCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(imei['imei']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                                      if (imei['model_name'] != null)
                                        Text(imei['model_name'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isSold ? Colors.red : Colors.green).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isSold ? 'Sold' : 'In Stock',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSold ? Colors.red.shade800 : Colors.green.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}
