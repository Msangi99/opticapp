import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/regional_manager_return_requests_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import '../../theme/app_theme.dart';
import 'regional_manager_scaffold.dart';

class RegionalManagerReturnRequestsScreen extends StatefulWidget {
  const RegionalManagerReturnRequestsScreen({super.key});

  @override
  State<RegionalManagerReturnRequestsScreen> createState() => _RegionalManagerReturnRequestsScreenState();
}

class _RegionalManagerReturnRequestsScreenState extends State<RegionalManagerReturnRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _incoming = [];
  List<Map<String, dynamic>> _outgoing = [];
  bool _loading = true;
  String? _error;

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      return DateFormat('MMM d, y · HH:mm').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  bool _boolFlag(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        listRegionalManagerReturnRequestsIncoming(),
        listRegionalManagerReturnRequestsOutgoing(),
      ]);
      if (!mounted) return;
      setState(() {
        _incoming = results[0];
        _outgoing = results[1];
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

  Future<void> _accept(Map<String, dynamic> row) async {
    final id = row['id'];
    final int? rid = id is int ? id : (id is num ? id.toInt() : null);
    if (rid == null) return;
    try {
      await acceptRegionalManagerReturnIncoming(rid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return accepted.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _decline(Map<String, dynamic> row) async {
    final id = row['id'];
    final int? rid = id is int ? id : (id is num ? id.toInt() : null);
    if (rid == null) return;
    try {
      await declineRegionalManagerReturnIncoming(rid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return declined.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _cancel(Map<String, dynamic> row) async {
    final id = row['id'];
    final int? rid = id is int ? id : (id is num ? id.toInt() : null);
    if (rid == null) return;
    try {
      await cancelRegionalManagerReturnOutgoing(rid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelled.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _statusChip(String status) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;
    if (status == 'pending') {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
    } else if (status == 'approved') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    } else if (status == 'rejected') {
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, {required bool incoming}) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AdminPageEmpty(
            icon: Icons.undo_rounded,
            title: incoming ? 'No return requests from team leaders.' : 'No return requests sent yet.',
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        final status = r['status'] as String? ?? '';
        final cnt = r['items_count'] as int? ?? (r['items_count'] is num ? (r['items_count'] as num).toInt() : 0);
        final title = incoming
            ? 'From ${(r['from_team_leader'] as Map<String, dynamic>?)?['name'] ?? 'Team leader'}'
            : 'To Admin';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: sectionCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 6),
              Text('$cnt device(s) · ${_fmtDate(r['created_at'] as String? ?? '')}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              if (incoming && (_boolFlag(r['can_accept']) || _boolFlag(r['can_decline'])))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (_boolFlag(r['can_accept'])) FilledButton(onPressed: () => _accept(r), child: const Text('Accept')),
                      if (_boolFlag(r['can_decline'])) OutlinedButton(onPressed: () => _decline(r), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Decline')),
                    ],
                  ),
                ),
              if (!incoming && _boolFlag(r['can_cancel']))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton(onPressed: () => _cancel(r), child: const Text('Cancel')),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegionalManagerScaffold(
      title: 'Return requests',
      showDrawer: true,
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'From team leaders'),
              Tab(text: 'My requests'),
            ],
          ),
          Expanded(
            child: _loading
                ? const AdminPageLoading()
                : _error != null
                    ? AdminPageError(message: _error!)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            _buildList(_incoming, incoming: true),
                            _buildList(_outgoing, incoming: false),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
