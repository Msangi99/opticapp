import 'package:flutter/material.dart';
import '../../api/distribution_sales_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_stock_ui.dart';
import 'widgets/admin_users_ui.dart';

class DistributionScreen extends StatefulWidget {
  const DistributionScreen({super.key});

  @override
  State<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends State<DistributionScreen> {
  List<Map<String, dynamic>> _list = [];
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
      final list = await getDistributionSales();
      if (!mounted) return;
      setState(() { _list = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  void _openDistribution(Map<String, dynamic> sale) {
    final id = _asInt(sale['id']);
    if (id == null) return;
    Navigator.pushNamed(
      context,
      '/admin/stock/distribution/info',
      arguments: {...sale, 'id': id},
    );
  }

  List<AdminStockStat> _summaryStats() {
    double totalSell = 0;
    double totalProfit = 0;
    var pending = 0;
    for (final s in _list) {
      totalSell += (s['total_selling_value'] as num?)?.toDouble() ?? 0;
      totalProfit += (s['profit'] as num?)?.toDouble() ?? 0;
      if ((s['status'] as String? ?? '').toLowerCase() == 'pending') pending++;
    }
    return [
      AdminStockStat(label: 'Records', value: formatCount(_list.length)),
      AdminStockStat(label: 'Total sales', value: formatTzs(totalSell)),
      AdminStockStat(label: 'Total profit', value: formatTzs(totalProfit), highlight: true, highlightColor: const Color(0xFF059669)),
      AdminStockStat(label: 'Pending', value: formatCount(pending), highlight: true, highlightColor: const Color(0xFFD97706)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Distribution sales',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.pushNamed(context, '/admin/stock/distribution/form');
          if (ok == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: AdminStockPageShell(
        eyebrow: 'Dealers',
        title: 'Distribution sales',
        subtitle: 'Sales to dealers (buy from purchases, sell from orders).',
        summaryLabel: _list.isEmpty ? null : 'Summary (current filter)',
        summaryStats: _list.isEmpty ? null : _summaryStats(),
        summaryColumns: 2,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const AdminPageLoading();
    if (_error != null) return AdminPageError(message: _error!);
    if (_list.isEmpty) {
      return const AdminPageEmpty(icon: Icons.local_shipping_outlined, title: 'No distribution sales yet');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _list.length,
        itemBuilder: (context, index) {
          final s = _list[index];
          final dealerName = s['dealer_name'] as String? ?? '–';
          final invoiceNumber = s['invoice_number'] as String? ?? '–';
          final productName = s['product_name'] as String? ?? '–';
          final total = (s['total_selling_value'] as num?)?.toDouble() ?? 0.0;
          final profit = (s['profit'] as num?)?.toDouble() ?? 0.0;
          final status = s['status'] as String? ?? 'pending';
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openDistribution(s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: sectionCardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(dealerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Invoice: $invoiceNumber', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                    Text(productName, style: TextStyle(color: kAdminTextMuted, fontSize: 13)),
                    Text('${formatTzs(total)} · profit ${formatTzs(profit)}', style: TextStyle(color: kAdminTextMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
