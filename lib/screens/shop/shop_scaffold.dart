import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/portal_drawer.dart';

const Color kShopBrandDark = Color(0xFF232F3E);
const Color kShopBrandOrange = Color(0xFFFA8900);
const Color kShopCanvas = Color(0xFFE8EDF5);

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
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.25,
              ),
        ),
        leading: widget.showDrawer
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: 'Menu',
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'Back',
              ),
        actions: [
          if (widget.showDrawer) const NotificationBell(),
          ...?widget.actions,
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: PortalDrawerTheme.panelBorder.withValues(alpha: 0.95),
          ),
        ),
      ),
      drawer: widget.showDrawer ? _buildDrawer(context) : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    void go(String route, {bool replace = false}) {
      Navigator.pop(context);
      if (replace) {
        Navigator.pushReplacementNamed(context, route);
      } else {
        Navigator.pushNamed(context, route);
      }
    }

    final browseItems = <PortalNavItem>[
      if (widget.mode == ShopPortalMode.customer)
        const PortalNavItem(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          route: '/shop/dashboard',
        ),
      PortalNavItem(
        icon: Icons.storefront_rounded,
        label: 'Browse products',
        route: _browseRoute,
      ),
      PortalNavItem(icon: Icons.shopping_cart_rounded, label: 'Cart', route: _cartRoute),
      PortalNavItem(icon: Icons.receipt_long_rounded, label: 'Orders', route: _ordersRoute),
      PortalNavItem(icon: Icons.location_on_rounded, label: 'Addresses', route: _addressesRoute),
    ];

    final accountItems = <PortalNavItem>[
      if (_profileRoute != null)
        PortalNavItem(icon: Icons.person_outline_rounded, label: 'Profile', route: _profileRoute!),
      if (widget.mode != ShopPortalMode.customer)
        PortalNavItem(
          icon: Icons.arrow_back_rounded,
          label: 'Back to portal',
          route: _dashboardRoute,
        ),
    ];

    return PortalDrawerShell(
      child: Column(
        children: [
          PortalDrawerHeader(roleBadge: _badge),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                PortalDrawerTheme.horizontalPadding,
                10,
                PortalDrawerTheme.horizontalPadding,
                8,
              ),
              children: [
                PortalDrawerSectionCard(
                  title: 'Shop',
                  primary: primary,
                  items: browseItems,
                  onNavigate: (route) {
                    final replaceDashboard = route == '/shop/dashboard';
                    final replaceBrowse = widget.mode != ShopPortalMode.customer &&
                        (route == _browseRoute);
                    go(route, replace: replaceDashboard || replaceBrowse);
                  },
                ),
                if (accountItems.isNotEmpty) ...[
                  const SizedBox(height: PortalDrawerTheme.sectionSpacing),
                  PortalDrawerSectionCard(
                    title: 'Account',
                    primary: primary,
                    items: accountItems,
                    onNavigate: (route) {
                      final replace = route == _dashboardRoute;
                      go(route, replace: replace);
                    },
                  ),
                ],
              ],
            ),
          ),
          PortalDrawerFooter(
            primary: primary,
            showProfile: false,
            onProfile: () {},
            onLogout: () async {
              Navigator.pop(context);
              await performLogout();
            },
          ),
        ],
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
