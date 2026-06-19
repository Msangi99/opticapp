import 'package:flutter/material.dart';
import '../../api/distribution_sales_api.dart';
import 'admin_scaffold.dart';

class _DistributionLine {
  _DistributionLine({
    required this.purchaseId,
    required this.purchaseLabel,
    required this.productId,
    required this.productLabel,
    required this.imeiIds,
    required this.unitBuy,
    required this.unitSell,
  });

  final int purchaseId;
  final String purchaseLabel;
  final int productId;
  final String productLabel;
  final List<int> imeiIds;
  final double unitBuy;
  final double unitSell;

  String get lineKey => '$productId:$purchaseId';

  double get lineTotal => imeiIds.length * unitSell;
}

class DistributionFormScreen extends StatefulWidget {
  const DistributionFormScreen({super.key, this.saleId});

  final int? saleId;

  @override
  State<DistributionFormScreen> createState() => _DistributionFormScreenState();
}

class _DistributionFormScreenState extends State<DistributionFormScreen> {
  final _date = TextEditingController();
  final _seller = TextEditingController();
  final _paidAmount = TextEditingController();
  final _imeiRegister = TextEditingController();

  List<Map<String, dynamic>> _dealers = [];
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _models = [];
  List<Map<String, dynamic>> _imeis = [];
  final List<_DistributionLine> _saleLines = [];

  int? _purchaseId;
  int? _dealerId;
  int? _productId;
  final Set<int> _selectedImeiIds = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date.text = DateTime.now().toIso8601String().substring(0, 10);
    _load();
  }

  @override
  void dispose() {
    _date.dispose();
    _seller.dispose();
    _paidAmount.dispose();
    _imeiRegister.dispose();
    super.dispose();
  }

  String _purchaseLabel(int id) {
    for (final p in _purchases) {
      if (p['id'] == id) {
        return p['name']?.toString() ?? 'Purchase #$id';
      }
    }
    return 'Purchase #$id';
  }

  Map<String, dynamic>? _modelMeta(int productId) {
    for (final m in _models) {
      if (m['product_id'] == productId) return m;
    }
    return null;
  }

  double _grandTotal() => _saleLines.fold(0.0, (sum, line) => sum + line.lineTotal);

  Future<void> _load() async {
    try {
      final form = await getDistributionFormData();
      if (!mounted) return;
      setState(() {
        _dealers = (form['dealers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _purchases = (form['purchases'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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

  Future<void> _onPurchaseChanged(int? id) async {
    setState(() {
      _purchaseId = id;
      _productId = null;
      _models = [];
      _imeis = [];
      _selectedImeiIds.clear();
    });
    if (id == null) return;
    try {
      final models = await getDistributionModelsForPurchase(id);
      if (!mounted) return;
      setState(() => _models = models);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _onProductChanged(int? id) async {
    setState(() {
      _productId = id;
      _imeis = [];
      _selectedImeiIds.clear();
    });
    if (id == null || _purchaseId == null) return;
    try {
      final imeis = await getDistributionAssignableImeis(purchaseId: _purchaseId!, productId: id);
      if (!mounted) return;
      setState(() => _imeis = imeis);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _registerImeis() async {
    if (_purchaseId == null || _productId == null) return;
    final raw = _imeiRegister.text.trim();
    if (raw.isEmpty) return;
    try {
      await registerDistributionImeis(
        purchaseId: _purchaseId!,
        catalogProductId: _productId!,
        imeiNumbers: raw,
      );
      _imeiRegister.clear();
      await _onProductChanged(_productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IMEIs registered.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _addLineToSale() {
    if (_purchaseId == null || _productId == null || _selectedImeiIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select purchase, model, and at least one IMEI.')),
      );
      return;
    }

    final meta = _modelMeta(_productId!);
    if (meta == null) return;

    final lineKey = '${_productId!}:${_purchaseId!}';
    final existingIndex = _saleLines.indexWhere((l) => l.lineKey == lineKey);
    final buy = (meta['unit_price'] as num?)?.toDouble() ?? 0;
    final sell = (meta['sell_price'] as num?)?.toDouble() ?? (meta['suggest'] as num?)?.toDouble() ?? buy;
    final label = meta['label']?.toString() ?? 'Model #${_productId!}';

    setState(() {
      if (existingIndex >= 0) {
        final existing = _saleLines[existingIndex];
        final merged = {...existing.imeiIds, ..._selectedImeiIds}.toList();
        _saleLines[existingIndex] = _DistributionLine(
          purchaseId: _purchaseId!,
          purchaseLabel: _purchaseLabel(_purchaseId!),
          productId: _productId!,
          productLabel: label,
          imeiIds: merged,
          unitBuy: buy,
          unitSell: sell,
        );
      } else {
        _saleLines.add(_DistributionLine(
          purchaseId: _purchaseId!,
          purchaseLabel: _purchaseLabel(_purchaseId!),
          productId: _productId!,
          productLabel: label,
          imeiIds: _selectedImeiIds.toList(),
          unitBuy: buy,
          unitSell: sell,
        ));
      }
      _selectedImeiIds.clear();
    });
  }

  Future<void> _save() async {
    if (_dealerId == null || _saleLines.isEmpty) {
      setState(() => _error = 'Select dealer and add at least one line to the sale.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = {
        'date': _date.text.trim(),
        'dealer_id': _dealerId,
        if (_seller.text.trim().isNotEmpty) 'seller_name': _seller.text.trim(),
        'lines': _saleLines
            .map((line) => {
                  'purchase_id': line.purchaseId,
                  'product_id': line.productId,
                  'product_list_ids': line.imeiIds,
                })
            .toList(),
        if (_paidAmount.text.trim().isNotEmpty) 'paid_amount': double.tryParse(_paidAmount.text.trim()),
      };
      if (widget.saleId == null) {
        await createDistributionSale(body);
      } else {
        await updateDistributionSale(widget.saleId!, body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.saleId == null ? 'New distribution sale' : 'Edit distribution',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  TextField(controller: _date, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _purchaseId,
                    decoration: const InputDecoration(
                      labelText: 'Purchase (for next selection)',
                      border: OutlineInputBorder(),
                    ),
                    items: _purchases
                        .map((p) => DropdownMenuItem(value: p['id'] as int, child: Text(p['name']?.toString() ?? '')))
                        .toList(),
                    onChanged: _onPurchaseChanged,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _dealerId,
                    decoration: const InputDecoration(labelText: 'Dealer', border: OutlineInputBorder()),
                    items: _dealers
                        .map((d) => DropdownMenuItem(value: d['id'] as int, child: Text(d['name']?.toString() ?? '')))
                        .toList(),
                    onChanged: (v) => setState(() => _dealerId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _productId,
                    decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                    items: _models
                        .map((m) => DropdownMenuItem(
                              value: m['product_id'] as int,
                              child: Text(m['picker_label']?.toString() ?? m['label']?.toString() ?? ''),
                            ))
                        .toList(),
                    onChanged: _onProductChanged,
                  ),
                  if (_productId != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imeiRegister,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Register IMEIs (one per line)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: _registerImeis, child: const Text('Register IMEIs')),
                    ),
                    const SizedBox(height: 8),
                    ..._imeis.map((i) {
                      final id = i['id'] as int;
                      final selectable = i['selectable'] != false;
                      final label = i['text']?.toString() ?? i['imei_number']?.toString() ?? '';
                      return CheckboxListTile(
                        value: _selectedImeiIds.contains(id),
                        onChanged: selectable
                            ? (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedImeiIds.add(id);
                                  } else {
                                    _selectedImeiIds.remove(id);
                                  }
                                });
                              }
                            : null,
                        title: Text(label),
                        subtitle: selectable ? null : Text(i['status_label']?.toString() ?? 'Not available'),
                        dense: true,
                      );
                    }),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(
                        onPressed: _selectedImeiIds.isEmpty ? null : _addLineToSale,
                        child: const Text('Add to sale'),
                      ),
                    ),
                  ],
                  if (_saleLines.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Sale lines', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ..._saleLines.asMap().entries.map((entry) {
                      final line = entry.value;
                      return Card(
                        child: ListTile(
                          title: Text(line.productLabel),
                          subtitle: Text(
                            '${line.purchaseLabel}\n'
                            '${line.imeiIds.length} device(s) · '
                            'Buy ${line.unitBuy.toStringAsFixed(0)} · '
                            'Sell ${line.unitSell.toStringAsFixed(0)} · '
                            'Total ${line.lineTotal.toStringAsFixed(0)} TZS',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() => _saleLines.removeAt(entry.key)),
                          ),
                        ),
                      );
                    }),
                    Text(
                      'Grand total: ${_grandTotal().toStringAsFixed(2)} TZS',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(controller: _seller, decoration: const InputDecoration(labelText: 'Seller name (optional)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _paidAmount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Paid amount', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.saleId == null ? 'Create distribution sale' : 'Save changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
