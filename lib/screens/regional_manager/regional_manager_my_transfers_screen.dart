import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/regional_manager_transfer_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import '../../theme/app_theme.dart';
import 'regional_manager_scaffold.dart';

class RegionalManagerMyTransfersScreen extends StatefulWidget {
  const RegionalManagerMyTransfersScreen({super.key});

  @override
  State<RegionalManagerMyTransfersScreen> createState() => _RegionalManagerMyTransfersScreenState();
}

class _RegionalManagerMyTransfersScreenState extends State<RegionalManagerMyTransfersScreen> {
  String _fmtDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      return DateFormat('MMM d, y · HH:mm').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  List<Map<String, dynamic>> _list = [];
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
      final list = await listRegionalManagerTransfers();
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

  Future<void> _tryAccept(Map<String, dynamic> row) async {
    final id = row['id'];
    final int? tid = id is int ? id : (id is num ? id.toInt() : null);
    if (tid == null) return;
    final from = row['from_admin'] as Map<String, dynamic>?;
    final fn = from?['name'] as String? ?? 'admin';
    final cnt = row['items_count'] as int? ?? (row['items_count'] is num ? (row['items_count'] as num).toInt() : 0);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept transfer?'),
        content: Text('Accept $cnt device(s) from $fn? They will be added to your inventory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accept')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await acceptRegionalManagerTransfer(tid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer accepted.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _tryDecline(Map<String, dynamic> row) async {
    final id = row['id'];
    final int? tid = id is int ? id : (id is num ? id.toInt() : null);
    if (tid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline transfer?'),
        content: const Text('Admin will be notified that you declined this product request.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await declineRegionalManagerTransfer(tid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer declined.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  bool _boolFlag(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

  @override
  Widget build(BuildContext context) {
    return RegionalManagerScaffold(
      title: 'Transfer requests',
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
                            AdminPageEmpty(
                              icon: Icons.swap_horiz_rounded,
                              title: 'No transfer requests yet.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final t = _list[index];
                            final status = t['status'] as String? ?? '';
                            final from = t['from_admin'] as Map<String, dynamic>?;
                            final fn = from?['name'] as String? ?? 'Admin';
                            final cnt = t['items_count'] as int? ?? (t['items_count'] is num ? (t['items_count'] as num).toInt() : 0);
                            final created = t['created_at'] as String? ?? '';
                            final direction = t['direction'] as String? ?? '';
                            final canAccept = _boolFlag(t['can_accept']);
                            final canDecline = _boolFlag(t['can_decline']);
                            return InkWell(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/regional-manager/transfers/detail',
                                arguments: {'id': t['id']},
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: sectionCardDecoration(context),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'From $fn',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        _statusChip(status),
                                      ],
                                    ),
                                    if (direction.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Incoming request',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$cnt device(s) · ${_fmtDate(created)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    if ((t['message'] as String?)?.isNotEmpty == true)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text('Admin note: ${t['message']}', style: Theme.of(context).textTheme.bodySmall),
                                      ),
                                    if ((t['admin_note'] as String?)?.isNotEmpty == true)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text('Your response: ${t['admin_note']}', style: Theme.of(context).textTheme.bodySmall),
                                      ),
                                    if (canAccept || canDecline)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Wrap(
                                          spacing: 8,
                                          children: [
                                            if (canAccept)
                                              FilledButton(
                                                onPressed: () => _tryAccept(t),
                                                child: const Text('Accept'),
                                              ),
                                            if (canDecline)
                                              OutlinedButton(
                                                onPressed: () => _tryDecline(t),
                                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                                child: const Text('Decline'),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _statusChip(String s) {
    Color bg;
    Color fg;
    switch (s) {
      case 'pending':
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amber.shade900;
        break;
      case 'approved':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade800;
        break;
      case 'rejected':
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red.shade800;
        break;
      default:
        bg = Colors.blueGrey.withValues(alpha: 0.15);
        fg = Colors.blueGrey.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(s.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
