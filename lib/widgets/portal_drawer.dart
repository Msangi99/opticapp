import 'package:flutter/material.dart';

import '../api/client.dart';

/// Brand + clay palette aligned with Laravel admin web UI.
abstract final class PortalDrawerTheme {
  static const brandDark = Color(0xFF232F3E);
  static const brandOrange = Color(0xFFFA8900);
  static const brandOrangeDark = Color(0xFFE07800);
  static const canvasTop = Color(0xFFDCE3EE);
  static const canvasMid = Color(0xFFE8EDF5);
  static const canvasBottom = Color(0xFFD4DCE8);
  static const panelBorder = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);

  static const drawerWidth = 304.0;
  static const sectionSpacing = 12.0;
  static const horizontalPadding = 12.0;

  static BoxDecoration canvasGradient() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [canvasTop, canvasMid, canvasBottom],
        ),
      );

  static BoxDecoration clayPanel({double radius = 16}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: const Alignment(-0.9, -1),
          end: const Alignment(0.9, 1),
          colors: [
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFF8FAFC).withValues(alpha: 0.92),
            const Color(0xFFF1F5F9).withValues(alpha: 0.88),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(6, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.92),
            blurRadius: 14,
            offset: const Offset(-4, -5),
          ),
        ],
      );

  static BoxDecoration clayHeaderSlab() => BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            const Color(0xFFF8FAFC).withValues(alpha: 0.94),
            const Color(0xFFF1F5F9).withValues(alpha: 0.90),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.26),
            blurRadius: 20,
            offset: const Offset(8, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.95),
            blurRadius: 16,
            offset: const Offset(-5, -6),
          ),
        ],
      );
}

class PortalNavItem {
  const PortalNavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final String route;
  final int? badgeCount;
}

String? portalCurrentRoute(BuildContext context) => ModalRoute.of(context)?.settings.name;

bool portalRouteIsActive(BuildContext context, String route) =>
    portalCurrentRoute(context) == route;

/// Drawer shell with clay canvas background and rounded trailing edge.
class PortalDrawerShell extends StatelessWidget {
  const PortalDrawerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: PortalDrawerTheme.drawerWidth,
      backgroundColor: PortalDrawerTheme.canvasMid,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: DecoratedBox(
        decoration: PortalDrawerTheme.canvasGradient(),
        child: SafeArea(child: child),
      ),
    );
  }
}

/// Header: clay slab, brand, role badge, signed-in user.
class PortalDrawerHeader extends StatefulWidget {
  const PortalDrawerHeader({
    super.key,
    required this.roleBadge,
    this.badgeIsOrange = true,
    this.subtitle,
  });

  final String roleBadge;
  final bool badgeIsOrange;
  final String? subtitle;

  @override
  State<PortalDrawerHeader> createState() => _PortalDrawerHeaderState();
}

class _PortalDrawerHeaderState extends State<PortalDrawerHeader> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await getStoredUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name']?.toString() ?? 'Signed in';
    final email = _user?['email']?.toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PortalDrawerTheme.horizontalPadding,
        10,
        PortalDrawerTheme.horizontalPadding,
        6,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: PortalDrawerTheme.clayHeaderSlab(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandWordmark(),
                      const SizedBox(height: 8),
                      _RoleBadge(
                        label: widget.roleBadge,
                        isOrange: widget.badgeIsOrange,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  style: IconButton.styleFrom(
                    foregroundColor: PortalDrawerTheme.textMuted,
                    backgroundColor: const Color(0xFFE2E8F0).withValues(alpha: 0.45),
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: 'Close menu',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        PortalDrawerTheme.brandOrange,
                        PortalDrawerTheme.brandOrangeDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PortalDrawerTheme.brandOrange.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: PortalDrawerTheme.brandDark,
                              letterSpacing: -0.2,
                            ),
                      ),
                      if (email != null && email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: PortalDrawerTheme.textMuted,
                                fontSize: 12,
                              ),
                        ),
                      ] else if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: PortalDrawerTheme.textMuted,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.05,
          fontSize: 20,
        );
    return RichText(
      text: TextSpan(
        style: base?.copyWith(color: PortalDrawerTheme.brandDark),
        children: [
          const TextSpan(text: 'opticedg'),
          TextSpan(
            text: 'eafrica',
            style: base?.copyWith(color: PortalDrawerTheme.brandOrange),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.isOrange});

  final String label;
  final bool isOrange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isOrange
            ? const LinearGradient(
                colors: [PortalDrawerTheme.brandOrange, PortalDrawerTheme.brandOrangeDark],
              )
            : null,
        color: isOrange ? null : const Color(0xFF334155),
        boxShadow: isOrange
            ? [
                BoxShadow(
                  color: PortalDrawerTheme.brandOrange.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isOrange ? PortalDrawerTheme.brandDark : Colors.white,
              letterSpacing: 0.9,
            ),
      ),
    );
  }
}

class PortalDrawerViewSiteButton extends StatelessWidget {
  const PortalDrawerViewSiteButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PortalDrawerTheme.horizontalPadding,
        4,
        PortalDrawerTheme.horizontalPadding,
        4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.55),
              border: Border.all(color: PortalDrawerTheme.panelBorder.withValues(alpha: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: PortalDrawerTheme.brandOrange.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 8),
                Text(
                  'View website',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: PortalDrawerTheme.brandDark,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PortalDrawerSectionLabel extends StatelessWidget {
  const PortalDrawerSectionLabel({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 6, top: 2),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: PortalDrawerTheme.textMuted,
              fontSize: 10.5,
            ),
      ),
    );
  }
}

class PortalDrawerSectionCard extends StatelessWidget {
  const PortalDrawerSectionCard({
    super.key,
    required this.title,
    required this.items,
    required this.onNavigate,
    required this.primary,
  });

  final String title;
  final List<PortalNavItem> items;
  final void Function(String route) onNavigate;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalDrawerSectionLabel(title: title),
        DecoratedBox(
          decoration: PortalDrawerTheme.clayPanel(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) _sectionDivider(),
                  PortalDrawerNavRow(
                    icon: items[i].icon,
                    label: items[i].label,
                    primary: primary,
                    route: items[i].route,
                    badgeCount: items[i].badgeCount,
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

class PortalDrawerCollapsibleSection extends StatefulWidget {
  const PortalDrawerCollapsibleSection({
    super.key,
    required this.sectionTitle,
    required this.groupIcon,
    required this.groupLabel,
    required this.items,
    required this.onNavigate,
    required this.primary,
    this.initiallyExpanded = true,
  });

  final String sectionTitle;
  final IconData groupIcon;
  final String groupLabel;
  final List<PortalNavItem> items;
  final void Function(String route) onNavigate;
  final Color primary;
  final bool initiallyExpanded;

  @override
  State<PortalDrawerCollapsibleSection> createState() =>
      _PortalDrawerCollapsibleSectionState();
}

class _PortalDrawerCollapsibleSectionState extends State<PortalDrawerCollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalDrawerSectionLabel(title: widget.sectionTitle),
        DecoratedBox(
          decoration: PortalDrawerTheme.clayPanel(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    splashColor: widget.primary.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          _iconTile(
                            icon: widget.groupIcon,
                            primary: widget.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.groupLabel,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: PortalDrawerTheme.textPrimary,
                                    letterSpacing: -0.15,
                                  ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _expanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: PortalDrawerTheme.textMuted.withValues(alpha: 0.75),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      _sectionDivider(indent: 0),
                      Padding(
                        padding: const EdgeInsets.only(left: 14, bottom: 4),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: widget.primary.withValues(alpha: 0.25),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < widget.items.length; i++) ...[
                                if (i > 0) _sectionDivider(indent: 44),
                                PortalDrawerNavRow(
                                  icon: widget.items[i].icon,
                                  label: widget.items[i].label,
                                  primary: widget.primary,
                                  route: widget.items[i].route,
                                  badgeCount: widget.items[i].badgeCount,
                                  compact: true,
                                  onTap: () => widget.onNavigate(widget.items[i].route),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  crossFadeState:
                      _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                  sizeCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Management block with fixed rows + nested collapsible users list.
class PortalDrawerManagementSection extends StatefulWidget {
  const PortalDrawerManagementSection({
    super.key,
    required this.primary,
    required this.onNavigate,
    required this.usersItems,
  });

  final Color primary;
  final void Function(String route) onNavigate;
  final List<PortalNavItem> usersItems;

  @override
  State<PortalDrawerManagementSection> createState() =>
      _PortalDrawerManagementSectionState();
}

class _PortalDrawerManagementSectionState extends State<PortalDrawerManagementSection> {
  bool _usersExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalDrawerSectionLabel(title: 'Management'),
        DecoratedBox(
          decoration: PortalDrawerTheme.clayPanel(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                PortalDrawerNavRow(
                  icon: Icons.category_rounded,
                  label: 'Brands',
                  primary: widget.primary,
                  route: '/admin/categories',
                  onTap: () => widget.onNavigate('/admin/categories'),
                ),
                _sectionDivider(),
                PortalDrawerNavRow(
                  icon: Icons.view_in_ar_rounded,
                  label: 'Models',
                  primary: widget.primary,
                  route: '/admin/models',
                  onTap: () => widget.onNavigate('/admin/models'),
                ),
                _sectionDivider(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _usersExpanded = !_usersExpanded),
                    splashColor: widget.primary.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          _iconTile(icon: Icons.people_rounded, primary: widget.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Users',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: PortalDrawerTheme.textPrimary,
                                  ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _usersExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: PortalDrawerTheme.textMuted.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_usersExpanded) ...[
                  _sectionDivider(indent: 0),
                  Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: widget.primary.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < widget.usersItems.length; i++) ...[
                            if (i > 0) _sectionDivider(indent: 44),
                            PortalDrawerNavRow(
                              icon: widget.usersItems[i].icon,
                              label: widget.usersItems[i].label,
                              primary: widget.primary,
                              route: widget.usersItems[i].route,
                              compact: true,
                              onTap: () => widget.onNavigate(widget.usersItems[i].route),
                            ),
                          ],
                        ],
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

class PortalDrawerNavRow extends StatelessWidget {
  const PortalDrawerNavRow({
    super.key,
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
    this.route,
    this.iconTint,
    this.iconBackground,
    this.showChevron = false,
    this.badgeCount,
    this.compact = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;
  final String? route;
  final Color? iconTint;
  final Color? iconBackground;
  final bool showChevron;
  final int? badgeCount;
  final bool compact;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final selected = route != null && portalRouteIsActive(context, route!);
    final fg = iconTint ?? (destructive ? PortalDrawerTheme.danger : primary);
    final bg = iconBackground ??
        (destructive
            ? PortalDrawerTheme.dangerBg
            : selected
                ? primary.withValues(alpha: 0.18)
                : primary.withValues(alpha: 0.10));

    return Material(
      color: selected ? primary.withValues(alpha: 0.07) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: primary.withValues(alpha: 0.1),
        highlightColor: primary.withValues(alpha: 0.05),
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: primary, width: 3),
                  ),
                )
              : null,
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 12,
            compact ? 10 : 11,
            12,
            compact ? 10 : 11,
          ),
          child: Row(
            children: [
              if (!compact)
                _iconTile(icon: icon, primary: primary, fg: fg, bg: bg)
              else
                Icon(icon, size: 18, color: fg.withValues(alpha: 0.9)),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: compact ? 13.5 : 14,
                        height: 1.25,
                        color: selected ? PortalDrawerTheme.brandDark : PortalDrawerTheme.textPrimary,
                        letterSpacing: -0.1,
                      ),
                ),
              ),
              if ((badgeCount ?? 0) > 0)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: PortalDrawerTheme.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: PortalDrawerTheme.textMuted.withValues(alpha: 0.6),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PortalDrawerFooter extends StatelessWidget {
  const PortalDrawerFooter({
    super.key,
    required this.primary,
    required this.onProfile,
    required this.onLogout,
    this.showProfile = true,
  });

  final Color primary;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final bool showProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PortalDrawerTheme.horizontalPadding,
        4,
        PortalDrawerTheme.horizontalPadding,
        12,
      ),
      child: DecoratedBox(
        decoration: PortalDrawerTheme.clayPanel(radius: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              if (showProfile) ...[
                PortalDrawerNavRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  primary: primary,
                  onTap: onProfile,
                ),
                _sectionDivider(),
              ],
              PortalDrawerNavRow(
                icon: Icons.logout_rounded,
                label: 'Log out',
                primary: primary,
                destructive: true,
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _iconTile({
  required IconData icon,
  required Color primary,
  Color? fg,
  Color? bg,
}) {
  return Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg ?? primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(icon, size: 20, color: fg ?? primary),
  );
}

Widget _sectionDivider({double indent = 58}) => Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: indent > 0 ? 0 : null,
      color: PortalDrawerTheme.panelBorder.withValues(alpha: 0.55),
    );
