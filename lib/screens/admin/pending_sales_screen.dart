import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/payment_options_api.dart';
import '../../api/pending_sales_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class PendingSalesScreen extends StatefulWidget {
  const PendingSalesScreen({super.key});

  @override
  State<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends State<PendingSalesScreen> {
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _paymentOptions = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getPendingSales();
      final paymentOptions = await getPaymentOptions();
      if (!mounted) return;
      setState(() {
        _list = list;
        _paymentOptions = paymentOptions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  String _formatCurrency(double v) => '${NumberFormat('#,##0').format(v)} TZS';
  String _formatDate(String? date) {
    if (date == null || date.trim().isEmpty) return '–';
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  Future<void> _showFinalizeDialog(Map<String, dynamic> sale) async {
    final id = sale['id'];
    final int? saleId = id is int ? id : (id is num ? id.toInt() : null);
    if (saleId == null) return;

    int? selectedPaymentOptionId;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Finalize pending sale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Customer: ${sale['customer_name'] ?? '–'}'),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: selectedPaymentOptionId,
                decoration: const InputDecoration(
                  labelText: 'Payment channel',
                  border: OutlineInputBorder(),
                ),
                items: _paymentOptions
                    .map((p) {
                      final pid = p['id'];
                      final int? parsed = pid is int ? pid : (pid is num ? pid.toInt() : null);
                      if (parsed == null) return null;
                      final name = p['name']?.toString() ?? 'Channel #$parsed';
                      return DropdownMenuItem<int>(value: parsed, child: Text(name));
                    })
                    .whereType<DropdownMenuItem<int>>()
                    .toList(),
                onChanged: (v) => setLocalState(() => selectedPaymentOptionId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving || selectedPaymentOptionId == null
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await savePendingSale(
                          id: saleId,
                          paymentOptionId: selectedPaymentOptionId!,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pending sale finalized.')),
                        );
                        _load();
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                        );
                      }
                    },
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Pending Sales',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : _list.isEmpty
                  ? const AdminPageEmpty(
                      icon: Icons.pending_actions_outlined,
                      title: 'No pending sales yet',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (context, index) {
                          final s = _list[index];
                          final customerName = s['customer_name'] as String? ?? '–';
                          final sellerName = s['seller_name'] as String? ?? '–';
                          final productName = s['product_name'] as String? ?? '–';
                          final categoryName = s['category_name'] as String? ?? '–';
                          final qty = (s['quantity_sold'] as num?)?.toInt() ?? 0;
                          final buy = (s['purchase_price'] as num?)?.toDouble() ?? 0.0;
                          final sell = (s['selling_price'] as num?)?.toDouble() ?? 0.0;
                          final total = (s['total_selling_value'] as num?)?.toDouble() ?? 0.0;
                          final profit = (s['profit'] as num?)?.toDouble() ?? 0.0;
                          final paymentOption = s['payment_option_name']?.toString() ?? 'Not set';
                          final date = _formatDate(s['date']?.toString());
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: AdminSectionCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person_rounded, color: Colors.amber.shade700, size: 20)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(customerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                                    const StatusChip(label: 'Pending', color: Color(0xFFB45309)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                KeyValueRow(label: 'Date', value: date),
                                KeyValueRow(label: 'Seller', value: sellerName),
                                KeyValueRow(label: 'Category', value: categoryName),
                                KeyValueRow(label: 'Product', value: productName),
                                KeyValueRow(label: 'Quantity', value: '$qty'),
                                KeyValueRow(label: 'Buy price', value: _formatCurrency(buy)),
                                KeyValueRow(label: 'Sell price', value: _formatCurrency(sell)),
                                KeyValueRow(label: 'Payment', value: paymentOption),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatCurrency(total), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                    Text('Profit: ${_formatCurrency(profit)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.tonalIcon(
                                    onPressed: _saving ? null : () => _showFinalizeDialog(s),
                                    icon: const Icon(Icons.save_rounded, size: 18),
                                    label: const Text('Save to agent sales'),
                                  ),
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
