import 'package:flutter/material.dart';

import '../../api/team_leader_api.dart';
import '../../theme/app_theme.dart';
import 'team_leader_scaffold.dart';

class TeamLeaderReturnDevicesScreen extends StatefulWidget {
  const TeamLeaderReturnDevicesScreen({super.key});

  @override
  State<TeamLeaderReturnDevicesScreen> createState() => _TeamLeaderReturnDevicesScreenState();
}

class _TeamLeaderReturnDevicesScreenState extends State<TeamLeaderReturnDevicesScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _imeiRows = [];
  int? _productId;
  final Set<int> _selectedIds = {};
  bool _loadingProducts = true;
  bool _loadingImeis = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
      _error = null;
    });
    try {
      final products = await getTeamLeaderReturnProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingProducts = false;
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
      final rows = await getTeamLeaderReturnableImeis(productId);
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

  Future<void> _submit() async {
    final pid = _productId;
    if (pid == null || _selectedIds.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final count = await postTeamLeaderReturnDevices(
        productId: pid,
        productListIds: _selectedIds.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return request sent ($count device(s)). Regional manager must accept.')),
      );
      setState(() {
        _selectedIds.clear();
        _submitting = false;
      });
      await _onProductChanged(pid);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
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
      title: 'Return to regional manager',
      body: _loadingProducts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Send devices back to your regional manager as a return request. They must accept before devices leave your custody.',
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
                  if (_loadingImeis)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_productId != null && _imeiRows.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('IMEIs to return', style: sectionLabelStyle(context)),
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
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting || _selectedIds.isEmpty ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Return to regional manager'),
                    ),
                  ] else if (_productId != null && !_loadingImeis)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'No returnable IMEIs for this product.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
