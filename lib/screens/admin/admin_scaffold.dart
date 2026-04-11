import 'package:flutter/material.dart';
import '../../api/client.dart';

/// Brand colors matching Laravel admin.
const Color _kBrandDark = Color(0xFF232F3E);
const Color _kBrandOrange = Color(0xFFFA8900);
const Color _kDrawerBg = Color(0xFFF8FAFC);
const Color _kSectionLabel = Color(0xFF64748B);

/// Admin scaffold. Drawer only on homepage (dashboard); other pages get back arrow.
class AdminScaffold extends StatefulWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showDrawer = false,
    this.floatingActionButton,
    this.leading,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  /// True only on admin dashboard (homepage). Other pages show back arrow.
  final bool showDrawer;
  final Widget? floatingActionButton;
  /// If set, used as AppBar leading (e.g. back button). When showDrawer is false, defaults to back arrow.
  final Widget? leading;

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final leading = widget.leading ??
        (widget.showDrawer
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: 'Menu',
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'Back',
              ));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kBrandDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF232F3E),
          ),
        ),
        leading: leading,
        actions: widget.actions,
      ),
      drawer: widget.showDrawer ? _AdminDrawer() : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _kDrawerBg,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                children: [
                  _SectionLabel('Dashboard'),
                  _DrawerTile(
                    icon: Icons.dashboard_rounded,
                    label: 'Main Dashboard',
                    onTap: () => _navigate(context, '/admin/dashboard'),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Management'),
                  _DrawerTile(
                    icon: Icons.category_rounded,
                    label: 'Categories',
                    onTap: () => _navigate(context, '/admin/categories'),
                  ),
                  _DrawerTile(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Orders',
                    onTap: () => _navigate(context, '/admin/orders'),
                  ),
                  _DrawerTile(
                    icon: Icons.people_rounded,
                    label: 'Customers',
                    onTap: () => _navigate(context, '/admin/customers'),
                  ),
                  _DrawerTile(
                    icon: Icons.store_rounded,
                    label: 'Dealers',
                    onTap: () => _navigate(context, '/admin/dealers'),
                  ),
                  _DrawerTile(
                    icon: Icons.person_search_rounded,
                    label: 'Agents',
                    onTap: () => _navigate(context, '/admin/agents'),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Stock'),
                  _DrawerTile(
                    icon: Icons.inventory_2_rounded,
                    label: 'Stocks',
                    onTap: () => _navigate(context, '/admin/stocks'),
                  ),
                  _DrawerTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Purchases',
                    onTap: () => _navigate(context, '/admin/stocks'),
                  ),
                  _DrawerTile(
                    icon: Icons.local_shipping_rounded,
                    label: 'Distribution',
                    onTap: () => _navigate(context, '/admin/stock/distribution'),
                  ),
                  _DrawerTile(
                    icon: Icons.pending_actions_rounded,
                    label: 'Pending Sales',
                    onTap: () => _navigate(context, '/admin/stock/pending-sales'),
                  ),
                  _DrawerTile(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Agent transfers',
                    onTap: () => _navigate(context, '/admin/stock/agent-transfers'),
                  ),
                  _DrawerTile(
                    icon: Icons.alt_route_rounded,
                    label: 'Branch transfer',
                    onTap: () => _navigate(context, '/admin/stock/branch-transfer'),
                  ),
                  _DrawerTile(
                    icon: Icons.person_pin_circle_rounded,
                    label: 'Agent Sales',
                    onTap: () => _navigate(context, '/admin/stock/agent-sales'),
                  ),
                  _DrawerTile(
                    icon: Icons.add_box_rounded,
                    label: 'Add Product',
                    onTap: () => _navigate(context, '/admin/add-product'),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Operations'),
                  _DrawerTile(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Channels',
                    onTap: () => _navigate(context, '/admin/channels'),
                  ),
                  _DrawerTile(
                    icon: Icons.payments_rounded,
                    label: 'Expenses',
                    onTap: () => _navigate(context, '/admin/expenses'),
                  ),
                  _DrawerTile(
                    icon: Icons.assessment_rounded,
                    label: 'Reports',
                    onTap: () => _navigate(context, '/admin/reports'),
                  ),
                  _DrawerTile(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => _navigate(context, '/admin/settings'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String routeName) {
    Navigator.pop(context); // close drawer
    Navigator.pushNamed(context, routeName); // push so back arrow returns to dashboard
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    await clearStoredAuth();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: _kBrandDark,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'opticedg',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'eafrica',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kBrandOrange,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kBrandOrange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'ADMIN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kBrandDark,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kSectionLabel,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _kBrandDark.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: _kBrandDark),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _kBrandDark,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}