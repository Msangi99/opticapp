import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/agent_dashboard_api.dart';
import '../../theme/app_theme.dart';
import 'agent_scaffold.dart';

/// Agent Dashboard: Overview of assignments, stats, and recent sales.
class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

enum _InventoryKind { assigned, remaining, sold }

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _inventoryCache;
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
      final data = await getAgentDashboardData();
      if (!mounted) return;
      setState(() {
        _data = data;
        _inventoryCache = null;
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
    final formatter = NumberFormat('#,##0');
    return '${formatter.format(value)} TZS';
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

  Future<Map<String, dynamic>> _inventoryFuture() {
    if (_inventoryCache != null) {
      return Future.value(_inventoryCache!);
    }
    return getAgentDashboardInventory().then((d) {
      if (mounted) setState(() => _inventoryCache = d);
      return d;
    });
  }

  void _openInventorySheet(_InventoryKind kind) {
    final title = switch (kind) {
      _InventoryKind.assigned => 'All assigned devices',
      _InventoryKind.remaining => 'Devices still with you',
      _InventoryKind.sold => 'Sold devices',
    };
    final listKey = switch (kind) {
      _InventoryKind.assigned => 'assigned',
      _InventoryKind.remaining => 'remaining',
      _InventoryKind.sold => 'sold',
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _InventorySheet(
          title: title,
          listKey: listKey,
          showStateChip: kind == _InventoryKind.assigned,
          future: _inventoryFuture(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AgentScaffold(
      title: 'Dashboard',
      showDrawer: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/agent/sell'),
        icon: const Icon(Icons.sell_rounded),
        label: const Text('Record Sale'),
        backgroundColor: const Color(0xFF232F3E),
        foregroundColor: Colors.white,
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
                  : _data == null
                      ? const Center(child: Text('No data available'))
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Products assigned to you. Record a sale when you sell to a customer.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              _buildStatsGrid(),
                              const SizedBox(height: 24),
                              _buildAssignments(),
                              const SizedBox(height: 24),
                              _buildRecentSales(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _data?['stats'] as Map<String, dynamic>? ?? {};
    final totalAssigned = stats['total_assigned'] as int? ?? 0;
    final totalSold = stats['total_sold'] as int? ?? 0;
    final totalRemaining = stats['total_remaining'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.blue,
                label: 'Assigned',
                value: totalAssigned.toString(),
                onTap: () => _openInventorySheet(_InventoryKind.assigned),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.green,
                label: 'Sold',
                value: totalSold.toString(),
                onTap: () => _openInventorySheet(_InventoryKind.sold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.pending_outlined,
                iconColor: Colors.orange,
                label: 'Remaining',
                value: totalRemaining.toString(),
                onTap: () => _openInventorySheet(_InventoryKind.remaining),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a card to see products and IMEIs',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildAssignments() {
    final assignmentsRaw = _data?['assignments'];
    final assignments = assignmentsRaw is List
        ? assignmentsRaw
        : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Assigned Products',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: sectionCardDecoration(context),
          child: assignments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No products assigned yet.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ...assignments.map((assignment) {
                      final a = assignment as Map<String, dynamic>;
                      final productName = a['product_name'] as String? ?? '–';
                      final categoryName = a['category_name'] as String? ?? '–';
                      final assigned = a['quantity_assigned'] as int? ?? 0;
                      final sold = a['quantity_sold'] as int? ?? 0;
                      final remaining = a['quantity_remaining'] as int? ?? 0;

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: remaining > 0
                              ? () => Navigator.pushNamed(context, '/agent/sell')
                              : null,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.phone_android_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '$categoryName – $productName',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          subtitle: Text(
                            'Assigned: $assigned · Sold: $sold · Remaining: $remaining',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          trailing: remaining > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Available',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'No stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildRecentSales() {
    final recentSalesRaw = _data?['recent_sales'];
    final recentSales = recentSalesRaw is List
        ? recentSalesRaw
        : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sales',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: sectionCardDecoration(context),
          child: recentSales.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No sales yet.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ...recentSales.map((sale) {
                      final s = sale as Map<String, dynamic>;
                      final customerName = s['customer_name'] as String? ?? '–';
                      final productName = s['product_name'] as String? ?? '–';
                      final totalValue = (s['total_selling_value'] as num?)?.toDouble() ?? 0.0;
                      final profit = (s['profit'] as num?)?.toDouble() ?? 0.0;
                      final date = s['date'] as String?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    customerName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                Text(
                                  _formatCurrency(totalValue),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              productName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (date != null)
                                  Text(
                                    _formatDate(date),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: sectionCardDecoration(context).copyWith(borderRadius: radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventorySheet extends StatelessWidget {
  final String title;
  final String listKey;
  final bool showStateChip;
  final Future<Map<String, dynamic>> future;

  const _InventorySheet({
    required this.title,
    required this.listKey,
    required this.showStateChip,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        snap.error.toString().replaceFirst('Exception: ', ''),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }
                  final inv = snap.data ?? {};
                  final raw = inv[listKey];
                  final list = raw is List ? raw : <dynamic>[];
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No devices in this list.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final row = list[i] as Map<String, dynamic>;
                      return _inventoryListTile(context, row, showStateChip);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _inventoryListTile(BuildContext context, Map<String, dynamic> row, bool showStateChip) {
    final category = row['category_name']?.toString() ?? '–';
    final product = row['product_name']?.toString() ?? '–';
    final imei = row['imei_number']?.toString() ?? '–';
    final model = row['model']?.toString();
    final state = row['state']?.toString();
    final customer = row['customer_name']?.toString();
    final soldAt = row['sold_at']?.toString();

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '$category · $product',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (showStateChip && state != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _StateChip(state: state),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'IMEI: $imei',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
            ),
            if (model != null && model.isNotEmpty && model != product) ...[
              const SizedBox(height: 4),
              Text(
                model,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (customer != null && customer.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Customer: $customer',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (soldAt != null && soldAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Sold: ${_formatSoldDate(soldAt)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatSoldDate(String iso) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _StateChip extends StatelessWidget {
  final String state;

  const _StateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final isRemaining = state == 'remaining';
    final label = isRemaining ? 'With you' : 'Sold';
    final color = isRemaining ? const Color(0xFFFA8900) : Colors.green.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
