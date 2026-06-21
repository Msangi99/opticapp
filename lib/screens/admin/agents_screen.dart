import 'package:flutter/material.dart';
import '../../api/users_api.dart';
import 'admin_scaffold.dart';
import 'admin_user_detail_screen.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_users_ui.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String _sort = 'name';
  String _direction = 'asc';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getAgents(sort: _sort, direction: _direction);
      if (!mounted) return;
      setState(() { _list = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Agents',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminUsersPageHeader(
            eyebrow: 'Sales team',
            title: 'Agents',
            subtitle: 'Manage agents and assign products for them to sell.',
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
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const AdminPageLoading();
    if (_error != null) return AdminPageError(message: _error!);
    if (_list.isEmpty) {
      return const AdminPageEmpty(icon: Icons.person_search_outlined, title: 'No agents yet');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
                        builder: (_) => AdminUserDetailScreen(userId: id, role: 'agent'),
                      ),
                    ).then((_) => _load()),
          );
        },
      ),
    );
  }
}
