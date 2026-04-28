import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/agent_dashboard_api.dart';
import '../../api/invoice_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'agent_scaffold.dart';

class AgentSaleDetailScreen extends StatefulWidget {
  const AgentSaleDetailScreen({super.key});

  @override
  State<AgentSaleDetailScreen> createState() => _AgentSaleDetailScreenState();
}

class _AgentSaleDetailScreenState extends State<AgentSaleDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  int? _asInt(dynamic v) => v is int ? v : int.tryParse(v.toString());
  String _money(dynamic v) {
    final n = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    return '${NumberFormat('#,##0').format(n)} TZS';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_detail != null || !_loading) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = _asInt(args['id']);
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Missing sale id.';
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
      final data = await getAgentSaleDetail(id);
      if (!mounted) return;
      setState(() {
        _detail = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _downloadInvoice() async {
    final endpoint = _detail?['invoice_endpoint']?.toString();
    if (endpoint == null || endpoint.isEmpty) return;
    final path = await downloadInvoicePdf(endpoint: endpoint, fallbackFilename: 'agent-sale-invoice.pdf');
    if (!mounted) return;
    await openDownloadedFile(path);
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail ?? {};
    return AgentScaffold(
      title: 'Sale detail',
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
                          Text(d['customer_name']?.toString() ?? '—', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          KeyValueRow(label: 'Product', value: '${d['category_name'] ?? '—'} - ${d['product_name'] ?? '—'}'),
                          KeyValueRow(label: 'IMEI', value: d['imei_number']?.toString() ?? '—'),
                          KeyValueRow(label: 'Price', value: _money(d['selling_price'])),
                          KeyValueRow(label: 'Total', value: _money(d['total_selling_value'])),
                          KeyValueRow(label: 'Profit', value: _money(d['profit'])),
                          KeyValueRow(label: 'Payment', value: d['payment_option']?.toString() ?? '—'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _downloadInvoice,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download invoice'),
                    ),
                  ],
                ),
    );
  }
}
