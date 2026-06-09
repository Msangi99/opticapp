import 'package:flutter/material.dart';

import '../../api/admin_modules_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class StockReceiptsScreen extends StatefulWidget {
  const StockReceiptsScreen({super.key});

  @override
  State<StockReceiptsScreen> createState() => _StockReceiptsScreenState();
}

class _StockReceiptsScreenState extends State<StockReceiptsScreen> {
  List<Map<String, dynamic>> _receipts = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) return;
    final stockId = args['stock_id'] as int?;
    if (stockId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final r = await getStockReceipts(stockId);
      if (!mounted) return;
      setState(() { _receipts = r; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Stock Receipts',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : _receipts.isEmpty
                  ? const AdminPageEmpty(icon: Icons.receipt_long, title: 'No receipts')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _receipts.length,
                        itemBuilder: (_, i) {
                          final r = _receipts[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: AdminSectionCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['receipt_number']?.toString() ?? 'Receipt #${r['id']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(r['description']?.toString() ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  if (r['amount'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Amount: ${r['amount']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                  if (r['date'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(r['date'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  ],
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
