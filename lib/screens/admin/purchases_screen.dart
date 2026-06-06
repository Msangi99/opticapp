import 'package:flutter/material.dart';
import '../../api/purchases_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_stock_ui.dart';
import 'widgets/admin_users_ui.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
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
      final list = await getPurchases();
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

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'paid') return Colors.green;
    if (s == 'partial') return Colors.orange;
    return Colors.red;
  }

  void _openPurchase(int id, Map<String, dynamic> purchase) {
    Navigator.pushNamed(
      context,
      '/admin/purchases/info',
      arguments: {
        ...purchase,
        'id': id,
        'name': purchase['name']?.toString() ?? 'Purchase',
      },
    );
  }

  List<AdminStockStat> _summaryStats() {
    var paid = 0;
    var partial = 0;
    var unpaid = 0;
    for (final p in _list) {
      final st = (p['payment_status']?.toString() ?? p['status']?.toString() ?? '').toLowerCase();
      if (st == 'paid') {
        paid++;
      } else if (st == 'partial') {
        partial++;
      } else {
        unpaid++;
      }
    }
    return [
      AdminStockStat(label: 'Purchases', value: formatCount(_list.length)),
      AdminStockStat(label: 'Paid', value: formatCount(paid), highlight: true, highlightColor: const Color(0xFF059669)),
      AdminStockStat(label: 'Partial', value: formatCount(partial)),
      AdminStockStat(label: 'Unpaid', value: formatCount(unpaid), highlight: true, highlightColor: const Color(0xFFDC2626)),
    ];
  }

  Future<void> _exportCsv() async {
    try {
      final size = await downloadPurchaseCsvBytes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported ($size bytes). Open web admin for file download if needed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _bulkUpdatePrices() async {
    try {
      await updateAllProductPrices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product prices updated.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Purchases',
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'export') _exportCsv();
            if (v == 'prices') _bulkUpdatePrices();
            if (v == 'receipts') Navigator.pushNamed(context, '/admin/purchases/receipts');
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'export', child: Text('Export CSV')),
            PopupMenuItem(value: 'prices', child: Text('Update all prices')),
            PopupMenuItem(value: 'receipts', child: Text('View receipts')),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.pushNamed(context, '/admin/purchases/form');
          if (ok == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: AdminStockPageShell(
        eyebrow: 'Inventory',
        title: 'Purchases',
        subtitle: 'Stock purchases, payments, and sell prices.',
        summaryLabel: _list.isEmpty ? null : 'Summary',
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
      return const AdminPageEmpty(icon: Icons.receipt_long_outlined, title: 'No purchases found');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _list.length,
        itemBuilder: (context, index) {
          final p = _list[index];
          final id = _parseInt(p['id']);
          final invoice = p['name']?.toString() ?? 'Purchase';
          final qty = _parseInt(p['quantity'] ?? p['limit']) ?? 0;
          final payStatus = p['payment_status']?.toString() ?? p['status']?.toString() ?? 'pending';
          final statusColor = _statusColor(payStatus);
          final product = p['product_name']?.toString();

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: id == null ? null : () => _openPurchase(id, p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: sectionCardDecoration(context),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(invoice, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          if (product != null && product.isNotEmpty)
                            Text(product, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kAdminTextMuted)),
                          Text('Qty $qty · ${p['date'] ?? ''}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kAdminTextMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payStatus.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
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
