import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/agent_return_devices_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import '../../theme/app_theme.dart';
import 'agent_scaffold.dart';

class AgentReturnRequestsScreen extends StatefulWidget {
  const AgentReturnRequestsScreen({super.key});

  @override
  State<AgentReturnRequestsScreen> createState() => _AgentReturnRequestsScreenState();
}

class _AgentReturnRequestsScreenState extends State<AgentReturnRequestsScreen> {
  List<Map<String, dynamic>> _list = [];
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
      final list = await listAgentReturnRequests();
      if (!mounted) return;
      setState(() {
        _list = list;
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

  Future<void> _tryCancel(Map<String, dynamic> row) async {
    final id = row['id'];
    final int? rid = id is int ? id : (id is num ? id.toInt() : null);
    if (rid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel return request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await cancelAgentReturnRequest(rid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelled.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  bool _boolFlag(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'pending':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
      case 'approved':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
      case 'rejected':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AgentScaffold(
      title: 'Return requests',
      showDrawer: true,
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _list.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: const [
                            AdminPageEmpty(icon: Icons.undo_rounded, title: 'No return requests yet.'),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final r = _list[index];
                            final status = r['status'] as String? ?? '';
                            final to = r['to_team_leader'] as Map<String, dynamic>?;
                            final name = to?['name'] as String? ?? 'Team leader';
                            final cnt = r['items_count'] as int? ?? (r['items_count'] is num ? (r['items_count'] as num).toInt() : 0);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: sectionCardDecoration(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text('To $name', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                                      _statusChip(status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('$cnt device(s) · ${_fmtDate(r['created_at'] as String? ?? '')}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  if (_boolFlag(r['can_cancel']))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: OutlinedButton(onPressed: () => _tryCancel(r), child: const Text('Cancel')),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
