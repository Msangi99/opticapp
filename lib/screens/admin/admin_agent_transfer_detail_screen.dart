import 'package:flutter/material.dart';
import '../../api/admin_agent_transfers_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

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
  final _noteController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await approveAdminAgentTransfer(widget.transferId, adminNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await rejectAdminAgentTransfer(widget.transferId, adminNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _data['status'] as String? ?? '';
    final pending = status == 'pending';

    return AdminScaffold(
      title: 'Transfer #${widget.transferId}',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!, style: errorStyle()),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: sectionCardDecoration(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: $status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                              Text('Admin note: ${_data['admin_note']}', style: Theme.of(context).textTheme.bodyMedium),
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
                            padding: const EdgeInsets.all(12),
                            decoration: sectionCardDecoration(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(imei, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600)),
                                if (pname.isNotEmpty || cat.isNotEmpty) Text('$cat · $pname', style: Theme.of(context).textTheme.bodySmall),
                                if (sn.isNotEmpty) Text('Stock: $sn', style: Theme.of(context).textTheme.bodySmall),
                                Text('Branch: $branch', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          );
                        }).toList();
                      })(),
                      if (pending) ...[
                        const SizedBox(height: 24),
                        TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Admin note (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _busy ? null : _approve,
                                child: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy ? null : _reject,
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
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
