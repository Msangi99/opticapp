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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildWelcomeHero(BuildContext context) {
    final metrics = _data?['financial_metrics'] as Map<String, dynamic>?;
    final net = (metrics?['net_profit'] as num?)?.toDouble();
    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.38),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _greeting(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.12,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here is your store at a glance.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          if (metrics != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net profit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(net),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (net != null)
                    Icon(
                      net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: net >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171),
                      size: 30,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
                color: const Color(0xFF0F172A),
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      showDrawer: true,
      title: 'Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.add_box_rounded),
          onPressed: () => Navigator.pushNamed(context, '/admin/add-product'),
          tooltip: 'Add Product',
        ),
      ],
      body: _loading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Syncing dashboard…',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sales, inventory, and payments',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF94A3B8),
                          ),
                    ),
                  ],
                ),
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
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: proCardDecoration(context, outline: true).copyWith(
                            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.25),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 28),
                              const SizedBox(width: 14),
                              Expanded(child: Text(_error!, style: errorStyle())),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _data == null
                      ? const Center(child: Text('No data available'))
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWelcomeHero(context),
                              const SizedBox(height: 24),
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
        _sectionHeading(
          'Overview',
          'Customers, orders, and catalog footprint.',
        ),
        _OverviewMetricsPanel(
          totalCustomers: totalCustomers,
          totalOrders: totalOrders,
          totalProducts: totalProducts,
          totalProductsInPurchases: '$totalProductsInPurchases',
        ),
      ],
    );
  }

  Widget _buildFinancialMetrics() {
    final metrics = _data?['financial_metrics'] as Map<String, dynamic>?;
    if (metrics == null) return const SizedBox.shrink();

    final net = (metrics['net_profit'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Financial summary',
          'Payables, receivables, stock value, and profit overview.',
        ),
        Container(
          decoration: proCardDecoration(context, outline: true, radius: 20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _financialMetricRow(
                'Payables',
                _formatCurrency((metrics['payables'] as num?)?.toDouble()),
                'Total pending (not paid) from purchases',
                Colors.amber.shade700,
              ),
              _thinListDivider(),
              _financialMetricRow(
                'Receivables',
                _formatCurrency((metrics['receivables'] as num?)?.toDouble()),
                'Pending from distribution sales',
                Colors.blue.shade700,
              ),
              _thinListDivider(),
              _financialMetricRow(
                'Stock in hand value',
                _formatCurrency((metrics['stock_in_hand_value'] as num?)?.toDouble()),
                'Total value of our stock',
                const Color(0xFF059669),
              ),
              _thinListDivider(),
              _financialMetricRow(
                'Cash in hand (agents)',
                _formatCurrency((metrics['cash_in_hand'] as num?)?.toDouble()),
                'Total value of stock given to agents',
                const Color(0xFF7C3AED),
              ),
              _thinListDivider(),
              _financialMetricRow(
                'Total value',
                _formatCurrency((metrics['total_value'] as num?)?.toDouble()),
                'Receivables + stock in hand + cash in hand',
                const Color(0xFF64748B),
              ),
              _thinListDivider(),
              _financialMetricRow(
                'Gross profit',
                _formatCurrency((metrics['gross_profit'] as num?)?.toDouble()),
                'Distribution sales + agent sales profit',
                const Color(0xFF059669),
              ),
              _thinListDivider(),
              _financialMetricRow(
                'Total expenses',
                _formatCurrency((metrics['total_expenses'] as num?)?.toDouble()),
                'From expenses section',
                const Color(0xFFDC2626),
              ),
              _thinListDivider(),
              _financialMetricRow(
                'Net profit',
                _formatCurrency((metrics['net_profit'] as num?)?.toDouble()),
                'Gross profit − total expenses',
                net >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
              _thinListDivider(),
              _financialMetricRow(
                'Total purchase buy price',
                _formatCurrency((metrics['total_purchase_buy_price'] as num?)?.toDouble()),
                'Total buy price of all purchases',
                const Color(0xFF4F46E5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thinListDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFFE2E8F0).withValues(alpha: 0.88),
    );
  }

  Widget _financialMetricRow(String label, String value, String description, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentBar(color: accent, height: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                        color: const Color(0xFF334155),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.35,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesMetrics() {
    final sales = _data?['sales_metrics'] as Map<String, dynamic>?;
    if (sales == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Sales',
          'Mauzo ya leo, wiki, mwezi na mwaka.',
        ),
        _SalesMetricsListPanel(sales: sales),
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
        _sectionHeading(
          'Cash in hand',
          'Payment options and their current balances.',
        ),
        Container(
          decoration: proCardDecoration(context, outline: true, radius: 20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) _thinListDivider(),
                _cashChannelRow(list[i] as Map<String, dynamic>),
              ],
              _thinListDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AccentBar(color: Theme.of(context).colorScheme.primary, height: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Total cash in hand',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                      ),
                    ),
                    Text(
                      _formatCurrency(total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cashChannelRow(Map<String, dynamic> opt) {
    final name = opt['name'] as String? ?? '–';
    final type = opt['type'] as String? ?? '';
    final balance = (opt['balance'] as num?)?.toDouble() ?? 0.0;
    final opening = (opt['opening_balance'] as num?)?.toDouble() ?? 0.0;
    final diff = balance - opening;
    final pct = opening != 0 ? (diff / opening) * 100 : 0.0;
    final accent = type == 'mobile'
        ? Colors.blue.shade700
        : type == 'bank'
            ? Colors.green.shade700
            : Colors.amber.shade800;
    final badgeColor = type == 'mobile'
        ? Colors.blue
        : type == 'bank'
            ? Colors.green
            : Colors.amber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentBar(color: accent, height: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: type == 'mobile'
                              ? Colors.blue.shade800
                              : type == 'bank'
                                  ? Colors.green.shade800
                                  : Colors.amber.shade900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(balance),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: const Color(0xFF334155),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Opening: ${_formatCurrency(opening)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                ),
                if (diff != 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        diff > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 16,
                        color: diff > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${diff > 0 ? '+' : ''}${NumberFormat('#,##0').format(diff)} TZS (${NumberFormat('0.0').format(pct)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: diff > 0 ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.account_balance_wallet_outlined, color: accent.withValues(alpha: 0.35), size: 24),
        ],
      ),
    );
  }

  Widget _recentOrderRow(Map<String, dynamic> orderData) {
    final id = orderData['id'] as int? ?? 0;
    final customerName = orderData['customer_name'] as String? ?? 'Guest';
    final totalPrice = (orderData['total_price'] as num?)?.toDouble() ?? 0.0;
    final status = orderData['status'] as String? ?? 'pending';
    final isCompleted = status == 'completed';
    final accent = isCompleted ? const Color(0xFF059669) : const Color(0xFFD97706);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentBar(color: accent, height: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$id',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  customerName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(totalPrice),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF059669).withValues(alpha: 0.12)
                      : const Color(0xFFD97706).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: isCompleted ? const Color(0xFF047857) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentPurchaseRow(Map<String, dynamic> purchase) {
    final name = purchase['name'] as String? ?? 'Purchase #${purchase['id']}';
    final limit = purchase['limit']?.toString() ?? '0';
    final available = purchase['available']?.toString() ?? '0';
    final status = purchase['status']?.toString() ?? 'unknown';
    final id = purchase['id'] as int?;
    final accent = _getStatusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: id != null
            ? () => Navigator.pushNamed(
                  context,
                  '/admin/stocks/purchase',
                  arguments: {'id': id, 'name': name},
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AccentBar(color: accent, height: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildPurchaseChip('Limit: $limit', Colors.blue),
                        _buildPurchaseChip('Available: $available', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    final top = _data?['top_products'];
    final list = top is List ? List<dynamic>.from(top) : <dynamic>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Top selling models',
          'Products sold by quantity.',
        ),
        Container(
          decoration: proCardDecoration(context, outline: true, radius: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          color: const Color(0xFF0F172A),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Latest activity from your store.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            if (recentOrders.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/admin/orders'),
                child: const Text('View all'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: proCardDecoration(context, outline: true, radius: 20),
          child: recentOrders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      'No recent orders.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < recentOrders.length; i++) ...[
                      if (i > 0) _thinListDivider(),
                      _recentOrderRow(recentOrders[i] as Map<String, dynamic>),
                    ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent purchases',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          color: const Color(0xFF0F172A),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stock intake and payment status.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            if (_purchases.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/admin/stocks'),
                child: const Text('View all'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: proCardDecoration(context, outline: true, radius: 20),
          child: _purchases.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      'No purchases yet.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _purchases.length; i++) ...[
                      if (i > 0) _thinListDivider(),
                      _recentPurchaseRow(_purchases[i]),
                    ],
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
        _sectionHeading(
          'Recent agent sales',
          'Field sales and margins.',
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: proCardDecoration(context, outline: true, radius: 20),
          child: _agentSales.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      'No agent sales yet.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _agentSales.length; i++) ...[
                      if (i > 0) _thinListDivider(),
                      _agentSaleRow(_agentSales[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _agentSaleRow(Map<String, dynamic> sale) {
    final agentName = sale['agent_name'] as String? ?? 'Unknown';
    final customerName = sale['customer_name'] as String? ?? '–';
    final productName = sale['product_name'] as String? ?? '–';
    final quantity = sale['quantity_sold'] as int? ?? 0;
    final totalValue = (sale['total_selling_value'] as num?)?.toDouble() ?? 0.0;
    final profit = (sale['profit'] as num?)?.toDouble() ?? 0.0;
    final date = sale['date'] as String?;
    const accent = Color(0xFF7C3AED);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentBar(color: accent, height: 88),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agentName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer: $customerName',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Qty $quantity',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Text(' · ', style: TextStyle(color: Color(0xFFCBD5E1))),
                    Text(
                      _formatCurrency(totalValue),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const Text(' · ', style: TextStyle(color: Color(0xFFCBD5E1))),
                    Text(
                      'Profit ${_formatCurrency(profit)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF047857),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                if (date != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.handshake_outlined, color: accent.withValues(alpha: 0.35), size: 24),
        ],
      ),
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

/// Single panel, 2×2 grid with top accent strips (distinct from floating KPI cards).
class _OverviewMetricsPanel extends StatelessWidget {
  const _OverviewMetricsPanel({
    required this.totalCustomers,
    required this.totalOrders,
    required this.totalProducts,
    required this.totalProductsInPurchases,
  });

  final int totalCustomers;
  final int totalOrders;
  final int totalProducts;
  final String totalProductsInPurchases;

  static const _divider = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: proCardDecoration(context, outline: true, radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(color: _divider.withValues(alpha: 0.9), width: 1),
        ),
        defaultColumnWidth: const FlexColumnWidth(1),
        children: [
          TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: _OverviewMetricCell(
                  icon: Icons.people_outline_rounded,
                  accent: const Color(0xFF2563EB),
                  label: 'Total customers',
                  value: totalCustomers.toString(),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: _OverviewMetricCell(
                  icon: Icons.shopping_bag_outlined,
                  accent: const Color(0xFF7C3AED),
                  label: 'Total orders',
                  value: totalOrders.toString(),
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: _OverviewMetricCell(
                  icon: Icons.inventory_2_outlined,
                  accent: const Color(0xFF059669),
                  label: 'Total products',
                  value: totalProducts.toString(),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: _OverviewMetricCell(
                  icon: Icons.fact_check_outlined,
                  accent: const Color(0xFF0D9488),
                  label: 'Products in purchases',
                  value: totalProductsInPurchases,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetricCell extends StatelessWidget {
  const _OverviewMetricCell({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent,
                accent.withValues(alpha: 0.2),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: const Color(0xFF0F172A),
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One outlined card; each period is a full-width row with vertical accent bar.
class _SalesMetricsListPanel extends StatelessWidget {
  const _SalesMetricsListPanel({required this.sales});

  final Map<String, dynamic> sales;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? m(String key) => sales[key] as Map<String, dynamic>?;

    Widget row({
      required String label,
      required String mapKey,
      required Color color,
    }) {
      final block = m(mapKey);
      final value = block?['sales'] as num?;
      final sub = block?['percentage_change'] != null
          ? (mapKey == 'today'
              ? 'vs jana'
              : mapKey == 'wtd'
                  ? 'vs wiki iliyopita'
                  : mapKey == 'mtd'
                      ? 'vs mwezi uliopita'
                      : 'vs mwaka uliopita')
          : null;
      final pct = block?['percentage_change'] as num?;
      final isIncrease = block?['is_increase'] as bool? ?? true;
      return _SalesMetricRow(
        label: label,
        value: value,
        sub: sub,
        pct: pct,
        isIncrease: isIncrease,
        color: color,
      );
    }

    return Container(
      decoration: proCardDecoration(context, outline: true, radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          row(label: 'Mauzo ya leo', mapKey: 'today', color: const Color(0xFF2563EB)),
          Divider(height: 1, thickness: 1, color: const Color(0xFFE2E8F0).withValues(alpha: 0.85)),
          row(label: 'WTD', mapKey: 'wtd', color: const Color(0xFF7C3AED)),
          Divider(height: 1, thickness: 1, color: const Color(0xFFE2E8F0).withValues(alpha: 0.85)),
          row(label: 'MTD', mapKey: 'mtd', color: const Color(0xFF059669)),
          Divider(height: 1, thickness: 1, color: const Color(0xFFE2E8F0).withValues(alpha: 0.85)),
          row(label: 'YTD', mapKey: 'ytd', color: const Color(0xFFD97706)),
        ],
      ),
    );
  }
}

class _SalesMetricRow extends StatelessWidget {
  const _SalesMetricRow({
    required this.label,
    required this.value,
    this.sub,
    this.pct,
    required this.isIncrease,
    required this.color,
  });

  final String label;
  final num? value;
  final String? sub;
  final num? pct;
  final bool isIncrease;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0');
    final valueStr = value != null ? '${formatter.format(value)} TZS' : '0 TZS';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentBar(color: color, height: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  valueStr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                        color: const Color(0xFF334155),
                      ),
                ),
                if (sub != null && pct != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 16,
                        color: isIncrease ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${NumberFormat('0.0').format((pct ?? 0).abs())}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isIncrease ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sub!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (sub != null && pct == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      sub!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.show_chart_rounded, color: color.withValues(alpha: 0.35), size: 26),
        ],
      ),
    );
  }
}

/// Shared vertical accent used across dashboard list panels.
class _AccentBar extends StatelessWidget {
  const _AccentBar({required this.color, this.height = 52});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color,
            color.withValues(alpha: 0.45),
          ],
        ),
      ),
    );
  }
}
