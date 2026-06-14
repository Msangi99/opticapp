import 'package:flutter/material.dart';
import '../../api/agent_dashboard_api.dart';
import '../../api/agent_return_devices_api.dart';
import '../../theme/app_theme.dart';
import 'agent_scaffold.dart';

/// Return assigned IMEIs to team leader (mirrors web agent return-devices).
class AgentReturnDevicesScreen extends StatefulWidget {
  const AgentReturnDevicesScreen({super.key});

  @override
  State<AgentReturnDevicesScreen> createState() => _AgentReturnDevicesScreenState();
}

class _AgentReturnDevicesScreenState extends State<AgentReturnDevicesScreen> {
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
      final devices = await getAvailableProducts();
      final byProduct = <int, Map<String, dynamic>>{};
      for (final d in devices) {
        final pid = d['product_id'];
        final int? id = pid is int ? pid : (pid is num ? pid.toInt() : int.tryParse('$pid'));
        if (id == null) continue;
        byProduct.putIfAbsent(id, () => d);
      }
      if (!mounted) return;
      setState(() {
        _products = byProduct.values.toList();
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
      final rows = await getReturnableImeis(productId);
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
    if (_selectedIds.isEmpty) return;
    if (_productId == null) return;
    setState(() => _submitting = true);
    try {
      await returnDevicesToTeamLeader(_productId!, _selectedIds.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return request sent. Team leader must accept to complete.')),
      );
      setState(() {
        _selectedIds.clear();
        _submitting = false;
      });
      await _onProductChanged(_productId);
      await _loadProducts();
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

  String _productLabel(Map<String, dynamic> d) {
    final cat = d['category_name'] as String? ?? '';
    final model = d['model'] as String? ?? '';
    final t = '$cat $model'.trim();
    return t.isEmpty ? 'Product' : t;
  }

  @override
  Widget build(BuildContext context) {
    return AgentScaffold(
      title: 'Return devices',
      body: _loadingProducts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Submit a return request to your team leader. They must accept before devices leave your custody.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: errorStyle()),
                  ],
                  const SizedBox(height: 20),
                  if (_products.isEmpty)
                    Text(
                      'No assignable devices to return.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  else ...[
                    DropdownButtonFormField<int?>(
                      value: _productId,
                      decoration: const InputDecoration(
                        labelText: 'Product',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Select product')),
                        ..._products.map((p) {
                          final id = _parseId(p['product_id']);
                          if (id == null) return null;
                          return DropdownMenuItem<int?>(
                            value: id,
                            child: Text(_productLabel(p)),
                          );
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
                            : const Text('Return to team leader'),
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
                ],
              ),
            ),
    );
  }
}
