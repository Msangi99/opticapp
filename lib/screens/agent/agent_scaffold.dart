import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/auth_api.dart';
import '../../providers/pending_request_counts_provider.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/portal_drawer.dart';
import '../../widgets/portal_pending_nav.dart';
import '../../widgets/portal_scaffold_helpers.dart';

const Color _kBrandDark = Color(0xFF232F3E);
const Color _kDrawerCanvas = Color(0xFFE8EDF5);
const Color _kPanelBorder = Color(0xFFE2E8F0);
const Color _kTextPrimary = Color(0xFF0F172A);

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
      drawer: widget.showDrawer ? const _AgentDrawer() : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

class _AgentDrawer extends StatelessWidget {
  const _AgentDrawer();

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

    return PortalDrawerShell(
      child: Column(
        children: [
          const PortalDrawerHeader(roleBadge: 'AGENT'),
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
                  title: 'Dashboard',
                  primary: primary,
                  items: const [
                    PortalNavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Main dashboard',
                      route: '/agent/dashboard',
                    ),
                  ],
                  onNavigate: navigate,
                ),
                const SizedBox(height: PortalDrawerTheme.sectionSpacing),
                PortalDrawerSectionCard(
                  title: 'Sales',
                  primary: primary,
                  items: const [
                    PortalNavItem(icon: Icons.sell_rounded, label: 'Record sale', route: '/agent/sell'),
                    PortalNavItem(icon: Icons.credit_score_rounded, label: 'Credit sales', route: '/agent/credits'),
                    PortalNavItem(icon: Icons.person_search_rounded, label: 'Leads', route: '/agent/leads'),
                  ],
                  onNavigate: navigate,
                ),
                const SizedBox(height: PortalDrawerTheme.sectionSpacing),
                Consumer<PendingRequestCountsProvider>(
                  builder: (context, pending, _) => PortalDrawerSectionCard(
                    title: 'Transfers',
                    primary: primary,
                    items: PortalPendingNav.agentInventoryItems(pending.counts),
                    onNavigate: navigate,
                  ),
                ),
                const SizedBox(height: PortalDrawerTheme.sectionSpacing),
                PortalDrawerSectionCard(
                  title: 'Account',
                  primary: primary,
                  items: const [
                    PortalNavItem(icon: Icons.person_outline_rounded, label: 'Profile', route: '/agent/profile'),
                  ],
                  onNavigate: navigate,
                ),
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
