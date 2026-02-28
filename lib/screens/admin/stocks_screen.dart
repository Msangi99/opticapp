import 'package:flutter/material.dart';
import '../../api/client.dart';
import '../../api/product_list_api.dart';
import '../../theme/app_theme.dart';

/// Stocks page: list of purchases (name, limit, available, status). Tap name → purchase detail.
class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

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

  Future<void> _logout() async {
    await clearStoredAuth();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Stocks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin/dashboard'),
          tooltip: 'Back to Dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: () => Navigator.pushReplacementNamed(context, '/admin/add-product'),
            tooltip: 'Add Product',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Log out',
          ),
        ],
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
                                final limit = p['limit']?.toString() ?? '0';
                                final available = p['available']?.toString() ?? '0';
                                final status = p['status']?.toString() ?? 'unknown';
                                final id = p['id'] as int?;
                                final limitNum = int.tryParse(limit) ?? 0;
                                final availableNum = int.tryParse(available) ?? 0;
                                final isLowStock = availableNum < (limitNum * 0.2);
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: id != null
                                          ? () => Navigator.pushNamed(
                                                context,
                                                '/admin/stocks/purchase',
                                                arguments: {'id': id, 'name': name},
                                              )
                                          : null,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primaryContainer,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.inventory_2_rounded,
                                                    color: Theme.of(context).colorScheme.primary,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                              fontWeight: FontWeight.bold,
                                                              color: Theme.of(context).colorScheme.onSurface,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      _buildStatusChip(context, status),
                                                    ],
                                                  ),
                                                ),
                                                if (id != null)
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(
                                                      Icons.chevron_right_rounded,
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      size: 20,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildStatItem(
                                                    context,
                                                    Icons.trending_up_rounded,
                                                    'Limit',
                                                    limit,
                                                    Colors.blue,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: _buildStatItem(
                                                    context,
                                                    Icons.check_circle_outline_rounded,
                                                    'Available',
                                                    available,
                                                    isLowStock ? Colors.red : Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'active':
      case 'available':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
        break;
      case 'low':
      case 'warning':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.warning_rounded;
        break;
      case 'out':
      case 'empty':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel_rounded;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.info_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
