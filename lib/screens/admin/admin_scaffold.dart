import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/client.dart';
import '../../api/users_api.dart';

/// Brand colors matching Laravel admin.
const Color _kBrandDark = Color(0xFF232F3E);
const Color _kBrandOrange = Color(0xFFFA8900);
const Color _kDrawerCanvas = Color(0xFFF1F5F9);
const Color _kPanel = Color(0xFFFFFFFF);
const Color _kPanelBorder = Color(0xFFE2E8F0);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextMuted = Color(0xFF64748B);

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
          if (widget.showDrawer)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon.')),
                );
              },
            ),
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

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.route, this.badgeCount});

  final IconData icon;
  final String label;
  final String route;
  final int? badgeCount;
}

class _AdminDrawer extends StatefulWidget {
  const _AdminDrawer();

  @override
  State<_AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<_AdminDrawer> {
  static const _sectionSpacing = 14.0;

  Map<String, dynamic>? _permissions;
  String? _siteUrl;

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

    return Drawer(
      width: 300,
      backgroundColor: _kDrawerCanvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const _DrawerHeader(),
            if (_siteUrl != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(_siteUrl!);
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('View site'),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                children: [
                  if (_canViewModule('dashboard')) ...[
                    _DrawerSectionCard(
                      title: 'Dashboard',
                      primary: primary,
                      items: const [
                        _NavItem(icon: Icons.dashboard_rounded, label: 'Main Dashboard', route: '/admin/dashboard'),
                      ],
                      onNavigate: navigate,
                    ),
                    const SizedBox(height: _sectionSpacing),
                  ],
                  if (_canViewModule('customers') || _canViewModule('agents'))
                    _ManagementDrawerSection(primary: primary, onNavigate: navigate),
                  if (_canViewModule('customers') || _canViewModule('agents'))
                    const SizedBox(height: _sectionSpacing),
                  if (_canViewModule('stocks') || _canViewModule('purchases'))
                    _DrawerSectionCard(
                    title: 'Stock Management',
                    primary: primary,
                    collapsible: true,
                    initiallyExpanded: true,
                    groupIcon: Icons.inventory_2_rounded,
                    groupLabel: 'Stock',
                    items: const [
                      _NavItem(icon: Icons.inventory_2_rounded, label: 'Stocks', route: '/admin/stocks'),
                      _NavItem(icon: Icons.qr_code_2_rounded, label: 'IMEI search', route: '/admin/imei-search'),
                      _NavItem(icon: Icons.store_mall_directory_rounded, label: 'Branches', route: '/admin/branches'),
                      _NavItem(icon: Icons.receipt_long_rounded, label: 'Purchases', route: '/admin/purchases'),
                      _NavItem(icon: Icons.swap_horiz_rounded, label: 'Passthrough Sales', route: '/admin/passthrough'),
                      _NavItem(icon: Icons.local_shipping_rounded, label: 'Distribution Sales', route: '/admin/stock/distribution'),
                      _NavItem(icon: Icons.person_pin_circle_rounded, label: 'Agent Cash Sales', route: '/admin/stock/agent-sales'),
                      _NavItem(icon: Icons.credit_card_rounded, label: 'Agent Credit Sales', route: '/admin/agent-credits'),
                      _NavItem(icon: Icons.alt_route_rounded, label: 'Branch transfer', route: '/admin/stock/branch-transfer'),
                    ],
                    onNavigate: navigate,
                  ),
                  if (_canViewModule('stocks') || _canViewModule('purchases'))
                    const SizedBox(height: _sectionSpacing),
                  if (_canViewModule('expenses') || _canViewModule('reports') || _canViewModule('settings'))
                    _DrawerSectionCard(
                    title: 'Operations',
                    primary: primary,
                    items: const [
                      _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Channels', route: '/admin/channels'),
                      _NavItem(icon: Icons.payments_rounded, label: 'Expenses', route: '/admin/expenses'),
                      _NavItem(icon: Icons.outbond_rounded, label: 'Pay out', route: '/admin/payout'),
                      _NavItem(icon: Icons.assessment_rounded, label: 'Sales Reports', route: '/admin/reports'),
                      _NavItem(icon: Icons.leaderboard_rounded, label: 'Leads report', route: '/admin/leads'),
                      _NavItem(icon: Icons.apartment_rounded, label: 'Subscription', route: '/admin/subscription'),
                      _NavItem(icon: Icons.settings_rounded, label: 'Store Settings', route: '/admin/settings'),
                    ],
                    onNavigate: navigate,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _kPanel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kPanelBorder.withValues(alpha: 0.9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _DrawerNavRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        primary: primary,
                        onTap: () => navigate('/admin/profile'),
                      ),
                      Divider(height: 1, thickness: 1, indent: 60, color: _kPanelBorder.withValues(alpha: 0.65)),
                      _DrawerNavRow(
                        icon: Icons.logout_rounded,
                        label: 'Log out',
                        primary: primary,
                        iconTint: const Color(0xFFDC2626),
                        iconBackground: const Color(0xFFFEE2E2),
                        showChevron: false,
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    await clearStoredAuth();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class _ManagementDrawerSection extends StatefulWidget {
  const _ManagementDrawerSection({required this.primary, required this.onNavigate});

  final Color primary;
  final void Function(String route) onNavigate;

  static const _usersItems = [
    _NavItem(icon: Icons.groups_2_rounded, label: 'All users', route: '/admin/users'),
    _NavItem(icon: Icons.account_tree_rounded, label: 'Organization tree', route: '/admin/organization'),
    _NavItem(icon: Icons.store_rounded, label: 'Dealers', route: '/admin/dealers'),
    _NavItem(icon: Icons.local_shipping_rounded, label: 'Vendors', route: '/admin/vendors'),
  ];

  @override
  State<_ManagementDrawerSection> createState() => _ManagementDrawerSectionState();
}

class _ManagementDrawerSectionState extends State<_ManagementDrawerSection> {
  bool _usersExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'MANAGEMENT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.85,
                  color: _kTextMuted,
                  fontSize: 11,
                ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kPanelBorder.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                _DrawerNavRow(
                  icon: Icons.category_rounded,
                  label: 'Brands',
                  primary: widget.primary,
                  onTap: () => widget.onNavigate('/admin/categories'),
                ),
                Divider(height: 1, thickness: 1, indent: 60, color: _kPanelBorder.withValues(alpha: 0.65)),
                _DrawerNavRow(
                  icon: Icons.view_in_ar_rounded,
                  label: 'Models',
                  primary: widget.primary,
                  onTap: () => widget.onNavigate('/admin/models'),
                ),
                Divider(height: 1, thickness: 1, indent: 60, color: _kPanelBorder.withValues(alpha: 0.65)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _usersExpanded = !_usersExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: widget.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.people_rounded, size: 21, color: widget.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Users',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                    color: _kTextPrimary,
                                  ),
                            ),
                          ),
                          Icon(
                            _usersExpanded ? Icons.expand_more : Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_usersExpanded) ...[
                  Divider(height: 1, thickness: 1, indent: 60, color: _kPanelBorder.withValues(alpha: 0.65)),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: _kPanelBorder.withValues(alpha: 0.75)),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          children: [
                            for (var i = 0; i < _ManagementDrawerSection._usersItems.length; i++) ...[
                              if (i > 0)
                                Divider(height: 1, thickness: 1, color: _kPanelBorder.withValues(alpha: 0.65)),
                              _DrawerNavRow(
                                icon: _ManagementDrawerSection._usersItems[i].icon,
                                label: _ManagementDrawerSection._usersItems[i].label,
                                primary: widget.primary,
                                compact: true,
                                onTap: () => widget.onNavigate(_ManagementDrawerSection._usersItems[i].route),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerSectionCard extends StatefulWidget {
  const _DrawerSectionCard({
    required this.title,
    required this.items,
    required this.onNavigate,
    required this.primary,
    this.collapsible = false,
    this.initiallyExpanded = false,
    this.groupIcon,
    this.groupLabel,
  });

  final String title;
  final List<_NavItem> items;
  final void Function(String route) onNavigate;
  final Color primary;
  final bool collapsible;
  final bool initiallyExpanded;
  final IconData? groupIcon;
  final String? groupLabel;

  @override
  State<_DrawerSectionCard> createState() => _DrawerSectionCardState();
}

class _DrawerSectionCardState extends State<_DrawerSectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.collapsible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.85,
                    color: _kTextMuted,
                    fontSize: 11,
                  ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: _kPanel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kPanelBorder.withValues(alpha: 0.9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: widget.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(widget.groupIcon ?? Icons.people_rounded, size: 21, color: widget.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.groupLabel ?? widget.title,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.5,
                                      color: _kTextPrimary,
                                    ),
                              ),
                            ),
                            Icon(
                              _expanded ? Icons.expand_more : Icons.chevron_right_rounded,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_expanded) ...[
                    Divider(height: 1, thickness: 1, indent: 60, color: _kPanelBorder.withValues(alpha: 0.65)),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: _kPanelBorder.withValues(alpha: 0.75)),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            children: [
                              for (var i = 0; i < widget.items.length; i++) ...[
                                if (i > 0)
                                  Divider(height: 1, thickness: 1, color: _kPanelBorder.withValues(alpha: 0.65)),
                                _DrawerNavRow(
                                  icon: widget.items[i].icon,
                                  label: widget.items[i].label,
                                  primary: widget.primary,
                                  compact: true,
                                  onTap: () => widget.onNavigate(widget.items[i].route),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.85,
                  color: _kTextMuted,
                  fontSize: 11,
                ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kPanelBorder.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (var i = 0; i < widget.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 60,
                      color: _kPanelBorder.withValues(alpha: 0.65),
                    ),
                  _DrawerNavRow(
                    icon: widget.items[i].icon,
                    label: widget.items[i].label,
                    primary: widget.primary,
                    badgeCount: widget.items[i].badgeCount,
                    onTap: () => widget.onNavigate(widget.items[i].route),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerNavRow extends StatelessWidget {
  const _DrawerNavRow({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
    this.iconTint,
    this.iconBackground,
    this.showChevron = true,
    this.badgeCount,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;
  final Color? iconTint;
  final Color? iconBackground;
  final bool showChevron;
  final int? badgeCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = iconTint ?? primary;
    final bg = iconBackground ?? primary.withValues(alpha: 0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: primary.withValues(alpha: 0.08),
        highlightColor: primary.withValues(alpha: 0.05),
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 12 : 12, compact ? 9 : 11, 12, compact ? 9 : 11),
          child: Row(
            children: [
              if (!compact)
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 21, color: fg),
                ),
              if (!compact) const SizedBox(width: 12),
              if (compact)
                Icon(icon, size: 18, color: fg.withValues(alpha: 0.85)),
              if (compact) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        height: 1.25,
                        color: _kTextPrimary,
                        letterSpacing: -0.1,
                      ),
                ),
              ),
              if ((badgeCount ?? 0) > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${badgeCount!}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              if (showChevron)
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'opticedg',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
              ),
              Text(
                'eafrica',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _kBrandOrange,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kBrandOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ADMIN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _kBrandDark,
                    letterSpacing: 1.0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
