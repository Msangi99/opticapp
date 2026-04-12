import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/dashboard_api.dart';
import '../../api/product_list_api.dart';
import '../../api/agent_sales_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

/// Admin Dashboard: Overview of store performance with stats and financial metrics.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _agentSales = [];
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
      final data = await getDashboardData();
      List<Map<String, dynamic>> purchases = [];
      List<Map<String, dynamic>> agentSales = [];
      
      try {
        purchases = await getPurchases();
      } catch (_) {
        // If purchases fail, continue with empty list
      }
      
      try {
        agentSales = await getAgentSales();
      } catch (_) {
        // If agent sales fail, continue with empty list
      }
      
      if (!mounted) return;
      setState(() {
        _data = data;
        _purchases = purchases.take(5).toList();
        _agentSales = agentSales;
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

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      showDrawer: true,
      title: 'Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_box_rounded),
          onPressed: () => Navigator.pushNamed(context, '/admin/add-product'),
          tooltip: 'Add Product',
        ),
      ],
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
                              // Stats Grid
                              _buildStatsGrid(),
                              const SizedBox(height: 24),
                              // Sales Metrics (Today, WTD, MTD, YTD)
                              _buildSalesMetrics(),
                              const SizedBox(height: 24),
                              // Financial Metrics
                              _buildFinancialMetrics(),
                              const SizedBox(height: 24),
                              // Cash in Hand (Payment options)
                              _buildPaymentOptions(),
                              const SizedBox(height: 24),
                              // Top Selling Products
                              _buildTopProducts(),
                              const SizedBox(height: 24),
                              // Recent Orders
                              _buildRecentOrders(),
                              const SizedBox(height: 24),
                              // Recent Purchases
                              _buildRecentPurchases(),
                              const SizedBox(height: 24),
                              // Agent Sales
                              _buildAgentSales(),
                            ],
                          ),
                        ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final totalCustomers = _data?['total_customers'] as int? ?? 0;
    final totalOrders = _data?['total_orders'] as int? ?? 0;
    final totalProducts = _data?['total_products'] as int? ?? 0;
    final metrics = _data?['financial_metrics'] as Map<String, dynamic>?;
    final totalProductsInPurchases = metrics?['total_products_in_purchases'] ?? 0;

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
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 520;
            final cards = [
              _StatCard(
                icon: Icons.people_outline,
                iconColor: Colors.blue,
                label: 'Total Customers',
                value: totalCustomers.toString(),
              ),
              _StatCard(
                icon: Icons.shopping_bag_outlined,
                iconColor: Colors.purple,
                label: 'Total Orders',
                value: totalOrders.toString(),
              ),
              _StatCard(
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.green,
                label: 'Total Products',
                value: totalProducts.toString(),
              ),
              _StatCard(
                icon: Icons.fact_check_outlined,
                iconColor: Colors.teal,
                label: 'Total products in purchases',
                value: '$totalProductsInPurchases',
              ),
            ];
            if (narrow) {
              final half = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final c in cards) SizedBox(width: half, child: c)],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: cards[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFinancialMetrics() {
    final metrics = _data?['financial_metrics'] as Map<String, dynamic>?;
    if (metrics == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Payables, receivables, stock value, and profit overview.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: sectionCardDecoration(context),
          child: Column(
            children: [
              // First Row
              Row(
                children: [
                  Expanded(
                    child: _FinancialCard(
                      label: 'Payables',
                      value: _formatCurrency((metrics['payables'] as num?)?.toDouble()),
                      description: 'Total pending (not paid) from purchases',
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FinancialCard(
                      label: 'Receivables',
                      value: _formatCurrency((metrics['receivables'] as num?)?.toDouble()),
                      description: 'Pending from Distribution Sales',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FinancialCard(
                      label: 'Stock in Hand Value',
                      value: _formatCurrency((metrics['stock_in_hand_value'] as num?)?.toDouble()),
                      description: 'Total value of our stock',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FinancialCard(
                      label: 'Cash in Hand',
                      value: _formatCurrency((metrics['cash_in_hand'] as num?)?.toDouble()),
                      description: 'Total value of stocks given to agents',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              // Second Row
              Row(
                children: [
                  Expanded(
                    child: _FinancialCard(
                      label: 'Total Value',
                      value: _formatCurrency((metrics['total_value'] as num?)?.toDouble()),
                      description: 'Receivables + Stock in Hand + Cash in Hand',
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FinancialCard(
                      label: 'Gross Profit',
                      value: _formatCurrency((metrics['gross_profit'] as num?)?.toDouble()),
                      description: 'Distribution Sales + Agent Sales profit',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FinancialCard(
                      label: 'Total Expenses',
                      value: _formatCurrency((metrics['total_expenses'] as num?)?.toDouble()),
                      description: 'From Expenses section',
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FinancialCard(
                      label: 'Net Profit',
                      value: _formatCurrency((metrics['net_profit'] as num?)?.toDouble()),
                      description: 'Gross profit − Total expenses',
                      color: ((metrics['net_profit'] as num?)?.toDouble() ?? 0) >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FinancialCard(
                      label: 'Total Purchase Buy Price',
                      value: _formatCurrency((metrics['total_purchase_buy_price'] as num?)?.toDouble()),
                      description: 'Total buy price of all purchases',
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesMetrics() {
    final sales = _data?['sales_metrics'] as Map<String, dynamic>?;
    if (sales == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Mauzo ya leo, wiki, mwezi na mwaka.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _SalesMetricCard(
              label: 'Mauzo ya Leo',
              value: (sales['today'] as Map<String, dynamic>?)?['sales'] as num?,
              sub: (sales['today'] as Map<String, dynamic>?)?['percentage_change'] != null ? 'vs jana' : null,
              pct: (sales['today'] as Map<String, dynamic>?)?['percentage_change'] as num?,
              isIncrease: (sales['today'] as Map<String, dynamic>?)?['is_increase'] as bool? ?? true,
              color: Colors.blue,
            )),
            const SizedBox(width: 12),
            Expanded(child: _SalesMetricCard(
              label: 'WTD',
              value: (sales['wtd'] as Map<String, dynamic>?)?['sales'] as num?,
              sub: (sales['wtd'] as Map<String, dynamic>?)?['percentage_change'] != null ? 'vs wiki iliyopita' : null,
              pct: (sales['wtd'] as Map<String, dynamic>?)?['percentage_change'] as num?,
              isIncrease: (sales['wtd'] as Map<String, dynamic>?)?['is_increase'] as bool? ?? true,
              color: Colors.purple,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SalesMetricCard(
              label: 'MTD',
              value: (sales['mtd'] as Map<String, dynamic>?)?['sales'] as num?,
              sub: (sales['mtd'] as Map<String, dynamic>?)?['percentage_change'] != null ? 'vs mwezi uliopita' : null,
              pct: (sales['mtd'] as Map<String, dynamic>?)?['percentage_change'] as num?,
              isIncrease: (sales['mtd'] as Map<String, dynamic>?)?['is_increase'] as bool? ?? true,
              color: Colors.green,
            )),
            const SizedBox(width: 12),
            Expanded(child: _SalesMetricCard(
              label: 'YTD',
              value: (sales['ytd'] as Map<String, dynamic>?)?['sales'] as num?,
              sub: (sales['ytd'] as Map<String, dynamic>?)?['percentage_change'] != null ? 'vs mwaka uliopita' : null,
              pct: (sales['ytd'] as Map<String, dynamic>?)?['percentage_change'] as num?,
              isIncrease: (sales['ytd'] as Map<String, dynamic>?)?['is_increase'] as bool? ?? true,
              color: Colors.amber,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    final options = _data?['payment_options'];
    final list = options is List ? List<dynamic>.from(options) : <dynamic>[];
    if (list.isEmpty) return const SizedBox.shrink();
    double total = 0;
    for (final o in list) {
      if (o is Map && o['balance'] != null) total += (o['balance'] as num).toDouble();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash in Hand',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Payment options and their current balances',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        ...list.map<Widget>((o) {
          final opt = o as Map<String, dynamic>;
          final name = opt['name'] as String? ?? '–';
          final type = opt['type'] as String? ?? '';
          final balance = (opt['balance'] as num?)?.toDouble() ?? 0.0;
          final opening = (opt['opening_balance'] as num?)?.toDouble() ?? 0.0;
          final diff = balance - opening;
          final pct = opening != 0 ? (diff / opening) * 100 : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: sectionCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (type == 'mobile' ? Colors.blue : type == 'bank' ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: type == 'mobile' ? Colors.blue.shade700 : type == 'bank' ? Colors.green.shade700 : Colors.amber.shade700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_formatCurrency(balance), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Opening: ${_formatCurrency(opening)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                if (diff != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(diff > 0 ? Icons.trending_up : Icons.trending_down, size: 14, color: diff > 0 ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Text('${diff > 0 ? '+' : ''}${NumberFormat('#,##0').format(diff)} TZS (${NumberFormat('0.0').format(pct)}%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: diff > 0 ? Colors.green.shade700 : Colors.red.shade700)),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: sectionCardDecoration(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Cash in Hand', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(_formatCurrency(total), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopProducts() {
    final top = _data?['top_products'];
    final list = top is List ? List<dynamic>.from(top) : <dynamic>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Selling Products (Models)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Products sold by quantity',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: sectionCardDecoration(context),
          child: Column(
            children: [
              for (int i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(6)),
                        child: Text('${i + 1}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          (list[i] as Map<String, dynamic>)['model'] as String? ?? '–',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${(list[i] as Map<String, dynamic>)['total_quantity'] ?? 0} sold',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    final recentOrdersRaw = _data?['recent_orders'];
    final recentOrders = recentOrdersRaw is List
        ? recentOrdersRaw
        : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (recentOrders.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/admin/orders'),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: sectionCardDecoration(context),
          child: recentOrders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No recent orders.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ...recentOrders.map((order) {
                      final orderData = order as Map<String, dynamic>;
                      final id = orderData['id'] as int? ?? 0;
                      final customerName = orderData['customer_name'] as String? ?? 'Guest';
                      final totalPrice = (orderData['total_price'] as num?)?.toDouble() ?? 0.0;
                      final status = orderData['status'] as String? ?? 'pending';
                      final isCompleted = status == 'completed';

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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            '#$id',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          subtitle: Text(customerName),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(totalPrice),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? Colors.green.shade800 : Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildRecentPurchases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Purchases',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_purchases.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/admin/stocks'),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: sectionCardDecoration(context),
          child: _purchases.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No purchases yet.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ..._purchases.map((purchase) {
                      final name = purchase['name'] as String? ?? 'Purchase #${purchase['id']}';
                      final limit = purchase['limit']?.toString() ?? '0';
                      final available = purchase['available']?.toString() ?? '0';
                      final status = purchase['status']?.toString() ?? 'unknown';
                      final id = purchase['id'] as int?;

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
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          subtitle: Row(
                            children: [
                              _buildPurchaseChip('Limit: $limit', Colors.blue),
                              const SizedBox(width: 8),
                              _buildPurchaseChip('Available: $available', Colors.green),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(status),
                              ),
                            ),
                          ),
                          onTap: id != null
                              ? () => Navigator.pushNamed(
                                    context,
                                    '/admin/stocks/purchase',
                                    arguments: {'id': id, 'name': name},
                                  )
                              : null,
                        ),
                      );
                    }).toList(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPurchaseChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'complete':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAgentSales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Agent Sales',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: sectionCardDecoration(context),
          child: _agentSales.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No agent sales yet.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ..._agentSales.map((sale) {
                      final agentName = sale['agent_name'] as String? ?? 'Unknown';
                      final customerName = sale['customer_name'] as String? ?? '–';
                      final productName = sale['product_name'] as String? ?? '–';
                      final quantity = sale['quantity_sold'] as int? ?? 0;
                      final totalValue = (sale['total_selling_value'] as num?)?.toDouble() ?? 0.0;
                      final profit = (sale['profit'] as num?)?.toDouble() ?? 0.0;
                      final date = sale['date'] as String?;

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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.purple,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        agentName,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Customer: $customerName',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Product',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      Text(
                                        productName,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Qty: $quantity',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCurrency(totalValue),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
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
                            if (date != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Date: ${_formatDate(date)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
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

  String _formatDate(String? dateString) {
    if (dateString == null) return '–';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }
}

class _SalesMetricCard extends StatelessWidget {
  final String label;
  final num? value;
  final String? sub;
  final num? pct;
  final bool isIncrease;
  final Color color;

  const _SalesMetricCard({
    required this.label,
    required this.value,
    this.sub,
    this.pct,
    required this.isIncrease,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0');
    final valueStr = value != null ? '${formatter.format(value)} TZS' : '0 TZS';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.sell_rounded, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(valueStr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (sub != null && pct != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(isIncrease ? Icons.trending_up : Icons.trending_down, size: 14, color: isIncrease ? Colors.green : Colors.red),
                const SizedBox(width: 4),
                Text('${NumberFormat('0.0').format((pct ?? 0).abs())}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isIncrease ? Colors.green.shade700 : Colors.red.shade700)),
                const SizedBox(width: 4),
                Text(sub!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ],
          if (sub != null && pct == null)
            Text(sub!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final Color color;

  const _FinancialCard({
    required this.label,
    required this.value,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
