import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/payment_options_api.dart';
import 'admin_scaffold.dart';

class ChannelTransferHistoryScreen extends StatefulWidget {
  const ChannelTransferHistoryScreen({super.key});

  @override
  State<ChannelTransferHistoryScreen> createState() => _ChannelTransferHistoryScreenState();
}

class _ChannelTransferHistoryScreenState extends State<ChannelTransferHistoryScreen> {
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
      final list = await getPaymentTransferHistory();
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

  String _fmt(double v) => '${NumberFormat('#,##0').format(v)} TZS';

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Transfer history',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(padding: const EdgeInsets.all(16), child: Text(_error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _list.length,
                  itemBuilder: (context, index) {
                    final row = _list[index];
                    final from = row['from_channel']?.toString() ?? '—';
                    final to = row['to_channel']?.toString() ?? '—';
                    final amount = (row['amount'] as num?)?.toDouble() ?? 0;
                    final when = row['created_at']?.toString() ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$from → $to', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(_fmt(amount)),
                          const SizedBox(height: 4),
                          Text(when, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
