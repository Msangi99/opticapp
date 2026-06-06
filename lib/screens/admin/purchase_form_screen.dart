import 'package:flutter/material.dart';
import '../../api/branches_api.dart';
import '../../api/payment_options_api.dart';
import '../../api/categories_api.dart';
import '../../api/purchases_api.dart';
import 'admin_scaffold.dart';

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key, this.purchaseId, this.isPassthrough = false});

  final int? purchaseId;
  final bool isPassthrough;

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _name = TextEditingController();
  final _distributor = TextEditingController();
  final _date = TextEditingController();
  final _paidAmount = TextEditingController();
  final _paidDate = TextEditingController();
  int? _branchId;
  int? _paymentOptionId;
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _channels = [];
  List<Map<String, dynamic>> _products = [];
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
    _name.dispose();
    _distributor.dispose();
    _date.dispose();
    _paidAmount.dispose();
    _paidDate.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final branches = await getBranches();
      final channels = await getPaymentOptions();
      final categories = await getCategories();
      final products = <Map<String, dynamic>>[];
      for (final c in categories) {
        final cid = c['id'] as int?;
        if (cid == null) continue;
        final models = await getCategoryModels(cid);
        products.addAll(models);
      }
      if (!mounted) return;
      setState(() {
        _branches = branches;
        _channels = channels;
        _products = products;
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

  Future<void> _save() async {
    if (_branchId == null) {
      setState(() => _error = 'Select a branch.');
      return;
    }
    final product = _products.isNotEmpty ? _products.first : null;
    if (product == null) {
      setState(() => _error = 'No products available.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = {
        'branch_id': _branchId,
        'date': _date.text.trim(),
        if (_name.text.trim().isNotEmpty) 'name': _name.text.trim(),
        if (_distributor.text.trim().isNotEmpty) 'distributor_name': _distributor.text.trim(),
        'lines': [
          {
            'product_id': product['id'],
            'quantity': 1,
            'unit_price': double.tryParse(product['price']?.toString() ?? '0') ?? 1,
          },
        ],
        if (_paidAmount.text.trim().isNotEmpty) 'paid_amount': double.tryParse(_paidAmount.text.trim()) ?? 0,
        if (_paidDate.text.trim().isNotEmpty) 'paid_date': _paidDate.text.trim(),
        if (_paymentOptionId != null) 'payment_option_id': _paymentOptionId,
      };
      if (widget.purchaseId == null) {
        if (widget.isPassthrough) {
          await createPassthrough(body);
        } else {
          await createPurchase(body);
        }
      } else if (widget.isPassthrough) {
        await updatePassthrough(widget.purchaseId!, body);
      } else {
        await updatePurchase(widget.purchaseId!, body);
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
      title: widget.isPassthrough
          ? (widget.purchaseId == null ? 'New passthrough' : 'Edit passthrough')
          : (widget.purchaseId == null ? 'New purchase' : 'Edit purchase'),
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
                  DropdownButtonFormField<int>(
                    value: _branchId,
                    decoration: const InputDecoration(labelText: 'Branch'),
                    items: _branches
                        .map((b) => DropdownMenuItem(value: b['id'] as int, child: Text(b['name']?.toString() ?? '')))
                        .toList(),
                    onChanged: (v) => setState(() => _branchId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _date, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
                  const SizedBox(height: 12),
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Invoice name (optional)')),
                  const SizedBox(height: 12),
                  TextField(controller: _distributor, decoration: const InputDecoration(labelText: 'Distributor')),
                  const SizedBox(height: 12),
                  TextField(controller: _paidAmount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pay amount')),
                  const SizedBox(height: 12),
                  TextField(controller: _paidDate, decoration: const InputDecoration(labelText: 'Paid date')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _paymentOptionId,
                    decoration: const InputDecoration(labelText: 'Payment channel'),
                    items: _channels
                        .map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name']?.toString() ?? '')))
                        .toList(),
                    onChanged: (v) => setState(() => _paymentOptionId = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.purchaseId == null
                            ? (widget.isPassthrough ? 'Create passthrough' : 'Create purchase')
                            : 'Save changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
