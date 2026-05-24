import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/payment_options_api.dart';
import 'admin_scaffold.dart';
import 'channel_form_screen.dart';

class ChannelDetailScreen extends StatefulWidget {
  const ChannelDetailScreen({super.key, required this.channelId});

  final int channelId;

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen> {
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
      final d = await getPaymentOptionDetail(widget.channelId);
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
    final name = _data['name']?.toString() ?? 'Channel';
    final type = _data['type']?.toString() ?? '—';
    final balance = (_data['balance'] as num?)?.toDouble() ?? 0;
    final hidden = _data['is_hidden'] == true;
    return AdminScaffold(
      title: name,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          onPressed: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => ChannelFormScreen(channelId: widget.channelId)),
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
                    Text('Type: $type'),
                    const SizedBox(height: 8),
                    Text('Balance: ${_fmt(balance)}'),
                    const SizedBox(height: 8),
                    Text('Visibility: ${hidden ? 'Hidden' : 'Visible'}'),
                    const SizedBox(height: 14),
                    FilledButton.tonal(
                      onPressed: () async {
                        await togglePaymentOptionVisibility(widget.channelId);
                        _load();
                      },
                      child: Text(hidden ? 'Show channel' : 'Hide channel'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final amountController = TextEditingController();
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Shrink balance'),
                            content: TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Amount to remove (TZS)',
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Shrink'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !mounted) return;
                        final amount = double.tryParse(amountController.text.trim());
                        amountController.dispose();
                        if (amount == null || amount <= 0) return;
                        try {
                          await shrinkPaymentOptionBalance(id: widget.channelId, shrinkAmount: amount);
                          if (!mounted) return;
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Balance reduced')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                      child: const Text('Shrink balance'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        await deletePaymentOption(widget.channelId);
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('Delete channel'),
                    ),
                  ],
                ),
    );
  }
}
