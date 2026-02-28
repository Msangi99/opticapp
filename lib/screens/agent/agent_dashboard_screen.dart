import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/client.dart';
import '../../api/agent_dashboard_api.dart';
import '../../theme/app_theme.dart';

/// Agent Dashboard: Overview of assignments, stats, and recent sales.
class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  Map<String, dynamic>? _data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sell_rounded),
            onPressed: () => Navigator.pushNamed(context, '/agent/sell'),
            tooltip: 'Sell Product',
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
                              // Assignments
                              _buildAssignments(),
                              const SizedBox(height: 24),
                              // Recent Sales
                              _buildRecentSales(),
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.green,
                label: 'Sold',
                value: totalSold.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.pending_outlined,
                iconColor: Colors.orange,
                label: 'Remaining',
                value: totalRemaining.toString(),
              ),
            ),
          ],
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
                                  child: Text(
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
