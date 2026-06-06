import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/agent_sales_api.dart';
import '../../api/invoice_api.dart';
import '../../api/payment_options_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_stock_ui.dart';

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

  int? _parseId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Future<void> _editSale(Map<String, dynamic> sale) async {
    final saleId = _parseId(sale['id']);
    if (saleId == null) return;

    List<Map<String, dynamic>> channels = [];
    try {
      channels = await getPaymentOptions();
    } catch (_) {}

    if (!mounted) return;
    int? channelId = _parseId(sale['payment_option_id']);
    final commissionController = TextEditingController(
      text: ((sale['commission_paid'] as num?)?.toDouble() ?? 0).toString(),
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Edit sale #$saleId', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  if (channels.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      value: channelId,
                      decoration: const InputDecoration(labelText: 'Payment channel'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Not set')),
                        ...channels.map((c) {
                          final id = _parseId(c['id']);
                          if (id == null) return null;
                          return DropdownMenuItem<int?>(
                            value: id,
                            child: Text(c['name']?.toString() ?? 'Channel'),
                          );
                        }).whereType<DropdownMenuItem<int?>>(),
                      ],
                      onChanged: (v) => setModalState(() => channelId = v),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commissionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Commission paid (TZS)'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      try {
                        if (channelId != null) {
                          await updateAgentSaleChannel(id: saleId, paymentOptionId: channelId!);
                        }
                        final commission = double.tryParse(commissionController.text.trim());
                        if (commission != null) {
                          await updateAgentSaleCommission(id: saleId, commissionPaid: commission);
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    commissionController.dispose();
    if (saved == true) _load();
  }

  Future<void> _saleActions(Map<String, dynamic> sale) async {
    final saleId = _parseId(sale['id']);
    if (saleId == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.receipt_long), title: const Text('Download invoice'), onTap: () => Navigator.pop(ctx, 'invoice')),
            ListTile(leading: const Icon(Icons.swap_horiz), title: const Text('Convert to credit'), onTap: () => Navigator.pop(ctx, 'convert')),
            ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete sale'), onTap: () => Navigator.pop(ctx, 'delete')),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    try {
      if (action == 'invoice') {
        await downloadReceiptAndNotify(context, endpoint: '/admin/agent-sales/$saleId/invoice', fallbackFilename: 'agent-sale-$saleId.pdf');
      } else if (action == 'convert') {
        await convertAgentSaleToCredit(saleId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Converted to credit.')));
        _load();
      } else if (action == 'delete') {
        await deleteAgentSale(saleId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale deleted.')));
        _load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalSell = 0;
    double totalProfit = 0;
    for (final s in _list) {
      totalSell += (s['total_selling_value'] as num?)?.toDouble() ?? 0;
      totalProfit += (s['profit'] as num?)?.toDouble() ?? 0;
    }
    final summary = _list.isEmpty
        ? null
        : [
            AdminStockStat(label: 'Sales', value: formatCount(_list.length)),
            AdminStockStat(label: 'Total selling', value: formatTzs(totalSell)),
            AdminStockStat(label: 'Total profit', value: formatTzs(totalProfit), highlight: true, highlightColor: const Color(0xFF059669)),
          ];

    return AdminScaffold(
      title: 'Agent cash sales',
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create sale',
        onPressed: () => Navigator.pushNamed(context, '/admin/stock/pending-sales'),
        child: const Icon(Icons.add),
      ),
      body: AdminStockPageShell(
        eyebrow: 'Agents',
        title: 'Agent sales',
        subtitle: 'All sales by agents, including pending; set payment channel as needed.',
        summaryLabel: summary == null ? null : 'Summary (current filter)',
        summaryStats: summary,
        summaryColumns: 1,
        body: _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_loading) return const AdminPageLoading();
    if (_error != null) return AdminPageError(message: _error!);
    if (_list.isEmpty) {
      return const AdminPageEmpty(icon: Icons.person_pin_circle_outlined, title: 'No agent sales yet');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _editSale(s),
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          label: const Text('Edit'),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _saleActions(s),
                                          icon: const Icon(Icons.more_horiz, size: 18),
                                          label: const Text('More'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
        },
      ),
    );
  }
}
