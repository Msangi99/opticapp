import 'package:flutter/material.dart';
import '../../api/auth_api.dart';
import '../../widgets/portal_drawer.dart';

const Color _kBrandDark = Color(0xFF232F3E);
const Color _kDrawerCanvas = Color(0xFFE8EDF5);
const Color _kPanelBorder = Color(0xFFE2E8F0);
const Color _kTextPrimary = Color(0xFF0F172A);

class SuperadminScaffold extends StatefulWidget {
  const SuperadminScaffold({
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
  final bool showDrawer;
  final Widget? floatingActionButton;
  final Widget? leading;

  @override
  State<SuperadminScaffold> createState() => _SuperadminScaffoldState();
}

class _SuperadminScaffoldState extends State<SuperadminScaffold> {
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
      backgroundColor: _kDrawerCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kBrandDark,
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
                color: _kTextPrimary,
              ),
        ),
        leading: leading,
        actions: widget.actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _kPanelBorder.withValues(alpha: 0.95)),
        ),
      ),
      drawer: widget.showDrawer ? const _SuperadminDrawer() : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

class _SuperadminDrawer extends StatelessWidget {
  const _SuperadminDrawer();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    void navigate(String route) {
      Navigator.pop(context);
      if (route == '/superadmin/dashboard') {
        Navigator.pushReplacementNamed(context, route);
      } else {
        Navigator.pushNamed(context, route);
      }
    }

    return PortalDrawerShell(
      child: Column(
        children: [
          const PortalDrawerHeader(roleBadge: 'PLATFORM', badgeIsOrange: false),
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
                  title: 'Platform',
                  primary: primary,
                  items: const [
                    PortalNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/superadmin/dashboard'),
                    PortalNavItem(icon: Icons.store_rounded, label: 'Vendors', route: '/superadmin/tenants'),
                    PortalNavItem(icon: Icons.inventory_2_rounded, label: 'Packages', route: '/superadmin/packages'),
                    PortalNavItem(icon: Icons.payments_rounded, label: 'Subscription', route: '/superadmin/subscription-profits'),
                    PortalNavItem(icon: Icons.settings_rounded, label: 'Platform settings', route: '/superadmin/settings'),
                    PortalNavItem(icon: Icons.terminal_rounded, label: 'Command Center', route: '/superadmin/command-center'),
                  ],
                  onNavigate: navigate,
                ),
                const SizedBox(height: PortalDrawerTheme.sectionSpacing),
                PortalDrawerSectionCard(
                  title: 'Master catalog',
                  primary: primary,
                  items: const [
                    PortalNavItem(icon: Icons.public_rounded, label: 'Regions', route: '/superadmin/regions'),
                    PortalNavItem(icon: Icons.category_rounded, label: 'Brands', route: '/superadmin/brands'),
                    PortalNavItem(icon: Icons.view_in_ar_rounded, label: 'Models', route: '/superadmin/models'),
                  ],
                  onNavigate: navigate,
                ),
              ],
            ),
          ),
          PortalDrawerFooter(
            primary: primary,
            onProfile: () => navigate('/superadmin/profile'),
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
