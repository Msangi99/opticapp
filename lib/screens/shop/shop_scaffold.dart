import 'package:flutter/material.dart';

import '../../api/client.dart';

const Color kShopBrandDark = Color(0xFF232F3E);
const Color kShopBrandOrange = Color(0xFFFA8900);
const Color kShopCanvas = Color(0xFFF1F5F9);

enum ShopPortalMode { customer, teamLeader, regionalManager }

class ShopScaffold extends StatefulWidget {
  const ShopScaffold({
    super.key,
    required this.title,
    required this.body,
    this.mode = ShopPortalMode.customer,
    this.actions,
    this.showDrawer = true,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final ShopPortalMode mode;
  final List<Widget>? actions;
  final bool showDrawer;
  final Widget? floatingActionButton;

  @override
  State<ShopScaffold> createState() => _ShopScaffoldState();
}

class _ShopScaffoldState extends State<ShopScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _badge {
    switch (widget.mode) {
      case ShopPortalMode.teamLeader:
        return 'TEAM LEADER SHOP';
      case ShopPortalMode.regionalManager:
        return 'REGIONAL MANAGER SHOP';
      case ShopPortalMode.customer:
        return 'SHOP';
    }
  }

  String get _dashboardRoute {
    switch (widget.mode) {
      case ShopPortalMode.teamLeader:
        return '/team-leader/dashboard';
      case ShopPortalMode.regionalManager:
        return '/regional-manager/dashboard';
      case ShopPortalMode.customer:
        return '/shop/dashboard';
    }
  }

  String get _browseRoute {
    switch (widget.mode) {
      case ShopPortalMode.teamLeader:
        return '/team-leader/shop/browse';
      case ShopPortalMode.regionalManager:
        return '/regional-manager/shop/browse';
      case ShopPortalMode.customer:
        return '/shop/browse';
    }
  }

  String get _cartRoute {
    switch (widget.mode) {
      case ShopPortalMode.teamLeader:
        return '/team-leader/cart';
      case ShopPortalMode.regionalManager:
        return '/regional-manager/shop/cart';
      case ShopPortalMode.customer:
        return '/shop/cart';
    }
  }

  String get _ordersRoute {
    switch (widget.mode) {
      case ShopPortalMode.teamLeader:
        return '/team-leader/orders';
      case ShopPortalMode.regionalManager:
        return '/regional-manager/shop/orders';
      case ShopPortalMode.customer:
        return '/shop/orders';
    }
  }

  String get _addressesRoute {
    switch (widget.mode) {
      case ShopPortalMode.teamLeader:
        return '/team-leader/addresses';
      case ShopPortalMode.regionalManager:
        return '/regional-manager/shop/addresses';
      case ShopPortalMode.customer:
        return '/shop/addresses';
    }
  }

  String? get _profileRoute {
    if (widget.mode == ShopPortalMode.customer) return '/shop/profile';
    if (widget.mode == ShopPortalMode.teamLeader) return '/team-leader/profile';
    if (widget.mode == ShopPortalMode.regionalManager) return '/regional-manager/profile';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kShopCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kShopBrandDark,
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: widget.showDrawer
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
        actions: widget.actions,
      ),
      drawer: widget.showDrawer ? _buildDrawer(context) : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    void go(String route, {bool replace = false}) {
      Navigator.pop(context);
      if (replace) {
        Navigator.pushReplacementNamed(context, route);
      } else {
        Navigator.pushNamed(context, route);
      }
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: kShopBrandDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('opticedge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: kShopBrandOrange, borderRadius: BorderRadius.circular(6)),
                    child: Text(_badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (widget.mode == ShopPortalMode.customer)
                    ListTile(
                      leading: const Icon(Icons.dashboard_outlined),
                      title: const Text('Dashboard'),
                      onTap: () => go('/shop/dashboard', replace: true),
                    ),
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text('Browse products'),
                    onTap: () => go(_browseRoute, replace: widget.mode != ShopPortalMode.customer),
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart_outlined),
                    title: const Text('Cart'),
                    onTap: () => go(_cartRoute),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Orders'),
                    onTap: () => go(_ordersRoute),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Addresses'),
                    onTap: () => go(_addressesRoute),
                  ),
                  if (_profileRoute != null)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profile'),
                      onTap: () => go(_profileRoute!),
                    ),
                  if (widget.mode != ShopPortalMode.customer)
                    ListTile(
                      leading: const Icon(Icons.arrow_back),
                      title: const Text('Back to portal'),
                      onTap: () => go(_dashboardRoute, replace: true),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log out'),
              onTap: () async {
                Navigator.pop(context);
                await clearStoredAuth();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget shopProductImage(String? url, {double height = 120}) {
  if (url == null || url.isEmpty) {
    return Container(
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.phone_android, size: 48, color: Colors.grey),
    );
  }
  return Image.network(
    url,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => Container(
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image_outlined),
    ),
  );
}
