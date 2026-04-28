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

  int? _id(dynamic v) => v is int ? v : int.tryParse(v.toString());

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
                            const SizedBox(height: 12),
                            KeyValueRow(label: 'From', value: data['from_agent']?['name']?.toString() ?? '—'),
                            KeyValueRow(label: 'To', value: data['to_agent']?['name']?.toString() ?? '—'),
                            KeyValueRow(label: 'Created', value: _fmtDate(data['created_at']?.toString())),
                            KeyValueRow(label: 'Decided', value: _fmtDate(data['decided_at']?.toString())),
                            if ((data['message'] ?? '').toString().isNotEmpty)
                              KeyValueRow(label: 'Message', value: data['message'].toString()),
                            if ((data['admin_note'] ?? '').toString().isNotEmpty)
                              KeyValueRow(label: 'Admin note', value: data['admin_note'].toString()),
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
                                  KeyValueRow(label: 'Product', value: item['product_name']?.toString() ?? '—'),
                                  KeyValueRow(label: 'Category', value: item['category_name']?.toString() ?? '—'),
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
