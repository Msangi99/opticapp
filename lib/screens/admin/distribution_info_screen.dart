import 'package:flutter/material.dart';
import '../../api/distribution_sales_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

class DistributionInfoScreen extends StatefulWidget {
  const DistributionInfoScreen({super.key});

  @override
  State<DistributionInfoScreen> createState() => _DistributionInfoScreenState();
}

class _DistributionInfoScreenState extends State<DistributionInfoScreen> {
  Map<String, dynamic> _details = {};
  bool _loading = true;
  String? _error;
  int? _loadedId;

  Map<String, dynamic> _args(BuildContext context) {
    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is Map<String, dynamic>) return raw;
    return const {};
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _label(dynamic value, {String fallback = '—'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = _asInt(_args(context)['id']);
    if (id != null && id != _loadedId) {
      _load(id);
    } else if (id == null && _loading) {
      setState(() => _loading = false);
    }
  }

  Future<void> _load(int id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final details = await getDistributionSaleDetails(id);
      if (!mounted) return;
      setState(() {
        _details = details;
        _loadedId = id;
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

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args(context);
    final id = _asInt(args['id']);
    final data = _details.isNotEmpty ? _details : args;
    final title = 'Distribution #${_label(data['id'], fallback: '')}';
    final dealer = _label(data['dealer_name']);
    final seller = _label(data['seller_name']);
    final product = _label(data['product_name']);
    final category = _label(data['category_name']);
    final date = _label(data['date']);
    final quantity = _label(data['quantity_sold'], fallback: '0');
    final purchasePrice = _label(data['purchase_price']);
    final sellingPrice = _label(data['selling_price']);
    final totalBuy = _label(data['total_purchase_value']);
    final totalSell = _label(data['total_selling_value']);
    final paid = _label(data['paid_amount']);
    final pending = _label(data['pending_amount'] ?? data['balance']);
    final commission = _label(data['commission']);
    final profit = _label(data['profit']);
    final status = _label(data['status']);
    final channel = _label(data['payment_option_name']);
    final collectionDate = _label(data['collection_date']);
    final payments = (data['payments'] is List) ? (data['payments'] as List) : const [];

    return AdminScaffold(
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (id != null) await _load(id);
              },
              child: _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_error!, style: errorStyle()),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: sectionCardDecoration(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distribution Information',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              _infoRow(context, 'Date', date),
                              _infoRow(context, 'Dealer', dealer),
                              _infoRow(context, 'Seller', seller),
                              _infoRow(context, 'Category', category),
                              _infoRow(context, 'Product', product),
                              _infoRow(context, 'Quantity', quantity),
                              _infoRow(context, 'Buy Price', purchasePrice),
                              _infoRow(context, 'Sell Price', sellingPrice),
                              _infoRow(context, 'Total Buy', totalBuy),
                              _infoRow(context, 'Total Sell', totalSell),
                              _infoRow(context, 'Paid', paid),
                              _infoRow(context, 'Pending', pending),
                              _infoRow(context, 'Commission', commission),
                              _infoRow(context, 'Profit', profit),
                              _infoRow(context, 'Status', status),
                              _infoRow(context, 'Payment Channel', channel),
                              _infoRow(context, 'Collection Date', collectionDate),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: sectionCardDecoration(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment History',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              if (payments.isEmpty)
                                Text(
                                  'No payment history recorded yet.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                )
                              else
                                ...payments.map((row) {
                                  final map = row is Map ? Map<String, dynamic>.from(row) : <String, dynamic>{};
                                  final paidDate = _label(map['paid_date']);
                                  final paymentChannel = _label(map['payment_option_name']);
                                  final amount = _label(map['amount']);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('• $paidDate · $paymentChannel · $amount'),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
