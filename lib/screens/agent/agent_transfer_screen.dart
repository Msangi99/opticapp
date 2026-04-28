import 'package:flutter/material.dart';
import '../../api/agent_dashboard_api.dart';
import '../../api/agent_transfer_api.dart';
import '../../api/client.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'agent_scaffold.dart';

class AgentTransferScreen extends StatefulWidget {
  const AgentTransferScreen({super.key});

  @override
  State<AgentTransferScreen> createState() => _AgentTransferScreenState();
}

class _AgentTransferScreenState extends State<AgentTransferScreen> {
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _imeiRows = [];
  Map<int, String> _productLabels = {};
  List<int> _productIds = [];

  int? _toAgentId;
  int? _productId;
  final Set<int> _selectedIds = {};
  final _messageController = TextEditingController();

  bool _loadingMeta = true;
  bool _loadingImeis = false;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _error = null;
    });
    try {
      final user = await getStoredUser();
      final selfId = user?['id'] as int? ?? (user?['id'] is num ? (user!['id'] as num).toInt() : null);
      final agents = await getAgentTransferRecipients();
      final devices = await getAvailableProducts();
      final labels = <int, String>{};
      final pids = <int>{};
      for (final d in devices) {
        final pid = d['product_id'];
        final int? id = pid is int ? pid : (pid is num ? pid.toInt() : null);
        if (id == null) continue;
        pids.add(id);
        labels.putIfAbsent(id, () {
          final cat = d['category_name'] as String? ?? '';
          final m = d['model'] as String? ?? '';
          final t = '$cat $m'.trim();
          return t.isEmpty ? 'Product #$id' : t;
        });
      }
      final sorted = pids.toList()..sort();
      if (!mounted) return;
      setState(() {
        _agents = agents.where((a) {
          final id = a['id'];
          final aid = id is int ? id : (id is num ? id.toInt() : null);
          return aid != null && aid != selfId;
        }).toList();
        _imeiRows = [];
        _productLabels = labels;
        _productIds = sorted;
        _loadingMeta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingMeta = false;
      });
    }
  }

  Future<void> _loadImeis(int productId) async {
    setState(() {
      _loadingImeis = true;
      _selectedIds.clear();
      _error = null;
    });
    try {
      final rows = await getTransferableImeis(productId);
      if (!mounted) return;
      setState(() {
        _loadingImeis = false;
        _imeiRows = rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingImeis = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submit() async {
    if (_toAgentId == null || _productId == null || _selectedIds.isEmpty) {
      setState(() => _error = 'Select agent, product, and at least one device.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm transfer request'),
        content: Text('Submit transfer of ${_selectedIds.length} device(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await createAgentTransfer(
        toAgentId: _toAgentId!,
        productListIds: _selectedIds.toList(),
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer request submitted.')));
      Navigator.pushReplacementNamed(context, '/agent/transfers');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AgentScaffold(
      title: 'Transfer devices',
      showDrawer: true,
      body: _loadingMeta
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _loadMeta,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_productIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'You have no assignable devices to transfer.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    if (_error != null) AdminPageError(message: _error!),
                    Text('Receiving agent', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _toAgentId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      hint: const Text('Select agent'),
                      items: _agents.map((a) {
                        final id = a['id'];
                        final int? aid = id is int ? id : (id is num ? id.toInt() : null);
                        if (aid == null) return null;
                        final name = a['name'] as String? ?? '';
                        final email = a['email'] as String? ?? '';
                        return DropdownMenuItem(value: aid, child: Text('$name ($email)', overflow: TextOverflow.ellipsis));
                      }).whereType<DropdownMenuItem<int>>().toList(),
                      onChanged: (v) => setState(() => _toAgentId = v),
                    ),
                    const SizedBox(height: 20),
                    Text('Product', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _productId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      hint: const Text('Select product'),
                      items: _productIds
                          .map(
                            (id) => DropdownMenuItem(
                              value: id,
                              child: Text(_productLabels[id] ?? 'Product #$id', overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _productId = v;
                          _selectedIds.clear();
                        });
                        if (v != null) _loadImeis(v);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_loadingImeis)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                      else if (_productId != null) ...[
                      Text('Devices (IMEI)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (_imeiRows.isEmpty)
                        Text('No transferable devices for this product.', style: Theme.of(context).textTheme.bodySmall)
                      else
                        ..._imeiRows.map((row) {
                          final id = row['id'];
                          final int? lid = id is int ? id : (id is num ? id.toInt() : null);
                          if (lid == null) return const SizedBox.shrink();
                          final label = row['text'] as String? ?? row['imei_number']?.toString() ?? '#$lid';
                          return CheckboxListTile(
                            value: _selectedIds.contains(lid),
                            onChanged: (c) {
                              setState(() {
                                if (c == true) {
                                  _selectedIds.add(lid);
                                } else {
                                  _selectedIds.remove(lid);
                                }
                              });
                            },
                            title: Text(label, style: const TextStyle(fontSize: 14)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Note to admin (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: (_submitting || _productIds.isEmpty) ? null : _submit,
                      child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit transfer request'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/agent/transfers'),
                      child: const Text('My transfer requests'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
