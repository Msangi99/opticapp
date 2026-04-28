import 'package:flutter/material.dart';
import '../../api/product_list_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

/// Stocks page: list of purchases (name, limit, available, status).
class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key, this.pageTitle = 'Stocks'});

  final String pageTitle;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  List<Map<String, dynamic>> _purchases = [];
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
        _purchases = list;
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

  void _openPurchase(int id, String name) {
    Navigator.pushNamed(
      context,
      '/admin/stocks/purchase',
      arguments: {'id': id, 'name': name},
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'paid' || s == 'active' || s == 'available') return Colors.green;
    if (s == 'partial' || s == 'low' || s == 'warning') return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.pageTitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/admin/add-product'),
        icon: const Icon(Icons.add_box_rounded, color: Colors.black),
        label: const Text('Add Product', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFFA8900),
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading…', style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_error!, style: errorStyle()),
                        ),
                      ),
                    )
                  : _purchases.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No purchases yet',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add a purchase to get started',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _purchases.length,
                              itemBuilder: (context, index) {
                                final p = _purchases[index];
                                final name = p['name'] as String? ?? 'Purchase #${p['id']}';
                                final qty = _parseInt(p['limit'] ?? p['quantity']) ?? 0;
                                final status = p['available_status']?.toString() ?? p['status']?.toString() ?? 'unknown';
                                final id = _parseInt(p['id']);
                                final statusColor = _statusColor(status);
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: id == null ? null : () => _openPurchase(id, name),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: sectionCardDecoration(context),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Qty: $qty',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
    );
  }
}
