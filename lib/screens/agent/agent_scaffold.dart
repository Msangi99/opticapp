import 'package:flutter/material.dart';
import '../../api/client.dart';

/// Brand colors (same as admin).
const Color _kBrandDark = Color(0xFF232F3E);
const Color _kBrandOrange = Color(0xFFFA8900);
const Color _kDrawerBg = Color(0xFFF8FAFC);

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
      drawer: widget.showDrawer ? _AgentDrawer() : null,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

class _AgentDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _kDrawerBg,
      child: SafeArea(
        child: Column(
          children: [
            _AgentDrawerHeader(),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kBrandDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dashboard_rounded, size: 20, color: _kBrandDark),
              ),
              title: const Text('Dashboard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kBrandDark)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/agent/dashboard');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kBrandDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sell_rounded, size: 20, color: _kBrandDark),
              ),
              title: const Text('Record Sale', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kBrandDark)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/agent/sell');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kBrandDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.credit_score_rounded, size: 20, color: _kBrandDark),
              ),
              title: const Text('Credit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kBrandDark)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/agent/credits');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kBrandDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz_rounded, size: 20, color: _kBrandDark),
              ),
              title: const Text('Transfer devices', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kBrandDark)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/agent/transfer');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kBrandDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.list_alt_rounded, size: 20, color: _kBrandDark),
              ),
              title: const Text('Transfer requests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kBrandDark)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/agent/transfers');
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, size: 22, color: _kBrandDark),
              title: const Text('Log out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kBrandDark)),
              onTap: () async {
                Navigator.pop(context);
                await clearStoredAuth();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AgentDrawerHeader extends StatelessWidget {
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
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('opticedg', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              Text('eafrica', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kBrandOrange, letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kBrandOrange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'AGENT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kBrandDark, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
