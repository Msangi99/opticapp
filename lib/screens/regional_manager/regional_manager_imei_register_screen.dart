import 'package:flutter/material.dart';

import '../../api/regional_manager_api.dart';
import '../../theme/app_theme.dart';
import 'regional_manager_scaffold.dart';

class RegionalManagerImeiRegisterScreen extends StatefulWidget {
  const RegionalManagerImeiRegisterScreen({super.key});

  @override
  State<RegionalManagerImeiRegisterScreen> createState() => _RegionalManagerImeiRegisterScreenState();
}

class _RegionalManagerImeiRegisterScreenState extends State<RegionalManagerImeiRegisterScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  int? _teamLeaderId;
  int? _agentId;
  int? _productId;
  String _status = 'all';
  final _searchController = TextEditingController();
  int _page = 1;

  List<Map<String, dynamic>> _teamLeaders = [];
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
      _page = page;
    });
    try {
      final data = await getRegionalManagerRegionInventory(
        teamLeaderId: _teamLeaderId,
        agentId: _agentId,
        productId: _productId,
        status: _status,
        q: _searchController.text,
        page: page,
      );
      if (!mounted) return;
      final filters = data['filters'] as Map<String, dynamic>? ?? {};
      setState(() {
        _data = data;
        _teamLeaders = (filters['team_leaders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _agents = (filters['agents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _products = (filters['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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

  int? _parseId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'unsold':
        return 'In field';
      case 'pending':
        return 'Pending admin';
      case 'sold':
        return 'Sold';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sold':
        return const Color(0xFF64748B);
      case 'pending':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF059669);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _data?['summary'] as Map<String, dynamic>? ?? {};
    final rows = (_data?['rows'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final meta = _data?['meta'] as Map<String, dynamic>? ?? {};
    final currentPage = _parseId(meta['current_page']) ?? 1;
    final lastPage = _parseId(meta['last_page']) ?? 1;

    return RegionalManagerScaffold(
      title: 'IMEI register',
      body: _loading && _data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(page: _page),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Every device assigned to agents under your team leaders.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!, style: errorStyle()),
                          ],
                          const SizedBox(height: 16),
                          _summaryGrid(summary),
                          const SizedBox(height: 16),
                          _filtersCard(context),
                        ],
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (rows.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No IMEI assignments for your hierarchy yet.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _rowTile(context, rows[index]),
                        childCount: rows.length,
                      ),
                    ),
                  if (lastPage > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: currentPage > 1 ? () => _load(page: currentPage - 1) : null,
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Text('Page $currentPage of $lastPage'),
                            IconButton(
                              onPressed: currentPage < lastPage ? () => _load(page: currentPage + 1) : null,
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _summaryGrid(Map<String, dynamic> summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _summaryTile('Total IMEIs', '${summary['total'] ?? 0}'),
        _summaryTile('In field', '${summary['unsold'] ?? 0}'),
        _summaryTile('Sold', '${summary['sold'] ?? 0}'),
        _summaryTile('Pending admin', '${summary['pending'] ?? 0}'),
      ],
    );
  }

  Widget _summaryTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _filtersCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int?>(
            value: _teamLeaderId,
            decoration: const InputDecoration(labelText: 'Team leader'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All team leaders')),
              ..._teamLeaders.map((tl) {
                final id = _parseId(tl['id']);
                if (id == null) return null;
                return DropdownMenuItem<int?>(value: id, child: Text(tl['name']?.toString() ?? '#$id'));
              }).whereType<DropdownMenuItem<int?>>(),
            ],
            onChanged: (v) {
              setState(() {
                _teamLeaderId = v;
                _agentId = null;
              });
              _load();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: _agentId,
            decoration: const InputDecoration(labelText: 'Agent'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All agents')),
              ..._agents.where((a) => _teamLeaderId == null || _parseId(a['team_leader_id']) == _teamLeaderId).map((a) {
                final id = _parseId(a['id']);
                if (id == null) return null;
                return DropdownMenuItem<int?>(value: id, child: Text(a['name']?.toString() ?? '#$id'));
              }).whereType<DropdownMenuItem<int?>>(),
            ],
            onChanged: (v) {
              setState(() => _agentId = v);
              _load();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: _productId,
            decoration: const InputDecoration(labelText: 'Product'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All products')),
              ..._products.map((p) {
                final id = _parseId(p['id']);
                if (id == null) return null;
                return DropdownMenuItem<int?>(value: id, child: Text(p['name']?.toString() ?? '#$id'));
              }).whereType<DropdownMenuItem<int?>>(),
            ],
            onChanged: (v) {
              setState(() => _productId = v);
              _load();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'unsold', child: Text('In field')),
              DropdownMenuItem(value: 'pending', child: Text('Pending admin')),
              DropdownMenuItem(value: 'sold', child: Text('Sold')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _status = v);
              _load();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'IMEI search',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _load, child: const Text('Apply')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rowTile(BuildContext context, Map<String, dynamic> row) {
    final imei = row['imei_number']?.toString() ?? '—';
    final product = (row['product'] as Map<String, dynamic>?)?['name']?.toString() ?? '—';
    final agent = (row['agent'] as Map<String, dynamic>?)?['name']?.toString() ?? '—';
    final tl = (row['team_leader'] as Map<String, dynamic>?)?['name']?.toString() ?? '—';
    final status = row['status']?.toString() ?? 'unknown';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: sectionCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    imei,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Product: $product'),
            Text('Team leader: $tl'),
            Text('Agent: $agent'),
          ],
        ),
      ),
    );
  }
}
