import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/agent_credits_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'agent_scaffold.dart';

class AgentCreditDetailScreen extends StatefulWidget {
  const AgentCreditDetailScreen({super.key});

  @override
  State<AgentCreditDetailScreen> createState() => _AgentCreditDetailScreenState();
}

class _AgentCreditDetailScreenState extends State<AgentCreditDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  int? _asInt(dynamic v) => v is int ? v : int.tryParse(v.toString());
  double _asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
  String _money(dynamic v) => '${NumberFormat('#,##0.##').format(_asDouble(v))} TZS';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_detail != null || !_loading) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = _asInt(args['id']);
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Missing credit id.';
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
      final data = await getAgentCreditDetail(id);
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
    final payments = (d['payments'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return AgentScaffold(
      title: 'Credit detail',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['customer_name']?.toString() ?? '—',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          KeyValueRow(label: 'Product', value: d['product_label']?.toString() ?? '—'),
                          KeyValueRow(label: 'IMEI', value: d['imei_number']?.toString() ?? '—'),
                          KeyValueRow(label: 'Total', value: _money(d['total_amount'])),
                          KeyValueRow(label: 'Paid', value: _money(d['paid_amount'])),
                          KeyValueRow(label: 'Remaining', value: _money(d['remaining'])),
                          KeyValueRow(label: 'Status', value: d['payment_status']?.toString() ?? '—'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Installment history', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (payments.isEmpty)
                      const AdminPageEmpty(icon: Icons.payments_outlined, title: 'No installment payments yet')
                    else
                      ...payments.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AdminSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                KeyValueRow(label: 'Amount', value: _money(p['amount'])),
                                KeyValueRow(label: 'Date', value: p['paid_date']?.toString() ?? '—'),
                                KeyValueRow(
                                  label: 'Channel',
                                  value: p['payment_option']?['name']?.toString() ?? '—',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
