import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/reports_api.dart';
import 'admin_scaffold.dart';

class ReportBranchDetailScreen extends StatefulWidget {
  const ReportBranchDetailScreen({super.key, required this.branchId});

  final int branchId;

  @override
  State<ReportBranchDetailScreen> createState() => _ReportBranchDetailScreenState();
}

class _ReportBranchDetailScreenState extends State<ReportBranchDetailScreen> {
  Map<String, dynamic> _data = {};
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
      final d = await getReportBranchDetail(widget.branchId);
      if (!mounted) return;
      setState(() {
        _data = d;
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

  String _fmt(double v) => '${NumberFormat('#,##0').format(v)} TZS';

  @override
  Widget build(BuildContext context) {
    final branchName = _data['branch_name']?.toString() ?? 'Branch';
    final purchases = (_data['purchases'] is List) ? (_data['purchases'] as List) : const [];
    final agents = (_data['agents'] is List) ? (_data['agents'] as List) : const [];
    final metricsDays = (_data['sales_metrics_days'] as num?)?.toInt() ?? 30;

    return AdminScaffold(
      title: branchName,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(padding: const EdgeInsets.all(16), child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Purchases',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (purchases.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            'No purchases for this branch.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        )
                      else
                        ...purchases.map<Widget>((raw) {
                          final p = raw as Map<String, dynamic>;
                          final name = p['name']?.toString() ?? 'Purchase';
                          final total = (p['total_amount'] as num?)?.toDouble() ?? 0;
                          final date = p['date']?.toString() ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(date),
                                const SizedBox(height: 4),
                                Text(_fmt(total)),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      Text(
                        'Sales team',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Units and revenue in the last $metricsDays days (branch-scoped stock, same rules as admin reports).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (agents.isEmpty)
                        Text(
                          'No agents linked to this branch yet.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        )
                      else
                        ...agents.map<Widget>((raw) {
                          final a = raw as Map<String, dynamic>;
                          final name = a['name']?.toString() ?? 'Agent';
                          final units = (a['sales_units'] as num?)?.toInt() ?? 0;
                          final revenue = (a['revenue_tzs'] as num?)?.toDouble() ?? 0.0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$units units · ${_fmt(revenue)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
