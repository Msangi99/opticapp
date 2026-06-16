import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/auth_api.dart';
import '../../api/client.dart';
import '../../api/users_api.dart';
import '../../providers/pending_request_counts_provider.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/portal_drawer.dart';
import '../../widgets/portal_pending_nav.dart';
import '../../widgets/portal_scaffold_helpers.dart';

const Color _kBrandDark = Color(0xFF232F3E);
const Color _kDrawerCanvas = Color(0xFFE8EDF5);
const Color _kPanelBorder = Color(0xFFE2E8F0);
const Color _kTextPrimary = Color(0xFF0F172A);

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
                onPressed: () {
                  refreshPortalBadges(context);
                  _scaffoldKey.currentState?.openDrawer();
                },
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
        actions: [
          if (widget.showDrawer) const NotificationBell(),
          ...?widget.actions,
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: _kPanelBorder.withValues(alpha: 0.95),
          ),
        ),
      ),
      drawer: widget.showDrawer ? const _AdminDrawer() : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

class _AdminDrawer extends StatefulWidget {
  const _AdminDrawer();

  @override
  State<_AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<_AdminDrawer> {
  Map<String, dynamic>? _permissions;
  String? _siteUrl;

  static const _usersItems = [
    PortalNavItem(icon: Icons.groups_2_rounded, label: 'All users', route: '/admin/users'),
    PortalNavItem(icon: Icons.account_tree_rounded, label: 'Organization tree', route: '/admin/organization'),
    PortalNavItem(icon: Icons.store_rounded, label: 'Dealers', route: '/admin/dealers'),
    PortalNavItem(icon: Icons.local_shipping_rounded, label: 'Vendors', route: '/admin/vendors'),
  ];

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final perms = await getMyPermissions();
      final base = await resolveBaseUrl();
      if (!mounted) return;
      setState(() {
        _permissions = perms;
        _siteUrl = base.replaceAll('/api', '');
      });
    } catch (_) {}
  }

  bool _canViewModule(String module) {
    if (_permissions == null) return true;
    if (_permissions!['full_access'] == true) return true;
    if (_permissions!['view_only'] == true) return true;
    final list = _permissions!['permissions'];
    if (list is! List) return true;
    for (final p in list) {
      if (p is Map && (p['module'] == module || p['module'] == '*')) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    void navigate(String routeName) {
      Navigator.pop(context);
      Navigator.pushNamed(context, routeName);
    }

    return PortalDrawerShell(
      child: Column(
        children: [
          const PortalDrawerHeader(roleBadge: 'ADMIN'),
          if (_siteUrl != null)
            PortalDrawerViewSiteButton(
              onPressed: () async {
                final uri = Uri.parse(_siteUrl!);
                Navigator.pop(context);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                PortalDrawerTheme.horizontalPadding,
                10,
                PortalDrawerTheme.horizontalPadding,
                8,
              ),
              children: [
                if (_canViewModule('dashboard')) ...[
                  PortalDrawerSectionCard(
                    title: 'Dashboard',
                    primary: primary,
                    items: const [
                      PortalNavItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Main Dashboard',
                        route: '/admin/dashboard',
                      ),
                    ],
                    onNavigate: navigate,
                  ),
                  const SizedBox(height: PortalDrawerTheme.sectionSpacing),
                ],
                if (_canViewModule('customers') || _canViewModule('agents')) ...[
                  PortalDrawerManagementSection(
                    primary: primary,
                    onNavigate: navigate,
                    usersItems: _usersItems,
                  ),
                  const SizedBox(height: PortalDrawerTheme.sectionSpacing),
                ],
                if (_canViewModule('stock') || _canViewModule('branches'))
                  Consumer<PendingRequestCountsProvider>(
                    builder: (context, pending, _) => PortalDrawerCollapsibleSection(
                      sectionTitle: 'Stock Management',
                      groupIcon: Icons.inventory_2_rounded,
                      groupLabel: 'Stock',
                      primary: primary,
                      initiallyExpanded: true,
                      items: PortalPendingNav.adminStockItems(pending.counts),
                      onNavigate: navigate,
                    ),
                  ),
                if (_canViewModule('stock') || _canViewModule('branches'))
                  const SizedBox(height: PortalDrawerTheme.sectionSpacing),
                if (_canViewModule('expenses') || _canViewModule('reports') || _canViewModule('settings'))
                  PortalDrawerSectionCard(
                    title: 'Operations',
                    primary: primary,
                    items: const [
                      PortalNavItem(icon: Icons.account_balance_wallet_rounded, label: 'Channels', route: '/admin/channels'),
                      PortalNavItem(icon: Icons.payments_rounded, label: 'Expenses', route: '/admin/expenses'),
                      PortalNavItem(icon: Icons.outbond_rounded, label: 'Pay out', route: '/admin/payout'),
                      PortalNavItem(icon: Icons.assessment_rounded, label: 'Sales Reports', route: '/admin/reports'),
                      PortalNavItem(icon: Icons.leaderboard_rounded, label: 'Leads report', route: '/admin/leads'),
                      PortalNavItem(icon: Icons.apartment_rounded, label: 'Subscription', route: '/admin/subscription'),
                      PortalNavItem(icon: Icons.settings_rounded, label: 'Store Settings', route: '/admin/settings'),
                    ],
                    onNavigate: navigate,
                  ),
              ],
            ),
          ),
          PortalDrawerFooter(
            primary: primary,
            onProfile: () => navigate('/admin/profile'),
            onLogout: _logout,
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    Navigator.pop(context);
    await performLogout();
  }
}
