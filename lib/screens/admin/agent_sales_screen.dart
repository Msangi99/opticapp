import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/agent_sales_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

/// Admin: full list of agent sales.
class AgentSalesScreen extends StatefulWidget {
  const AgentSalesScreen({super.key});

  @override
  State<AgentSalesScreen> createState() => _AgentSalesScreenState();
}

class _AgentSalesScreenState extends State<AgentSalesScreen> {
  List<Map<String, dynamic>> _list = [];
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
      final list = await getAgentSales();
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

  String _formatCurrency(double? value) {
    if (value == null) return '0';
    return '${NumberFormat('#,##0').format(value)} TZS';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '–';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Agent Sales',
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _list.isEmpty
                      ? const AdminPageEmpty(icon: Icons.person_pin_circle_outlined, title: 'No agent sales yet')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final s = _list[index];
                            final agentName = s['agent_name'] as String? ?? 'Unknown';
                            final customerName = s['customer_name'] as String? ?? '–';
                            final productName = s['product_name'] as String? ?? '–';
                            final categoryName = s['category_name'] as String? ?? '–';
                            final qty = (s['quantity_sold'] as num?)?.toInt() ?? 0;
                            final buy = (s['purchase_price'] as num?)?.toDouble() ?? 0.0;
                            final sell = (s['selling_price'] as num?)?.toDouble() ?? 0.0;
                            final totalBuy = (s['total_purchase_value'] as num?)?.toDouble() ?? 0.0;
                            final totalValue = (s['total_selling_value'] as num?)?.toDouble() ?? 0.0;
                            final profit = (s['profit'] as num?)?.toDouble() ?? 0.0;
                            final commission = (s['commission_paid'] as num?)?.toDouble() ?? 0.0;
                            final payment = s['payment_option_name']?.toString() ?? 'Not set';
                            final date = s['date'] as String?;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: AdminSectionCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.person_rounded, color: Colors.purple.shade700, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            agentName,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const StatusChip(label: 'Completed', color: Color(0xFF047857)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    KeyValueRow(label: 'Date', value: _formatDate(date)),
                                    KeyValueRow(label: 'Customer', value: customerName),
                                    KeyValueRow(label: 'Category', value: categoryName),
                                    KeyValueRow(label: 'Product', value: productName),
                                    KeyValueRow(label: 'Quantity', value: '$qty'),
                                    KeyValueRow(label: 'Buy price', value: _formatCurrency(buy)),
                                    KeyValueRow(label: 'Sell price', value: _formatCurrency(sell)),
                                    KeyValueRow(label: 'Total buy', value: _formatCurrency(totalBuy)),
                                    KeyValueRow(label: 'Payment', value: payment),
                                    KeyValueRow(label: 'Commission', value: _formatCurrency(commission)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatCurrency(totalValue),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                        ),
                                        Text(
                                          'Profit: ${_formatCurrency(profit)}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
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
