import 'package:flutter/material.dart';
import '../../api/distribution_sales_api.dart';
import 'admin_scaffold.dart';

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

  Future<void> _save() async {
    if (_purchaseId == null || _dealerId == null || _productId == null || _selectedImeiIds.isEmpty) {
      setState(() => _error = 'Select purchase, dealer, model, and at least one IMEI.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = {
        'date': _date.text.trim(),
        'purchase_id': _purchaseId,
        'dealer_id': _dealerId,
        if (_seller.text.trim().isNotEmpty) 'seller_name': _seller.text.trim(),
        'lines': [
          {
            'product_id': _productId,
            'product_list_ids': _selectedImeiIds.toList(),
          },
        ],
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
                    decoration: const InputDecoration(labelText: 'Purchase', border: OutlineInputBorder()),
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
                        .map((m) => DropdownMenuItem(value: m['product_id'] as int, child: Text(m['picker_label']?.toString() ?? m['label']?.toString() ?? '')))
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
                      final label = i['text']?.toString() ?? i['imei_number']?.toString() ?? '';
                      return CheckboxListTile(
                        value: _selectedImeiIds.contains(id),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedImeiIds.add(id);
                            } else {
                              _selectedImeiIds.remove(id);
                            }
                          });
                        },
                        title: Text(label),
                        dense: true,
                      );
                    }),
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
