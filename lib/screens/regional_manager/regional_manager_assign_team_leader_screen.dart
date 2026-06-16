import 'package:flutter/material.dart';

import '../../api/regional_manager_api.dart';
import '../../theme/app_theme.dart';
import '../shared/scanner_dialog.dart';
import 'regional_manager_scaffold.dart';

class RegionalManagerAssignTeamLeaderScreen extends StatefulWidget {
  const RegionalManagerAssignTeamLeaderScreen({super.key});

  @override
  State<RegionalManagerAssignTeamLeaderScreen> createState() => _RegionalManagerAssignTeamLeaderScreenState();
}

class _RegionalManagerAssignTeamLeaderScreenState extends State<RegionalManagerAssignTeamLeaderScreen> {
  List<Map<String, dynamic>> _teamLeaders = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _imeiRows = [];

  int? _teamLeaderId;
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
      final data = await getRegionalManagerAssignFormData();
      if (!mounted) return;
      setState(() {
        _teamLeaders = (data['team_leaders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
      final rows = await getRegionalManagerAssignableImeis(productId);
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

  static String _normalizeImei(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), '');

  static String? _imeiFormatError(String raw) {
    final normalized = _normalizeImei(raw);
    if (normalized.isEmpty) return 'Enter an IMEI to scan or add.';
    if (!RegExp(r'^\d+$').hasMatch(normalized)) {
      return 'IMEI must contain digits only.';
    }
    if (normalized.length != 15) {
      return 'IMEI must be exactly 15 digits (got ${normalized.length}).';
    }
    return null;
  }

  Future<void> _tryAddImei(String raw) async {
    final pid = _productId;
    if (pid == null) {
      setState(() => _error = 'Select a product first.');
      return;
    }
    final formatError = _imeiFormatError(raw);
    if (formatError != null) {
      setState(() => _error = formatError);
      return;
    }
    final normalized = _normalizeImei(raw);
    final vr = await validateRegionalManagerAssignImei(productId: pid, imei: normalized);
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
    _manualImeiController.clear();
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _submitting ? null : _submit,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: _submitting
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('Send transfer request'),
    );
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
    final tlId = _teamLeaderId;
    final pid = _productId;
    if (tlId == null || pid == null || _selectedIds.isEmpty) {
      setState(() => _error = 'Choose a team leader, product, and at least one IMEI.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final count = await postRegionalManagerAssignTeamLeader(
        teamLeaderId: tlId,
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
    return RegionalManagerScaffold(
      title: 'Assign to team leader',
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Send devices in your custody to a team leader as a transfer request. They must accept before devices appear in their inventory.',
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
                    value: _teamLeaderId,
                    decoration: const InputDecoration(
                      labelText: 'Team leader',
                      prefixIcon: Icon(Icons.group_rounded),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Select team leader')),
                      ..._teamLeaders.map((tl) {
                        final id = _parseId(tl['id']);
                        if (id == null) return null;
                        return DropdownMenuItem<int?>(value: id, child: Text(tl['name']?.toString() ?? '#$id'));
                      }).whereType<DropdownMenuItem<int?>>(),
                    ],
                    onChanged: (v) => setState(() => _teamLeaderId = v),
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
                    _buildSubmitButton(),
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
                            keyboardType: TextInputType.number,
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
                ],
              ),
            ),
    );
  }
}
