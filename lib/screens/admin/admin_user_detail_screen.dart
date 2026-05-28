import 'package:flutter/material.dart';
import '../../api/users_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

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

  @override
  Widget build(BuildContext context) {
    final u = _user;
    return AdminScaffold(
      title: 'User',
      body: _loading
          ? const AdminPageLoading()
          : u == null
              ? const AdminPageEmpty(icon: Icons.person_off, title: 'User not found')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AdminSectionCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['name']?.toString() ?? '–', style: Theme.of(context).textTheme.titleLarge),
                          Text(u['email']?.toString() ?? ''),
                          Text('Role: ${u['role']} · Status: ${u['status']}'),
                          if (u['phone'] != null) Text('Phone: ${u['phone']}'),
                          if (u['business_name'] != null) Text('Business: ${u['business_name']}'),
                          if (u['branch_name'] != null) Text('Branch: ${u['branch_name']}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.role == 'dealer' && u['status'] == 'pending') ...[
                      FilledButton(
                        onPressed: () => _action(() => approveDealer(widget.userId)),
                        child: const Text('Approve dealer'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _action(() => rejectDealer(widget.userId)),
                        child: const Text('Reject dealer'),
                      ),
                    ],
                    if (u['status'] == 'active')
                      OutlinedButton(
                        onPressed: () => _action(() => deactivateUser(widget.userId)),
                        child: const Text('Deactivate'),
                      ),
                    if (u['status'] != 'active' && u['status'] != 'pending')
                      FilledButton(
                        onPressed: () => _action(() => activateUser(widget.userId)),
                        child: const Text('Activate'),
                      ),
                  ],
                ),
    );
  }
}
