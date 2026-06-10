import 'package:flutter/material.dart';
import '../../api/admin_agent_transfers_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class AdminAgentTransferDetailScreen extends StatefulWidget {
  const AdminAgentTransferDetailScreen({super.key, required this.transferId});

  final int transferId;

  @override
  State<AdminAgentTransferDetailScreen> createState() => _AdminAgentTransferDetailScreenState();
}

class _AdminAgentTransferDetailScreenState extends State<AdminAgentTransferDetailScreen> {
  Map<String, dynamic> _data = {};
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
      final d = await getAdminAgentTransferDetail(widget.transferId);
      if (!mounted) return;
      setState(() {
        _data = d;
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
    final status = _data['status'] as String? ?? '';
    final pending = status == 'pending';

    return AdminScaffold(
      title: 'Transfer #${widget.transferId}',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminSectionCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                StatusChip(
                                  label: status,
                                  color: status == 'approved'
                                      ? const Color(0xFF047857)
                                      : status == 'rejected'
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFFB45309),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _agentBlock('From', _data['from_agent'] as Map<String, dynamic>?),
                            const SizedBox(height: 12),
                            _agentBlock('To', _data['to_agent'] as Map<String, dynamic>?),
                            if ((_data['message'] as String?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 12),
                              Text('Agent note: ${_data['message']}', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                            if ((_data['admin_note'] as String?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Text('Response note: ${_data['admin_note']}', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Devices', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...(() {
                        final items = _data['items'];
                        if (items is! List) return <Widget>[const Text('—')];
                        return items.map<Widget>((raw) {
                          final it = raw as Map<String, dynamic>;
                          final imei = it['imei_number'] as String? ?? '—';
                          final prod = it['product'] as Map<String, dynamic>?;
                          final pname = prod?['name'] as String? ?? '';
                          final cat = prod?['category'] as String? ?? '';
                          final stock = it['stock'] as Map<String, dynamic>?;
                          final sn = stock?['name'] as String? ?? '';
                          final branch = it['effective_branch_name'] as String? ?? '—';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: AdminSectionCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(imei, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (pname.isNotEmpty || cat.isNotEmpty) KeyValueRow(label: 'Product', value: '$cat · $pname'),
                                  if (sn.isNotEmpty) KeyValueRow(label: 'Stock', value: sn),
                                  KeyValueRow(label: 'Branch', value: branch),
                                ],
                              ),
                            ),
                          );
                        }).toList();
                      })(),
                      if (pending) ...[
                        const SizedBox(height: 24),
                        AdminSectionCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Waiting for ${(_data['to_agent'] as Map<String, dynamic>?)?['name'] ?? 'the receiving agent'} to accept or decline.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _agentBlock(String label, Map<String, dynamic>? a) {
    if (a == null) return Text('$label: —');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        Text(a['name'] as String? ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(a['email'] as String? ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ],
    );
  }
}
