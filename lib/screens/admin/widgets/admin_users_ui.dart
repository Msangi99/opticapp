import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

const Color kAdminBrandDark = Color(0xFF232F3E);
const Color kAdminBrandOrange = Color(0xFFFA8900);
const Color kAdminTextMuted = Color(0xFF64748B);

class AdminUsersPageHeader extends StatelessWidget {
  const AdminUsersPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.75,
                        color: kAdminBrandOrange,
                        fontSize: 10,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: kAdminBrandDark,
                        letterSpacing: -0.35,
                        fontSize: 20,
                        height: 1.15,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kAdminTextMuted,
                          height: 1.3,
                          fontSize: 12.5,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class UserRoleFilterTab {
  const UserRoleFilterTab({
    required this.label,
    this.role,
    this.addLabel,
    this.addRole,
    this.assignRoute,
  });

  final String label;
  final String? role;
  final String? addLabel;
  final String? addRole;
  final String? assignRoute;
}

class UserDirectorySortOption {
  const UserDirectorySortOption({
    required this.sort,
    required this.direction,
    required this.label,
  });

  final String sort;
  final String direction;
  final String label;
}

const userDirectorySortOptions = [
  UserDirectorySortOption(sort: 'name', direction: 'asc', label: 'Name (A–Z)'),
  UserDirectorySortOption(sort: 'name', direction: 'desc', label: 'Name (Z–A)'),
  UserDirectorySortOption(sort: 'email', direction: 'asc', label: 'Email (A–Z)'),
  UserDirectorySortOption(sort: 'email', direction: 'desc', label: 'Email (Z–A)'),
  UserDirectorySortOption(sort: 'created_at', direction: 'desc', label: 'Newest first'),
  UserDirectorySortOption(sort: 'created_at', direction: 'asc', label: 'Oldest first'),
  UserDirectorySortOption(sort: 'status', direction: 'asc', label: 'Status (A–Z)'),
  UserDirectorySortOption(sort: 'status', direction: 'desc', label: 'Status (Z–A)'),
];

UserDirectorySortOption defaultUserDirectorySort(String? role) {
  if (role == null || role.isEmpty) {
    return userDirectorySortOptions[4];
  }
  if (['agent', 'teamleader', 'regional_manager', 'subadmin'].contains(role)) {
    return userDirectorySortOptions[0];
  }
  if (role == 'dealer') {
    return userDirectorySortOptions[4];
  }
  return userDirectorySortOptions[4];
}

UserDirectorySortOption userDirectorySortOptionFor(String sort, String direction) {
  for (final option in userDirectorySortOptions) {
    if (option.sort == sort && option.direction == direction) {
      return option;
    }
  }
  return userDirectorySortOptions[0];
}

class AdminUserSortBar extends StatelessWidget {
  const AdminUserSortBar({
    super.key,
    required this.sort,
    required this.direction,
    required this.onChanged,
  });

  final String sort;
  final String direction;
  final ValueChanged<UserDirectorySortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = userDirectorySortOptionFor(sort, direction);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort, size: 18, color: kAdminTextMuted),
            const SizedBox(width: 8),
            Text(
              'Sort',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: kAdminTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<UserDirectorySortOption>(
                  isExpanded: true,
                  value: selected,
                  items: userDirectorySortOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (option) {
                    if (option != null) onChanged(option);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminUserRoleFilterRow extends StatelessWidget {
  const AdminUserRoleFilterRow({
    super.key,
    required this.tabs,
    required this.selectedRole,
    required this.onSelect,
    this.onAdd,
    this.onAssign,
  });

  final List<UserRoleFilterTab> tabs;
  final String? selectedRole;
  final ValueChanged<String?> onSelect;
  final void Function(String role)? onAdd;
  final VoidCallback? onAssign;

  bool _isActive(UserRoleFilterTab tab) {
    if (tab.role == null) return selectedRole == null;
    return selectedRole == tab.role;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.map((tab) {
          final active = _isActive(tab);
          if (active && tab.addLabel != null && tab.addRole != null) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'add') {
                    onAdd?.call(tab.addRole!);
                  } else if (value == 'assign') {
                    onAssign?.call();
                  }
                },
                offset: const Offset(0, 40),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: 8),
                        Text(tab.addLabel!),
                      ],
                    ),
                  ),
                  if (tab.assignRoute != null)
                    const PopupMenuItem(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Assign devices'),
                        ],
                      ),
                    ),
                ],
                child: _FilterChip(label: tab.label, active: true, hasMenu: true),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelect(tab.role),
              borderRadius: BorderRadius.circular(999),
              child: _FilterChip(label: tab.label, active: active),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, this.hasMenu = false});

  final String label;
  final bool active;
  final bool hasMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? kAdminBrandDark : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? kAdminBrandDark : const Color(0xFFE2E8F0)),
        boxShadow: active
            ? [BoxShadow(color: kAdminBrandDark.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: active ? Colors.white : kAdminBrandDark,
            ),
          ),
          if (hasMenu) ...[
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: active ? Colors.white : kAdminBrandDark),
          ],
        ],
      ),
    );
  }
}

class UserRolePill extends StatelessWidget {
  const UserRolePill({super.key, required this.role});

  final String role;

  static String labelFor(String role) {
    switch (role) {
      case 'regional_manager':
        return 'Regional manager';
      case 'teamleader':
        return 'Team leader';
      case 'subadmin':
        return 'Admin';
      default:
        return role.isEmpty ? 'Customer' : role[0].toUpperCase() + role.substring(1);
    }
  }

  Color get _color {
    switch (role) {
      case 'admin':
      case 'subadmin':
        return const Color(0xFF7C3AED);
      case 'dealer':
        return const Color(0xFF0D9488);
      case 'agent':
        return const Color(0xFF4F46E5);
      case 'teamleader':
        return const Color(0xFF2563EB);
      case 'regional_manager':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labelFor(role),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class UserStatusPill extends StatelessWidget {
  const UserStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status == 'active';
    final pending = status == 'pending';
    final color = active
        ? const Color(0xFF059669)
        : pending
            ? const Color(0xFFD97706)
            : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class AdminUserListTile extends StatelessWidget {
  const AdminUserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.trailing,
    this.showRole = true,
  });

  final Map<String, dynamic> user;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showRole;

  @override
  Widget build(BuildContext context) {
    final name = user['name'] as String? ?? '–';
    final email = user['email'] as String? ?? '–';
    final role = user['role'] as String? ?? 'customer';
    final status = user['status'] as String? ?? 'active';
    final createdAt = user['created_at'] as String?;
    String joined = '–';
    if (createdAt != null) {
      try {
        joined = DateFormat('MMM d, y').format(DateTime.parse(createdAt));
      } catch (_) {
        joined = createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: sectionCardDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kAdminBrandOrange.withValues(alpha: 0.15),
                      child: Text(
                        (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                        style: const TextStyle(
                          color: kAdminBrandOrange,
                          fontWeight: FontWeight.w800,
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: kAdminBrandDark,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(email, style: TextStyle(color: kAdminTextMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (showRole) UserRolePill(role: role),
                    UserStatusPill(status: status),
                    ..._locationChips(user),
                    Text('Joined $joined', style: TextStyle(fontSize: 12, color: kAdminTextMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _locationChips(Map<String, dynamic> user) {
  final region = user['region_name'] as String?;
  final branch = user['branch_name'] as String?;
  final chips = <Widget>[];
  if (region != null && region.isNotEmpty) {
    chips.add(_LocationChip(label: 'Region', value: region));
  }
  if (branch != null && branch.isNotEmpty) {
    chips.add(_LocationChip(label: 'Branch', value: branch));
  }
  return chips;
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      ),
    );
  }
}

class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.add),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: kAdminBrandDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class AdminOutlineButton extends StatelessWidget {
  const AdminOutlineButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: kAdminBrandDark,
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({super.key, required this.value, required this.label, this.highlight = false});

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? const Color(0xFFFA8900) : const Color(0xFFCBD5E1);
    final valueColor = highlight ? const Color(0xFFB45309) : kAdminBrandDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            highlight ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
          ],
        ),
        border: Border.all(
          color: highlight ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 2.5,
            height: 30,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1.05,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: highlight ? const Color(0xFFB45309) : kAdminTextMuted,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
