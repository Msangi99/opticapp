import 'package:flutter/material.dart';
import '../../api/expenses_api.dart';
import '../../api/payment_options_api.dart';
import 'admin_scaffold.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expenseId});

  final int? expenseId;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _activity = TextEditingController();
  final _amount = TextEditingController();
  final _date = TextEditingController();
  int? _paymentOptionId;
  List<Map<String, dynamic>> _channels = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _activity.dispose();
    _amount.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final channels = await getPaymentOptions();
      if (widget.expenseId != null) {
        final expense = await getExpense(widget.expenseId!);
        _activity.text = expense['activity']?.toString() ?? '';
        _amount.text = expense['amount']?.toString() ?? '';
        _date.text = expense['date']?.toString() ?? '';
        final pid = expense['payment_option_id'];
        _paymentOptionId = pid is int ? pid : (pid is num ? pid.toInt() : null);
      }
      if (!mounted) return;
      setState(() {
        _channels = channels;
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
    if (_activity.text.trim().isEmpty || _paymentOptionId == null) {
      setState(() => _error = 'Activity and payment channel are required.');
      return;
    }
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Amount must be greater than zero.');
      return;
    }
    if (_date.text.trim().isEmpty) {
      setState(() => _error = 'Date is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.expenseId == null) {
        await createExpense(
          activity: _activity.text.trim(),
          amount: amount,
          paymentOptionId: _paymentOptionId!,
          date: _date.text.trim(),
        );
      } else {
        await updateExpense(
          id: widget.expenseId!,
          activity: _activity.text.trim(),
          amount: amount,
          paymentOptionId: _paymentOptionId!,
          date: _date.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.expenseId == null ? 'Add expense' : 'Edit expense',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                TextField(
                  controller: _activity,
                  decoration: const InputDecoration(labelText: 'Activity', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _date,
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _paymentOptionId,
                  decoration: const InputDecoration(labelText: 'Payment channel', border: OutlineInputBorder()),
                  items: _channels
                      .map((c) => DropdownMenuItem<int>(value: (c['id'] as num).toInt(), child: Text(c['name'].toString())))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentOptionId = v),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator() : const Text('Save'),
                ),
              ],
            ),
    );
  }
}
