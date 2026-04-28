import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/reports_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'report_branch_detail_screen.dart';
import 'widgets/admin_page_ui.dart';

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
      title: 'Reports',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _StatCard(icon: Icons.sell_rounded, label: 'Total Sales', value: _formatCurrency((_data?['total_sales'] as num?)?.toDouble() ?? 0), color: Colors.green)),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard(icon: Icons.receipt_long_rounded, label: 'Total Orders', value: '${_data?['total_orders'] ?? 0}', color: Colors.purple)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _StatCard(icon: Icons.people_rounded, label: 'Total Customers', value: '${_data?['total_customers'] ?? 0}', color: Colors.blue)),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 24),
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
