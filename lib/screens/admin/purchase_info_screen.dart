import 'package:flutter/material.dart';
import '../../api/product_list_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

/// Purchase info page used by Purchases tab.
class PurchaseInfoScreen extends StatefulWidget {
  const PurchaseInfoScreen({super.key});

  @override
  State<PurchaseInfoScreen> createState() => _PurchaseInfoScreenState();
}

class _PurchaseInfoScreenState extends State<PurchaseInfoScreen> {
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
      final details = await getPurchaseDetails(id);
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

  @override
  Widget build(BuildContext context) {
    final args = _args(context);
    final id = _asInt(args['id']);
    final data = _details.isNotEmpty ? _details : args;
    final title = _label(data['name'], fallback: 'Purchase');
    final invoice = _label(data['name']);
    final date = _label(data['date']);
    final branch = _label(data['branch_name']);
    final supplier = _label(data['distributor_name'] ?? data['supplier_name'] ?? data['supplier']);
    final product = _label(data['product_name']);
    final quantity = _label(data['quantity'] ?? data['limit'], fallback: '0');
    final unit = _label(data['unit_price']);
    final paid = _label(data['paid_amount']);
    final pending = _label(data['pending_amount']);
    final total = _label(data['total_amount'] ?? data['buy_price_total']);
    final sellPrice = _label(data['sell_price']);
    final paymentStatus = _label(data['payment_status'] ?? data['status']);
    final paymentChannel = _label(data['payment_option_name']);
    final available = _label(data['available']);
    final availableStatus = _label(data['available_status']);
    final createdAt = _label(data['created_at']);
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
                                'Purchase Information',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              _infoRow(context, 'Invoice', invoice),
                              _infoRow(context, 'Date', date),
                              _infoRow(context, 'Branch', branch),
                              _infoRow(context, 'Supplier', supplier),
                              _infoRow(context, 'Product', product),
                              _infoRow(context, 'Quantity', quantity),
                              _infoRow(context, 'Unit Price', unit),
                              _infoRow(context, 'Total', total),
                              _infoRow(context, 'Paid', paid),
                              _infoRow(context, 'Pending', pending),
                              _infoRow(context, 'Sell Price', sellPrice),
                              _infoRow(context, 'Payment Status', paymentStatus),
                              _infoRow(context, 'Payment Channel', paymentChannel),
                              _infoRow(context, 'Available', available),
                              _infoRow(context, 'Stock Status', availableStatus),
                              _infoRow(context, 'Created At', createdAt),
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
                                  final channel = _label(map['payment_option_name']);
                                  final amount = _label(map['amount']);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('• $paidDate · $channel · $amount'),
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

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
}
