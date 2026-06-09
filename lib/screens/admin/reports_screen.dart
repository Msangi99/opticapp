import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/reports_api.dart';
import '../../api/client.dart';
import 'admin_scaffold.dart';
import 'report_branch_detail_screen.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_stock_ui.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _data;
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
      final data = await getReports();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  String _formatCurrency(double v) => '${NumberFormat('#,##0').format(v)} TZS';

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Sales Reports',
      actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Export agent stock CSV',
          onPressed: () async {
            try {
              final res = await apiGet('/admin/reports/agent-stock-export');
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res.statusCode == 200 ? 'CSV ready (${res.bodyBytes.length} bytes)' : 'Export failed')),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
        ),
      ],
      body: AdminStockPageShell(
        eyebrow: 'Operations',
        title: 'Sales Reports',
        subtitle: 'Sales summary, trends, and branch performance.',
        body: _loading
            ? const AdminPageLoading()
            : _error != null
                ? AdminPageError(message: _error!)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminStockSummaryPanel(
                            label: 'Summary',
                            margin: EdgeInsets.zero,
                            stats: [
                              AdminStockStat(
                                label: 'Total sales',
                                value: _formatCurrency((_data?['total_sales'] as num?)?.toDouble() ?? 0),
                                highlight: true,
                                highlightColor: const Color(0xFF059669),
                              ),
                              AdminStockStat(
                                label: 'Total orders',
                                value: '${_data?['total_orders'] ?? 0}',
                              ),
                              AdminStockStat(
                                label: 'Customers',
                                value: '${_data?['total_customers'] ?? 0}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Sales (last 7 days)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (_data?['sales_by_day'] is Map) ...(_data!['sales_by_day'] as Map).entries.map<Widget>((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key.toString(), style: Theme.of(context).textTheme.bodyMedium),
                                Text(_formatCurrency((e.value as num?)?.toDouble() ?? 0), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )).toList(),
                          const SizedBox(height: 20),
                          Text('Branches', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...(() {
                            final rows = _data?['branches_business'];
                            if (rows is! List) return <Widget>[const Text('No branch data')];
                            return rows.map<Widget>((raw) {
                              final b = raw as Map<String, dynamic>;
                              final branchName = b['name']?.toString() ?? 'Branch';
                              final branchId = (b['branch_id'] as num?)?.toInt();
                              final purchaseTotal = (b['purchase_total'] as num?)?.toDouble() ?? 0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: AdminSectionCard(
                                  child: InkWell(
                                    onTap: branchId == null
                                        ? null
                                        : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ReportBranchDetailScreen(branchId: branchId),
                                              ),
                                            ),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(branchName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                        Text(_formatCurrency(purchaseTotal)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.chevron_right_rounded),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList();
                          })(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
