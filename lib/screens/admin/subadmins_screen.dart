import 'package:flutter/material.dart';
import '../../api/users_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'admin_user_detail_screen.dart';

class SubadminsScreen extends StatefulWidget {
  const SubadminsScreen({super.key});

  @override
  State<SubadminsScreen> createState() => _SubadminsScreenState();
}

class _SubadminsScreenState extends State<SubadminsScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getSubadmins();
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
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Leaders',
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: errorStyle()));
    }
    if (_list.isEmpty) {
      return const Center(child: Text('No leaders yet'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (context, index) {
          final u = _list[index];
          final id = (u['id'] as num?)?.toInt();
          return InkWell(
            onTap: id == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUserDetailScreen(userId: id, role: 'subadmin'),
                      ),
                    ).then((_) => _load()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: sectionCardDecoration(context),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u['name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(u['email']?.toString() ?? ''),
                      ],
                    ),
                  ),
                  Text((u['status'] as String? ?? 'active').toUpperCase()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
