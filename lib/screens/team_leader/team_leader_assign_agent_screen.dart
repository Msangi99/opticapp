import 'package:flutter/material.dart';

import '../../api/team_leader_api.dart';
import '../../theme/app_theme.dart';
import '../shared/scanner_dialog.dart';
import 'team_leader_scaffold.dart';

class TeamLeaderAssignAgentScreen extends StatefulWidget {
  const TeamLeaderAssignAgentScreen({super.key});

  @override
  State<TeamLeaderAssignAgentScreen> createState() => _TeamLeaderAssignAgentScreenState();
}

class _TeamLeaderAssignAgentScreenState extends State<TeamLeaderAssignAgentScreen> {
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _imeiRows = [];

  int? _agentId;
  int? _productId;
  final Set<int> _selectedIds = {};
  final _manualImeiController = TextEditingController();

  bool _loadingMeta = true;
  bool _loadingImeis = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _manualImeiController.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _error = null;
    });
    try {
      final data = await getTeamLeaderAssignFormData();
      if (!mounted) return;
      setState(() {
        _agents = (data['agents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _products = (data['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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

  Future<void> _onProductChanged(int? productId) async {
    setState(() {
      _productId = productId;
      _imeiRows = [];
      _selectedIds.clear();
      _loadingImeis = productId != null;
    });
    if (productId == null) return;
    try {
      final rows = await getTeamLeaderAssignableImeis(productId);
      if (!mounted) return;
      setState(() {
        _imeiRows = rows;
        _loadingImeis = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingImeis = false;
      });
    }
  }

  Future<void> _tryAddImei(String raw) async {
    final pid = _productId;
    if (pid == null) {
      setState(() => _error = 'Select a product first.');
      return;
    }
    final vr = await validateTeamLeaderAssignImei(productId: pid, imei: raw);
    if (!mounted) return;
    if (!vr.ok || vr.productListId == null) {
      setState(() => _error = vr.message ?? 'Validation failed.');
      return;
    }
    if (_selectedIds.contains(vr.productListId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Already selected: ${vr.imeiNumber ?? raw}')),
      );
      return;
    }
    setState(() {
      _selectedIds.add(vr.productListId!);
      _error = null;
    });
  }

  Future<void> _scanImei() async {
    if (_productId == null) {
      setState(() => _error = 'Select a product before scanning.');
      return;
    }
    final code = await showBarcodeScannerDialog(context);
    if (code == null || !mounted) return;
    await _tryAddImei(code);
  }

  Future<void> _submit() async {
    final aid = _agentId;
    final pid = _productId;
    if (aid == null || pid == null || _selectedIds.isEmpty) {
      setState(() => _error = 'Choose an agent, product, and at least one IMEI.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final count = await postTeamLeaderAssignAgent(
        agentId: aid,
        productId: pid,
        productListIds: _selectedIds.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned $count device(s).'), backgroundColor: successColor),
      );
      setState(() {
        _selectedIds.clear();
        _submitting = false;
      });
      await _onProductChanged(pid);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  int? _parseId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  String _productLabel(Map<String, dynamic> p) {
    final cat = p['category_name']?.toString() ?? '';
    final name = p['name']?.toString() ?? '';
    final t = [cat, name].where((s) => s.isNotEmpty).join(' – ');
    return t.isEmpty ? 'Product' : t;
  }

  @override
  Widget build(BuildContext context) {
    return TeamLeaderScaffold(
      title: 'Assign to agent',
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Give devices you received from your regional manager to an agent on your team.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: errorStyle()),
                  ],
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int?>(
                    value: _agentId,
                    decoration: const InputDecoration(
                      labelText: 'Agent',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Select agent')),
                      ..._agents.map((a) {
                        final id = _parseId(a['id']);
                        if (id == null) return null;
                        return DropdownMenuItem<int?>(value: id, child: Text(a['name']?.toString() ?? '#$id'));
                      }).whereType<DropdownMenuItem<int?>>(),
                    ],
                    onChanged: (v) => setState(() => _agentId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: _productId,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Select product')),
                      ..._products.map((p) {
                        final id = _parseId(p['id']);
                        if (id == null) return null;
                        return DropdownMenuItem<int?>(value: id, child: Text(_productLabel(p)));
                      }).whereType<DropdownMenuItem<int?>>(),
                    ],
                    onChanged: _onProductChanged,
                  ),
                  if (_productId != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _scanImei,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan IMEI barcode'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualImeiController,
                            decoration: const InputDecoration(
                              labelText: 'IMEI',
                              prefixIcon: Icon(Icons.dialpad_rounded),
                            ),
                            onSubmitted: (v) => _tryAddImei(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => _tryAddImei(_manualImeiController.text),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                  if (_loadingImeis)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_productId != null) ...[
                    const SizedBox(height: 16),
                    Text('Selectable IMEIs', style: sectionLabelStyle(context)),
                    const SizedBox(height: 8),
                    ..._imeiRows.map((row) {
                      final id = _parseId(row['id']);
                      if (id == null) return const SizedBox.shrink();
                      final label = row['text']?.toString() ?? row['imei_number']?.toString() ?? '#$id';
                      return CheckboxListTile(
                        value: _selectedIds.contains(id),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedIds.add(id);
                            } else {
                              _selectedIds.remove(id);
                            }
                          });
                        },
                        title: Text(label),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Assign to agent'),
                  ),
                ],
              ),
            ),
    );
  }
}
