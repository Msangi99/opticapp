import 'package:flutter/material.dart';
import '../../api/users_api.dart';
import 'admin_create_user_screen.dart';
import 'admin_scaffold.dart';
import 'admin_user_detail_screen.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_users_ui.dart';

class DealersScreen extends StatefulWidget {
  const DealersScreen({super.key});

  @override
  State<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends State<DealersScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getDealers();
      if (!mounted) return;
      setState(() { _list = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminCreateUserScreen(role: 'dealer')),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Dealers',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminUsersPageHeader(
            eyebrow: 'Partners',
            title: 'Dealers',
            subtitle: 'Review applications, approve accounts, and suspend when needed.',
            trailing: AdminPrimaryButton(label: 'Add dealer', onPressed: _openCreate, icon: Icons.add),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const AdminPageLoading();
    if (_error != null) return AdminPageError(message: _error!);
    if (_list.isEmpty) {
      return const AdminPageEmpty(icon: Icons.store_outlined, title: 'No dealers yet');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _list.length,
        itemBuilder: (context, index) {
          final u = _list[index];
          final id = (u['id'] as num?)?.toInt();
          return AdminUserListTile(
            user: u,
            showRole: false,
            onTap: id == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUserDetailScreen(userId: id, role: 'dealer'),
                      ),
                    ).then((_) => _load()),
            trailing: u['business_name'] != null
                ? Text(
                    u['business_name'].toString(),
                    style: TextStyle(fontSize: 12, color: kAdminTextMuted),
                  )
                : null,
          );
        },
      ),
    );
  }
}
