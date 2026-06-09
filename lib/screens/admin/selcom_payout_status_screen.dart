import 'package:flutter/material.dart';

import '../../api/admin_modules_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class SelcomPayoutStatusScreen extends StatefulWidget {
  const SelcomPayoutStatusScreen({super.key});

  @override
  State<SelcomPayoutStatusScreen> createState() => _SelcomPayoutStatusScreenState();
}

class _SelcomPayoutStatusScreenState extends State<SelcomPayoutStatusScreen> {
  final _idCtrl = TextEditingController();
  Map<String, dynamic>? _status;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final id = int.tryParse(_idCtrl.text.trim());
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid Selcom payout ID')));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
    });
    try {
      final s = await getSelcomPayoutStatus(id);
      if (!mounted) return;
      setState(() {
        _status = s;
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

  @override
  Widget build(BuildContext context) {
    final s = _status?['status']?.toString() ?? '';
    final msg = _status?['message']?.toString() ?? '';

    return AdminScaffold(
      title: 'Selcom Status',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Check Selcom Payout Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: _idCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Selcom payout ID',
                    hintText: 'Enter the Selcompay ID from bulk payout',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _check,
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: Text(_loading ? 'Checking…' : 'Check Status'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            AdminPageError(message: _error!),
          ],
          if (_status != null) ...[
            const SizedBox(height: 16),
            AdminSectionCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(s).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(s)),
                        ),
                      ),
                    ],
                  ),
                  if (msg.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(msg, style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'timeout':
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
