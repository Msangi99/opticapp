import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/agent_credits_api.dart';
import '../../api/payment_options_api.dart';
import '../../theme/app_theme.dart';
import 'agent_scaffold.dart';

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class AgentCreditsScreen extends StatefulWidget {
  const AgentCreditsScreen({super.key});

  @override
  State<AgentCreditsScreen> createState() => _AgentCreditsScreenState();
}

class _AgentCreditsScreenState extends State<AgentCreditsScreen> {
  List<Map<String, dynamic>> _credits = [];
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
      final list = await getAgentCredits();
      if (!mounted) return;
      setState(() {
        _credits = list;
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

  String _fmtMoney(double v) {
    return '${NumberFormat('#,##0.##').format(v)} TZS';
  }

  String _fmtDate(String? s) {
    if (s == null || s.isEmpty) return '—';
    try {
      return DateFormat('MMM d, y').format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }

  Future<void> _openPaySheet(Map<String, dynamic> credit) async {
    final remaining = _asDouble(credit['remaining']);
    if (remaining <= 0.0001) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This sale is fully paid.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return _PayInstallmentSheet(
          credit: credit,
          remaining: remaining,
          onPaid: () {
            Navigator.pop(ctx);
            _load();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AgentScaffold(
      title: 'Credit',
      showDrawer: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: errorStyle(), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _credits.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Icon(Icons.credit_score_outlined, size: 48, color: Colors.black38),
                            SizedBox(height: 16),
                            Center(
                              child: Text(
                                'No credit sales yet.\nRecord a sale as Credit from Record Sale.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _credits.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final c = _credits[i];
                            final id = _asInt(c['id']);
                            final customer = c['customer_name']?.toString() ?? '—';
                            final phone = c['customer_phone']?.toString();
                            final description = c['description']?.toString();
                            final date = c['date']?.toString();
                            final total = _asDouble(c['total_amount']);
                            final paid = _asDouble(c['paid_amount']);
                            final remaining = _asDouble(c['remaining']);
                            final status = c['payment_status']?.toString() ?? '';
                            final product = c['product_label']?.toString() ?? '—';
                            final imei = c['imei_number']?.toString();

                            final settled = remaining <= 0.0001;
                            Color statusColor;
                            switch (status) {
                              case 'paid':
                                statusColor = successColor;
                                break;
                              case 'partial':
                                statusColor = const Color(0xFFFA8900);
                                break;
                              default:
                                statusColor = theme.colorScheme.outline;
                            }

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: id == null ? null : () => _openPaySheet(c),
                                borderRadius: BorderRadius.circular(12),
                                child: Ink(
                                  decoration: sectionCardDecoration(context),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                customer,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (phone != null && phone.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            phone,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          product,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (description != null && description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            description,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        if (imei != null && imei.isNotEmpty)
                                          Text(
                                            'IMEI: $imei',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        Text(
                                          _fmtDate(date),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Total', style: sectionLabelStyle(context)),
                                            Text(_fmtMoney(total)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Paid', style: sectionLabelStyle(context)),
                                            Text(_fmtMoney(paid)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Remaining',
                                              style: sectionLabelStyle(context).copyWith(
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            Text(
                                              _fmtMoney(remaining),
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!settled) ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            'Tap to record installment',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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

class _PayInstallmentSheet extends StatefulWidget {
  const _PayInstallmentSheet({
    required this.credit,
    required this.remaining,
    required this.onPaid,
  });

  final Map<String, dynamic> credit;
  final double remaining;
  final VoidCallback onPaid;

  @override
  State<_PayInstallmentSheet> createState() => _PayInstallmentSheetState();
}

class _PayInstallmentSheetState extends State<_PayInstallmentSheet> {
  final _amountController = TextEditingController();
  List<Map<String, dynamic>> _options = [];
  int? _paymentOptionId;
  bool _loadingOptions = true;
  bool _submitting = false;
  String? _error;

  int? get _creditId => _asInt(widget.credit['id']);

  @override
  void initState() {
    super.initState();
    final hint = _asDouble(widget.credit['installment_amount']);
    if (hint > 0) {
      final use = hint > widget.remaining ? widget.remaining : hint;
      _amountController.text = use == use.roundToDouble()
          ? use.toInt().toString()
          : use.toStringAsFixed(2);
    } else {
      _amountController.text = widget.remaining == widget.remaining.roundToDouble()
          ? widget.remaining.toInt().toString()
          : widget.remaining.toStringAsFixed(2);
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    try {
      final opts = await getAgentPaymentOptions();
      if (!mounted) return;
      setState(() {
        _options = opts;
        _loadingOptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _options = [];
        _loadingOptions = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _creditId;
    if (id == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (amount > widget.remaining + 0.0001) {
      setState(() => _error = 'Amount cannot exceed remaining balance.');
      return;
    }
    if (_paymentOptionId == null) {
      setState(() => _error = 'Select a payment channel.');
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await payAgentCreditInstallment(
        agentCreditId: id,
        amount: amount,
        paymentOptionId: _paymentOptionId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Installment recorded.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: successColor,
        ),
      );
      widget.onPaid();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = widget.credit['customer_name']?.toString() ?? '—';
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 8, bottom: bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pay installment',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              customer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Remaining: ${NumberFormat('#,##0.##').format(widget.remaining)} TZS',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.payments_outlined, size: 22),
              ),
            ),
            const SizedBox(height: 16),
            Text('Payment channel', style: sectionLabelStyle(context)),
            const SizedBox(height: 8),
            if (_loadingOptions)
              const LinearProgressIndicator()
            else if (_options.isEmpty)
              Text(
                'No payment channels available.',
                style: errorStyle(),
              )
            else
              DropdownButtonFormField<int?>(
                value: _paymentOptionId,
                decoration: const InputDecoration(
                  labelText: 'Channel',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 22),
                ),
                items: _options.map((o) {
                  final oid = o['id'] is int ? o['id'] as int : (o['id'] is num ? (o['id'] as num).toInt() : int.tryParse(o['id'].toString()));
                  final name = o['name']?.toString() ?? '';
                  return DropdownMenuItem<int?>(
                    value: oid,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _paymentOptionId = v),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: errorStyle()),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Record payment'),
            ),
          ],
        ),
      ),
    );
  }
}
