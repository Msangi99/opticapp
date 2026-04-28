import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/expenses_api.dart';
import 'admin_scaffold.dart';
import 'expense_form_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final int expenseId;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await getExpense(widget.expenseId);
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

  String _fmt(double v) => '${NumberFormat('#,##0').format(v)} TZS';

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Expense',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          onPressed: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => ExpenseFormScreen(expenseId: widget.expenseId)),
            );
            if (changed == true) _load();
          },
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(padding: const EdgeInsets.all(16), child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Activity: ${_data['activity'] ?? '—'}'),
                    const SizedBox(height: 8),
                    Text('Amount: ${_fmt((_data['amount'] as num?)?.toDouble() ?? 0)}'),
                    const SizedBox(height: 8),
                    Text('Channel: ${_data['payment_option_name'] ?? '—'}'),
                    const SizedBox(height: 8),
                    Text('Date: ${_data['date'] ?? '—'}'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        await deleteExpense(widget.expenseId);
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('Delete expense'),
                    ),
                  ],
                ),
    );
  }
}
