import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'shop_scaffold.dart';

class ShopOrdersScreen extends StatefulWidget {
  const ShopOrdersScreen({
    super.key,
    this.apiPrefix = 'customer',
    this.mode = ShopPortalMode.customer,
  });

  final String apiPrefix;
  final ShopPortalMode mode;

  @override
  State<ShopOrdersScreen> createState() => _ShopOrdersScreenState();
}

class _ShopOrdersScreenState extends State<ShopOrdersScreen> {
  late final ShopApi _api = ShopApi(apiPrefix: widget.apiPrefix);
  List<dynamic> _orders = [];
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
      final orders = await _api.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
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
    return ShopScaffold(
      title: 'Orders',
      mode: widget.mode,
      showDrawer: true,
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _orders.isEmpty
                      ? const AdminPageEmpty(icon: Icons.receipt_long_outlined, title: 'No orders yet')
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          itemBuilder: (context, i) {
                            final o = _orders[i] as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                title: Text('Order #${o['id']}'),
                                subtitle: Text('${o['status']} · ${o['payment_status']}'),
                                trailing: Text(formatTzs((o['total_price'] as num?) ?? 0)),
                                onTap: () => _showDetail(o['id'] as int),
                              ),
                            );
                          },
                        ),
            ),
    );
  }

  Future<void> _showDetail(int id) async {
    try {
      final order = await _api.getOrder(id);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #$id', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Status: ${order['status']}'),
              Text('Payment: ${order['payment_status']}'),
              Text('Total: ${formatTzs((order['total_price'] as num?) ?? 0)}'),
              const SizedBox(height: 12),
              for (final item in (order['items'] as List<dynamic>? ?? []))
                Text('• ${item['product']?['name']} × ${item['quantity']}'),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
