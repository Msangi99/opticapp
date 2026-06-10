import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/agent_transfer_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'agent_scaffold.dart';

class AgentTransferDetailScreen extends StatefulWidget {
  const AgentTransferDetailScreen({super.key});

  @override
  State<AgentTransferDetailScreen> createState() => _AgentTransferDetailScreenState();
}

class _AgentTransferDetailScreenState extends State<AgentTransferDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _acting = false;
  int? _transferId;

  int? _id(dynamic v) => v is int ? v : int.tryParse(v.toString());

  bool _boolFlag(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('MMM d, y · HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data != null || _loading == false) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = _id(args['id']);
    if (id == null) {
      setState(() {
        _error = 'Missing transfer id.';
        _loading = false;
      });
      return;
    }
    _transferId = id;
    _load(id);
  }

  Future<void> _load(int id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getAgentTransferDetail(id);
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

  Future<void> _accept() async {
    final id = _transferId;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept transfer?'),
        content: const Text('Devices will be assigned to you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accept')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _acting = true);
    try {
      await acceptAgentTransfer(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer accepted.')));
      await _load(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decline() async {
    final id = _transferId;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline transfer?'),
        content: const Text('The sender will be notified that you declined.'),
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
    setState(() => _acting = true);
    try {
      await declineAgentTransfer(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer declined.')));
      await _load(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _cancel() async {
    final id = _transferId;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel transfer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _acting = true);
    try {
      await cancelAgentTransfer(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelled.')));
      await _load(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data ?? {};
    final status = (data['status'] ?? 'unknown').toString();
    final statusColor = switch (status) {
      'approved' => Colors.green,
      'rejected' || 'cancelled' => Colors.red,
      _ => Colors.orange,
    };
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final canAccept = _boolFlag(data['can_accept']);
    final canDecline = _boolFlag(data['can_decline']);
    final canCancel = _boolFlag(data['can_cancel']);
    final direction = data['direction'] as String? ?? '';

    return AgentScaffold(
      title: 'Transfer detail',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : RefreshIndicator(
                  onRefresh: () async => _load(_id(data['id']) ?? 0),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AdminSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Request #${data['id'] ?? '—'}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                StatusChip(label: status, color: statusColor),
                              ],
                            ),
                            if (direction.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                direction == 'incoming' ? 'Incoming request' : 'Outgoing request',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: direction == 'incoming' ? Colors.blue.shade700 : Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            KeyValueRow(label: 'From', value: data['from_agent']?['name']?.toString() ?? '—'),
                            KeyValueRow(label: 'To', value: data['to_agent']?['name']?.toString() ?? '—'),
                            KeyValueRow(label: 'Created', value: _fmtDate(data['created_at']?.toString())),
                            KeyValueRow(label: 'Decided', value: _fmtDate(data['decided_at']?.toString())),
                            if ((data['message'] ?? '').toString().isNotEmpty)
                              KeyValueRow(label: 'Sender note', value: data['message'].toString()),
                            if ((data['admin_note'] ?? '').toString().isNotEmpty)
                              KeyValueRow(label: 'Response note', value: data['admin_note'].toString()),
                            if (canAccept || canDecline || canCancel) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (canAccept)
                                    FilledButton(
                                      onPressed: _acting ? null : _accept,
                                      child: _acting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Accept'),
                                    ),
                                  if (canDecline)
                                    OutlinedButton(
                                      onPressed: _acting ? null : _decline,
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Decline'),
                                    ),
                                  if (canCancel)
                                    TextButton(
                                      onPressed: _acting ? null : _cancel,
                                      child: const Text('Cancel request', style: TextStyle(color: Colors.red)),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Transferred devices', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        const AdminPageEmpty(icon: Icons.devices_other_rounded, title: 'No items in this transfer')
                      else
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AdminSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['imei_number']?.toString() ?? '—',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  KeyValueRow(label: 'Model', value: item['model']?.toString() ?? '—'),
                                  KeyValueRow(label: 'Product', value: item['product']?['name']?.toString() ?? item['product_name']?.toString() ?? '—'),
                                  KeyValueRow(label: 'Category', value: item['product']?['category']?.toString() ?? item['category_name']?.toString() ?? '—'),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
