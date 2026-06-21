import 'package:flutter/material.dart';
import '../../api/users_api.dart';
import 'admin_scaffold.dart';
import 'admin_user_detail_screen.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_users_ui.dart';

class RegionalManagersScreen extends StatefulWidget {
  const RegionalManagersScreen({super.key});

  @override
  State<RegionalManagersScreen> createState() => _RegionalManagersScreenState();
}

class _RegionalManagersScreenState extends State<RegionalManagersScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String _sort = 'name';
  String _direction = 'asc';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getRegionalManagers(sort: _sort, direction: _direction);
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Regional managers',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminUsersPageHeader(
            eyebrow: 'Staff',
            title: 'Regional managers',
            subtitle: 'People who oversee a region and distribute devices.',
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
          Expanded(
            child: _loading
                ? const AdminPageLoading()
                : _error != null
                    ? AdminPageError(message: _error!)
                    : _list.isEmpty
                        ? const AdminPageEmpty(icon: Icons.public_outlined, title: 'No regional managers yet')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _list.length,
                              itemBuilder: (_, i) {
                                final u = _list[i];
                                final id = (u['id'] as num?)?.toInt();
                                return AdminUserListTile(
                                  user: u,
                                  showRole: false,
                                  onTap: id == null
                                      ? null
                                      : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AdminUserDetailScreen(userId: id, role: 'regional_manager'),
                                            ),
                                          ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
