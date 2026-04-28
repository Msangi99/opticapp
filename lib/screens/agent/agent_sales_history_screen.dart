import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/agent_dashboard_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'agent_scaffold.dart';

class AgentSalesHistoryScreen extends StatefulWidget {
  const AgentSalesHistoryScreen({super.key});

  @override
  State<AgentSalesHistoryScreen> createState() => _AgentSalesHistoryScreenState();
}

class _AgentSalesHistoryScreenState extends State<AgentSalesHistoryScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  String _money(dynamic v) {
    final n = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    return '${NumberFormat('#,##0').format(n)} TZS';
  }

  String _date(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('MMM d, y').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getAgentSalesHistory();
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
    return AgentScaffold(
      title: 'Sales history',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _list.isEmpty
                      ? const AdminPageEmpty(icon: Icons.receipt_long_outlined, title: 'No sales history')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final s = _list[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(context, '/agent/sales/detail', arguments: {'id': s['id']}),
                                child: AdminSectionCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s['customer_name']?.toString() ?? '—', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      KeyValueRow(label: 'Product', value: '${s['category_name'] ?? '—'} - ${s['product_name'] ?? '—'}'),
                                      KeyValueRow(label: 'Total', value: _money(s['total_selling_value'])),
                                      KeyValueRow(label: 'Date', value: _date(s['date']?.toString())),
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
