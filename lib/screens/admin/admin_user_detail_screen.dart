import 'package:flutter/material.dart';
import '../../api/users_api.dart';
import 'admin_scaffold.dart';
import 'assign_regional_manager_devices_screen.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_users_ui.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId, required this.role});

  final int userId;
  final String role;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final u = await getUserDetail(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = u;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _action(Future<void> Function() fn) async {
    try {
      await fn();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Done')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _resetPassword() async {
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
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
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
    await _action(() => resetUserPassword(widget.userId, pwd, pwdConfirm));
  }

  Future<void> _deleteUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await deleteUser(widget.userId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    final role = u?['role'] as String? ?? widget.role;
    final status = u?['status'] as String? ?? 'active';
    final isAdmin = role == 'admin';

    return AdminScaffold(
      title: 'User',
      body: _loading
          ? const AdminPageLoading()
          : u == null
              ? const AdminPageEmpty(icon: Icons.person_off, title: 'User not found')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AdminUserListTile(user: u, showRole: true),
                    const SizedBox(height: 16),
                    AdminSectionCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (u['phone'] != null) KeyValueRow(label: 'Phone', value: u['phone'].toString()),
                          if (u['business_name'] != null) KeyValueRow(label: 'Business', value: u['business_name'].toString()),
                          if (u['branch_name'] != null) KeyValueRow(label: 'Branch', value: u['branch_name'].toString()),
                          if (u['region_name'] != null) KeyValueRow(label: 'Region', value: u['region_name'].toString()),
                          if (u['team_leader_name'] != null) KeyValueRow(label: 'Team leader', value: u['team_leader_name'].toString()),
                          if (u['regional_manager_name'] != null) KeyValueRow(label: 'Regional manager', value: u['regional_manager_name'].toString()),
                          if (u['subadmin_role_name'] != null) KeyValueRow(label: 'Role', value: u['subadmin_role_name'].toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (role == 'regional_manager' && status == 'active')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignRegionalManagerDevicesScreen(
                                initialRegionalManagerId: widget.userId,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Assign devices'),
                          style: FilledButton.styleFrom(backgroundColor: kAdminBrandDark),
                        ),
                      ),
                    if (widget.role == 'dealer' && status == 'pending') ...[
                      FilledButton(
                        onPressed: () => _action(() => approveDealer(widget.userId)),
                        child: const Text('Approve dealer'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _action(() => rejectDealer(widget.userId)),
                        child: const Text('Reject dealer'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.role == 'agent') ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final branchId = int.tryParse(await showDialog<String>(
                                context: context,
                                builder: (ctx) {
                                  final c = TextEditingController(text: u['branch_id']?.toString() ?? '');
                                  return AlertDialog(
                                    title: const Text('Transfer branch'),
                                    content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Branch ID (blank to clear)')),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
                                    ],
                                  );
                                },
                              ) ??
                              '');
                          await transferAgentBranch(widget.userId, branchId);
                          _load();
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Transfer branch'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final tlId = int.tryParse(await showDialog<String>(
                                context: context,
                                builder: (ctx) {
                                  final c = TextEditingController(text: u['team_leader_id']?.toString() ?? '');
                                  return AlertDialog(
                                    title: const Text('Assign team leader'),
                                    content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Team leader user ID')),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
                                    ],
                                  );
                                },
                              ) ??
                              '');
                          await updateAgentTeamLeader(widget.userId, tlId);
                          _load();
                        },
                        icon: const Icon(Icons.supervisor_account_outlined),
                        label: const Text('Set team leader'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: _resetPassword,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Reset password'),
                    ),
                    const SizedBox(height: 8),
                    if (!isAdmin && status == 'active')
                      OutlinedButton(
                        onPressed: () => _action(() => deactivateUser(widget.userId)),
                        child: const Text('Deactivate'),
                      ),
                    if (!isAdmin && status != 'active' && status != 'pending')
                      FilledButton(
                        onPressed: () => _action(() => activateUser(widget.userId)),
                        child: const Text('Activate'),
                      ),
                    if (!isAdmin) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: _deleteUser,
                        child: const Text('Delete user'),
                      ),
                    ],
                  ],
                ),
    );
  }
}
