import 'package:flutter/material.dart';
import '../../api/stocks_api.dart';
import 'admin_scaffold.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  int? _stockId(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['id'] != null) {
      final id = args['id'];
      if (id is int) return id;
      return int.tryParse(id.toString());
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final id = _stockId(context);
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Invalid stock';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getStockDetail(id);
      if (!mounted) return;
      setState(() {
        _data = data;
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
    final name = _data?['name']?.toString() ?? 'Stock';
    final purchases = (_data?['purchases'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final receipts = (_data?['receipts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final stockId = _stockId(context);

    return AdminScaffold(
      title: name,
      actions: stockId != null
          ? [
              IconButton(
                icon: const Icon(Icons.qr_code_2),
                tooltip: 'View IMEIs',
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/admin/stocks/imei',
                  arguments: {'id': stockId, 'name': name},
                ),
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long),
                tooltip: 'Receipts',
                onPressed: () => Navigator.pushNamed(context, '/admin/stock-receipts', arguments: {'stock_id': stockId}),
              ),
            ]
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantity: ${_data?['quantity'] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
                              Text('Limit: ${_data?['stock_limit'] ?? 0}'),
                              if (stockId != null) ...[
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/admin/stocks/imei',
                                    arguments: {'id': stockId, 'name': name},
                                  ),
                                  icon: const Icon(Icons.qr_code_2, size: 20),
                                  label: const Text('View IMEIs in stock'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Purchases', style: Theme.of(context).textTheme.titleSmall),
                      ...purchases.map((p) => ListTile(
                            title: Text(p['name']?.toString() ?? ''),
                            subtitle: Text('${p['date']} · ${p['payment_status']}'),
                          )),
                      const SizedBox(height: 16),
                      Text('Receipts', style: Theme.of(context).textTheme.titleSmall),
                      ...receipts.map((r) => ListTile(
                            leading: r['payment_receipt_url'] != null
                                ? Image.network(r['payment_receipt_url'].toString(), width: 40, height: 40, fit: BoxFit.cover)
                                : const Icon(Icons.receipt),
                            title: Text(r['name']?.toString() ?? ''),
                            subtitle: Text(r['date']?.toString() ?? ''),
                          )),
                    ],
                  ),
                ),
    );
  }
}
