import 'package:flutter/material.dart';
import '../../api/agent_catalog_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'agent_scaffold.dart';

class AgentLeadsScreen extends StatefulWidget {
  const AgentLeadsScreen({super.key});

  @override
  State<AgentLeadsScreen> createState() => _AgentLeadsScreenState();
}

class _AgentLeadsScreenState extends State<AgentLeadsScreen> {
  List<Map<String, dynamic>> _leads = [];
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
      final rows = await getAgentCustomerNeeds();
      if (!mounted) return;
      setState(() {
        _leads = rows;
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
    return AgentScaffold(
      title: 'Leads',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _leads.isEmpty
                      ? const AdminPageEmpty(icon: Icons.person_search_outlined, title: 'No submitted leads')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _leads.length,
                          itemBuilder: (context, i) {
                            final row = _leads[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(context, '/agent/leads/detail', arguments: {'id': row['id']}),
                                child: AdminSectionCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(row['customer_name']?.toString() ?? '—', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      KeyValueRow(label: 'Phone', value: row['customer_phone']?.toString() ?? '—'),
                                      KeyValueRow(label: 'Product', value: '${row['category'] ?? '—'} - ${row['product'] ?? '—'}'),
                                      KeyValueRow(label: 'Branch', value: row['branch']?.toString() ?? '—'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
