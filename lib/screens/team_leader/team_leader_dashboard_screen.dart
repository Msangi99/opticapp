import 'package:flutter/material.dart';
import '../../api/team_leader_api.dart';
import '../../theme/app_theme.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'team_leader_scaffold.dart';

class TeamLeaderDashboardScreen extends StatefulWidget {
  const TeamLeaderDashboardScreen({super.key});

  @override
  State<TeamLeaderDashboardScreen> createState() => _TeamLeaderDashboardScreenState();
}

class _TeamLeaderDashboardScreenState extends State<TeamLeaderDashboardScreen> {
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
      final data = await getTeamLeaderDashboard();
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
    return TeamLeaderScaffold(
      title: 'Team overview',
      showDrawer: true,
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _data == null
                      ? const AdminPageEmpty(
                          icon: Icons.groups_outlined,
                          title: 'No dashboard data',
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAssignmentCard(),
                              const SizedBox(height: 20),
                              _buildStatsGrid(),
                              if (_pendingSaleCount > 0) ...[
                                const SizedBox(height: 16),
                                _buildPendingBanner(),
                              ],
                              const SizedBox(height: 24),
                              _buildCustodyProducts(),
                              _buildProductTable(),
                              const SizedBox(height: 24),
                              _buildAgentsList(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
    );
  }

  Map<String, dynamic> get _leader =>
      _data?['leader'] as Map<String, dynamic>? ?? {};

  Map<String, dynamic> get _stats => _data?['stats'] as Map<String, dynamic>? ?? {};

  int get _pendingSaleCount => _stats['pending_sale_imei_count'] as int? ?? 0;

  Widget _buildAssignmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your assignment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _leader['name'] as String? ?? '—',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          _infoRow('Branch', _leader['branch_name'] as String? ?? '—'),
          _infoRow('Region', _leader['region_name'] as String? ?? '—'),
          _infoRow(
            'Regional manager',
            _leader['regional_manager_name'] as String? ?? '—',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final items = [
      ('Device in hand', '${_stats['devices_in_hand_count'] ?? 0}'),
      ('Agents', '${_stats['agents_count'] ?? 0} (${_stats['active_agents'] ?? 0} active)'),
      ('Qty assigned', '${_stats['total_assigned'] ?? 0}'),
      ('Qty sold', '${_stats['total_sold'] ?? 0}'),
      ('Qty remaining', '${_stats['total_remaining'] ?? 0}'),
      ('IMEIs with team', '${_stats['total_imei_count'] ?? 0}'),
      ('IMEIs in field', '${_stats['unsold_imei_count'] ?? 0}'),
      ('IMEIs sold', '${_stats['sold_imei_count'] ?? 0}'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (e) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 52) / 2,
              child: _StatTile(label: e.$1, value: e.$2),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Text(
        '$_pendingSaleCount device(s) have a pending sale waiting for admin.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.amber.shade900,
            ),
      ),
    );
  }

  Widget _buildCustodyProducts() {
    final products = _data?['custody_product_stats'];
    final list = products is List ? products : <dynamic>[];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Devices in your custody',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: sectionCardDecoration(context),
          child: Column(
            children: list.map((raw) {
              final p = raw as Map<String, dynamic>;
              return ListTile(
                title: Text(p['product_name'] as String? ?? '—'),
                subtitle: Text('${p['device_count'] ?? 0} device(s) not yet assigned to an agent'),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProductTable() {
    final products = _data?['product_imei_stats'];
    final list = products is List ? products : <dynamic>[];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products on your team',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: sectionCardDecoration(context),
          child: Column(
            children: list.map((raw) {
              final p = raw as Map<String, dynamic>;
              return ListTile(
                title: Text(p['product_name'] as String? ?? '—'),
                subtitle: Text(
                  'Total ${p['imei_total']} · In field ${p['imei_unsold']} · Sold ${p['imei_sold']}',
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentsList() {
    final agents = _data?['agents'];
    final list = agents is List ? agents : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your agents',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: sectionCardDecoration(context),
          child: list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No agents linked to your team yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : Column(
                  children: list.map((raw) {
                    final a = raw as Map<String, dynamic>;
                    return ListTile(
                      title: Text(a['name'] as String? ?? '—'),
                      subtitle: Text(
                        '${a['branch_name'] ?? '—'} · '
                        'Qty ${a['qty_assigned']}/${a['qty_sold']} (${a['qty_remaining']} left) · '
                        'IMEIs ${a['imei_total']} (${a['imei_unsold']} in field)',
                      ),
                      trailing: a['status'] == 'active'
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                          : null,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
          ),
        ],
      ),
    );
  }
}
