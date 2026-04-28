import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/expenses_api.dart';
import 'admin_scaffold.dart';
import 'expense_detail_screen.dart';
import 'expense_form_screen.dart';
import 'widgets/admin_page_ui.dart';

/// Admin: list expenses.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Map<String, dynamic>> _list = [];
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
      final list = await getExpenses();
      if (!mounted) return;
      setState(() {
        _list = list;
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

  String _formatCurrency(double value) {
    return '${NumberFormat('#,##0').format(value)} TZS';
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Expenses',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          onPressed: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
            );
            if (changed == true) _load();
          },
        ),
      ],
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _list.isEmpty
                      ? const AdminPageEmpty(icon: Icons.payments_outlined, title: 'No expenses yet')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final e = _list[index];
                            final activity = e['activity'] as String? ?? '–';
                            final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
                            final date = e['date'] as String? ?? '–';
                            final channel = e['payment_option_name'] as String? ?? '–';
                            final id = (e['id'] as num?)?.toInt();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: AdminSectionCard(
                                padding: const EdgeInsets.all(16),
                                child: InkWell(
                                  onTap: id == null
                                      ? null
                                      : () async {
                                          final changed = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: id)),
                                          );
                                          if (changed == true) _load();
                                        },
                                  child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.payments_rounded, color: Colors.orange.shade700, size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activity,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$date · $channel',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                    Text(
                                      _formatCurrency(amount),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}
