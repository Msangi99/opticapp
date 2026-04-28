import 'package:flutter/material.dart';
import '../../api/agent_catalog_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'agent_scaffold.dart';

class AgentLeadDetailScreen extends StatefulWidget {
  const AgentLeadDetailScreen({super.key});

  @override
  State<AgentLeadDetailScreen> createState() => _AgentLeadDetailScreenState();
}

class _AgentLeadDetailScreenState extends State<AgentLeadDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  int? _asInt(dynamic v) => v is int ? v : int.tryParse(v.toString());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_detail != null || !_loading) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = _asInt(args['id']);
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Missing lead id.';
      });
      return;
    }
    _load(id);
  }

  Future<void> _load(int id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getAgentCustomerNeedDetail(id);
      if (!mounted) return;
      setState(() {
        _detail = data;
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
    final d = _detail ?? {};
    return AgentScaffold(
      title: 'Lead detail',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AdminSectionCard(
                      child: Column(
                        children: [
                          KeyValueRow(label: 'Customer', value: d['customer_name']?.toString() ?? '—'),
                          KeyValueRow(label: 'Phone', value: d['customer_phone']?.toString() ?? '—'),
                          KeyValueRow(label: 'Category', value: d['category']?.toString() ?? '—'),
                          KeyValueRow(label: 'Model', value: d['product']?.toString() ?? '—'),
                          KeyValueRow(label: 'Branch', value: d['branch']?.toString() ?? '—'),
                          KeyValueRow(label: 'Submitted', value: d['created_at']?.toString() ?? '—'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
