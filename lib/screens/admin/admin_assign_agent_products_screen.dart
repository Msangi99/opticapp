import 'dart:convert';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class AdminAssignAgentProductsScreen extends StatefulWidget {
  const AdminAssignAgentProductsScreen({super.key});

  @override
  State<AdminAssignAgentProductsScreen> createState() => _AdminAssignAgentProductsScreenState();
}

class _AdminAssignAgentProductsScreenState extends State<AdminAssignAgentProductsScreen> {
  List<Map<String, dynamic>> _agents = [];
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
      final res = await apiGet('/admin/users?role=agent&per_page=100');
      final data = jsonDecode(res.body);
      final list = (data is Map && data['data'] is List) ? (data['data'] as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() { _agents = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Agent Products',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : _agents.isEmpty
                  ? const AdminPageEmpty(icon: Icons.person_outline, title: 'No agents found')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _agents.length,
                        itemBuilder: (_, i) {
                          final a = _agents[i];
                          final name = a['name']?.toString() ?? '—';
                          final phone = a['phone']?.toString() ?? '';
                          final email = a['email']?.toString() ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: AdminSectionCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        if (phone.isNotEmpty) Text(phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                        if (email.isNotEmpty) Text(email, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.check_circle,
                                    color: a['status']?.toString() == 'active' ? Colors.green.shade600 : Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
