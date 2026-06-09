import 'package:flutter/material.dart';
import '../../api/stocks_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_stock_ui.dart';
import 'widgets/admin_users_ui.dart';

/// Stocks page: stock buckets with limits (mirrors web admin Stocks).
class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key, this.pageTitle = 'Stocks'});

  final String pageTitle;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  List<Map<String, dynamic>> _stocks = [];
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
      final list = await getStocks();
      if (!mounted) return;
      setState(() {
        _stocks = list;
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

  Color _statusColor(bool underLimit) => underLimit ? Colors.orange : Colors.green;

  List<AdminStockStat> _summaryStats() {
    var totalLimit = 0;
    var totalAdded = 0;
    var complete = 0;
    var pending = 0;
    for (final s in _stocks) {
      totalLimit += _parseInt(s['stock_limit'] ?? s['stock_quantity']) ?? 0;
      totalAdded += _parseInt(s['quantity'] ?? s['added']) ?? 0;
      if (s['under_limit'] == true) {
        pending++;
      } else {
        complete++;
      }
    }
    return [
      AdminStockStat(label: 'Rows', value: formatCount(_stocks.length)),
      AdminStockStat(label: 'Total limit qty', value: formatCount(totalLimit)),
      AdminStockStat(label: 'Total added', value: formatCount(totalAdded)),
      AdminStockStat(label: 'Complete', value: formatCount(complete), highlight: true, highlightColor: const Color(0xFF059669)),
      AdminStockStat(label: 'Pending', value: formatCount(pending), highlight: true, highlightColor: const Color(0xFFD97706)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.pageTitle,
      body: AdminStockPageShell(
        eyebrow: 'Inventory',
        title: 'Stocks',
        subtitle: 'Stock buckets for the app: quantities, purchases, and status.',
        trailing: AdminPrimaryButton(
          label: 'Add product (IMEI)',
          icon: Icons.add_box_rounded,
          onPressed: () => Navigator.pushNamed(context, '/admin/add-product'),
        ),
        summaryLabel: _stocks.isEmpty ? null : 'Summary',
        summaryStats: _stocks.isEmpty ? null : _summaryStats(),
        summaryColumns: 2,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const AdminPageLoading();
    if (_error != null) return AdminPageError(message: _error!);
    if (_stocks.isEmpty) {
      return const AdminPageEmpty(icon: Icons.inventory_2_outlined, title: 'No stocks yet');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _stocks.length,
        itemBuilder: (context, index) {
          final s = _stocks[index];
          final name = s['name'] as String? ?? 'Stock #${s['id']}';
          final limit = _parseInt(s['stock_limit'] ?? s['stock_quantity']) ?? 0;
          final qty = _parseInt(s['quantity'] ?? s['added']) ?? 0;
          final underLimit = s['under_limit'] == true;
          final fromPurchase = s['from_purchase'] == true;
          final statusColor = _statusColor(underLimit);
          final statusLabel = underLimit ? 'Pending' : 'Complete';
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (fromPurchase) {
                  Navigator.pushNamed(context, '/admin/purchases/info', arguments: {'id': s['id']});
                } else {
                  Navigator.pushNamed(context, '/admin/stocks/detail', arguments: {'id': s['id'], 'name': name});
                }
              },
              child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: sectionCardDecoration(context),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kAdminBrandOrange.withValues(alpha: 0.15),
                  child: Text(
                    (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                    style: const TextStyle(color: kAdminBrandOrange, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'Qty $qty / limit $limit',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kAdminTextMuted),
                      ),
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
                    statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
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
