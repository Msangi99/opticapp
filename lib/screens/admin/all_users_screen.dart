import 'package:flutter/material.dart';

import '../../api/users_api.dart';
import 'admin_scaffold.dart';
import 'admin_create_user_screen.dart';
import 'admin_user_detail_screen.dart';
import 'assign_regional_manager_devices_screen.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_users_ui.dart';

const _roleFilters = [
  UserRoleFilterTab(label: 'All', role: null),
  UserRoleFilterTab(label: 'Admins', role: 'subadmin', addLabel: 'Add admin', addRole: 'subadmin'),
  UserRoleFilterTab(label: 'Agents', role: 'agent', addLabel: 'Add agent', addRole: 'agent'),
  UserRoleFilterTab(
    label: 'Team leaders',
    role: 'teamleader',
    addLabel: 'Add team leader',
    addRole: 'teamleader',
  ),
  UserRoleFilterTab(
    label: 'Regional managers',
    role: 'regional_manager',
    addLabel: 'Add regional manager',
    addRole: 'regional_manager',
    assignRoute: '/admin/regional-managers/assign-devices',
  ),
];

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String? _selectedRole;
  late String _sort;
  late String _direction;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    final defaults = defaultUserDirectorySort(_selectedRole);
    _sort = defaults.sort;
    _direction = defaults.direction;
    _load();
  }

  void _applyRoleDefaults(String? role) {
    final defaults = defaultUserDirectorySort(role);
    _sort = defaults.sort;
    _direction = defaults.direction;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getUsersByRole(_selectedRole, sort: _sort, direction: _direction);
      if (!mounted) return;
      setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openCreate(String role) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminCreateUserScreen(role: role)),
    );
    if (created == true) _load();
  }

  Future<void> _openAssignDevices() async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AssignRegionalManagerDevicesScreen()),
    );
    if (done == true) _load();
  }

  Future<void> _openUser(Map<String, dynamic> user) async {
    final id = (user['id'] as num?)?.toInt();
    if (id == null) return;
    final role = user['role'] as String? ?? 'customer';
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: id, role: role)),
    );
    _load();
  }

  Future<void> _showActionsSheet(Map<String, dynamic> user) async {
    final id = (user['id'] as num?)?.toInt();
    if (id == null) return;
    final role = user['role'] as String? ?? '';
    final status = user['status'] as String? ?? 'active';
    final isAdmin = role == 'admin';
    final isActive = status == 'active';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openUser(user);
                },
              ),
              if (role == 'regional_manager' && isActive)
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Assign device'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignRegionalManagerDevicesScreen(
                          initialRegionalManagerId: id,
                        ),
                      ),
                    ).then((done) {
                      if (done == true) _load();
                    });
                  },
                ),
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Reset Password'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showResetPassword(id);
                },
              ),
              if (!isAdmin && isActive)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Deactivate', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _confirmAction(
                      title: 'Deactivate user?',
                      message: 'They will not be able to log in until reactivated.',
                      action: () => deactivateUser(id),
                    );
                  },
                ),
              if (!isAdmin && !isActive && status != 'pending')
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  title: const Text('Activate', style: TextStyle(color: Colors.green)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _confirmAction(
                      title: 'Activate user?',
                      message: 'They will be able to log in again.',
                      action: () => activateUser(id),
                    );
                  },
                ),
              if (!isAdmin)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _confirmAction(
                      title: 'Delete user?',
                      message: 'This cannot be undone.',
                      destructive: true,
                      action: () => deleteUser(id),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showResetPassword(int id) async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) {
      password.dispose();
      confirm.dispose();
      return;
    }
    final pwd = password.text;
    final pwdConfirm = confirm.text;
    password.dispose();
    confirm.dispose();
    try {
      await resetUserPassword(id, pwd, pwdConfirm);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required Future<void> Function() action,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await action();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Done')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'All users',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminUsersPageHeader(eyebrow: 'Users', title: 'All users'),
          const SizedBox(height: 12),
          AdminUserRoleFilterRow(
            tabs: _roleFilters,
            selectedRole: _selectedRole,
            onSelect: (role) {
              setState(() {
                _selectedRole = role;
                _applyRoleDefaults(role);
              });
              _load();
            },
            onAdd: _openCreate,
            onAssign: _openAssignDevices,
          ),
          AdminUserSortBar(
            sort: _sort,
            direction: _direction,
            onChanged: (option) {
              setState(() {
                _sort = option.sort;
                _direction = option.direction;
              });
              _load();
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AdminPageLoading();
    if (_error != null) return AdminPageError(message: _error!);
    if (_list.isEmpty) {
      return const AdminPageEmpty(
        icon: Icons.people_outline,
        title: 'No users found',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _list.length,
        itemBuilder: (context, index) {
          final user = _list[index];
          return AdminUserListTile(
            user: user,
            onTap: () => _openUser(user),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showActionsSheet(user),
            ),
          );
        },
      ),
    );
  }
}

/// Backward-compatible alias used by existing route.
class CustomersScreen extends AllUsersScreen {
  const CustomersScreen({super.key}) : super(initialRole: null);
}
