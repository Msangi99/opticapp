import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'shop_scaffold.dart';

class ShopDashboardScreen extends StatefulWidget {
  const ShopDashboardScreen({super.key});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  Map<String, dynamic>? _data;
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
      final data = await getCustomerDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
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
    final user = _data?['user'] as Map<String, dynamic>?;
    final stats = _data?['stats'] as Map<String, dynamic>?;

    return ShopScaffold(
      title: 'Dashboard',
      showDrawer: true,
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Hello, ${user?['name'] ?? 'there'}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (user?['role'] == 'dealer' && user?['business_name'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(user!['business_name'].toString(), style: TextStyle(color: Colors.grey.shade600)),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _statCard('Orders', '${stats?['orders_total'] ?? 0}', Icons.receipt_long),
                            const SizedBox(width: 12),
                            _statCard('Pending', '${stats?['orders_pending'] ?? 0}', Icons.pending_actions),
                            const SizedBox(width: 12),
                            _statCard('Addresses', '${stats?['addresses_total'] ?? 0}', Icons.location_on),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _actionChip(context, 'Browse shop', Icons.storefront, '/shop/browse'),
                            _actionChip(context, 'Cart', Icons.shopping_cart, '/shop/cart'),
                            _actionChip(context, 'Orders', Icons.list_alt, '/shop/orders'),
                            _actionChip(context, 'Profile', Icons.person, '/shop/profile'),
                          ],
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kShopBrandOrange),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(BuildContext context, String label, IconData icon, String route) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: kShopBrandOrange),
      label: Text(label),
      onPressed: () => Navigator.pushNamed(context, route),
    );
  }
}
