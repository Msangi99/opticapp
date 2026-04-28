import 'package:flutter/material.dart';
import '../../api/client.dart';

/// Brand colors matching Laravel admin.
const Color _kBrandDark = Color(0xFF232F3E);
const Color _kBrandOrange = Color(0xFFFA8900);
const Color _kDrawerCanvas = Color(0xFFF1F5F9);
const Color _kPanel = Color(0xFFFFFFFF);
const Color _kPanelBorder = Color(0xFFE2E8F0);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextMuted = Color(0xFF64748B);

/// Agent scaffold. Drawer only on dashboard; other pages get back arrow.
class AgentScaffold extends StatefulWidget {
  const AgentScaffold({
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
  State<AgentScaffold> createState() => _AgentScaffoldState();
}

class _AgentScaffoldState extends State<AgentScaffold> {
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
          child: Divider(
            height: 1,
            thickness: 1,
            color: _kPanelBorder.withValues(alpha: 0.95),
          ),
        ),
      ),
      drawer: widget.showDrawer ? const _AgentDrawer() : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;
}

class _AgentDrawer extends StatelessWidget {
  const _AgentDrawer();

  static const _sectionSpacing = 14.0;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    void navigate(String routeName) {
      Navigator.pop(context);
      if (routeName == '/agent/dashboard') {
        Navigator.pushReplacementNamed(context, routeName);
      } else {
        Navigator.pushNamed(context, routeName);
      }
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
            const _AgentDrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                children: [
                  _DrawerSectionCard(
                    title: 'Dashboard',
                    primary: primary,
                    items: const [
                      _NavItem(icon: Icons.dashboard_rounded, label: 'Main dashboard', route: '/agent/dashboard'),
                    ],
                    onNavigate: navigate,
                  ),
                  const SizedBox(height: _sectionSpacing),
                  _DrawerSectionCard(
                    title: 'Sales',
                    primary: primary,
                    items: const [
                      _NavItem(icon: Icons.sell_rounded, label: 'Record sale', route: '/agent/sell'),
                      _NavItem(icon: Icons.receipt_long_rounded, label: 'Sales history', route: '/agent/sales'),
                      _NavItem(icon: Icons.credit_score_rounded, label: 'Credit', route: '/agent/credits'),
                      _NavItem(icon: Icons.person_search_rounded, label: 'Leads', route: '/agent/leads'),
                    ],
                    onNavigate: navigate,
                  ),
                  const SizedBox(height: _sectionSpacing),
                  _DrawerSectionCard(
                    title: 'Transfers',
                    primary: primary,
                    items: const [
                      _NavItem(icon: Icons.swap_horiz_rounded, label: 'Transfer devices', route: '/agent/transfer'),
                      _NavItem(icon: Icons.list_alt_rounded, label: 'Transfer requests', route: '/agent/transfers'),
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
                  child: _DrawerNavRow(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    primary: primary,
                    iconTint: const Color(0xFFDC2626),
                    iconBackground: const Color(0xFFFEE2E2),
                    showChevron: false,
                    onTap: () => _logout(context),
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

class _DrawerSectionCard extends StatelessWidget {
  const _DrawerSectionCard({
    required this.title,
    required this.items,
    required this.onNavigate,
    required this.primary,
  });

  final String title;
  final List<_NavItem> items;
  final void Function(String route) onNavigate;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
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
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 60,
                      color: _kPanelBorder.withValues(alpha: 0.65),
                    ),
                  _DrawerNavRow(
                    icon: items[i].icon,
                    label: items[i].label,
                    primary: primary,
                    onTap: () => onNavigate(items[i].route),
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
  });

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;
  final Color? iconTint;
  final Color? iconBackground;
  final bool showChevron;

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
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
              const SizedBox(width: 12),
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
              if (showChevron)
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentDrawerHeader extends StatelessWidget {
  const _AgentDrawerHeader();

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
              'AGENT',
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
