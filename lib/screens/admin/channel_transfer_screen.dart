import 'package:flutter/material.dart';
import '../../api/payment_options_api.dart';
import 'admin_scaffold.dart';

class ChannelTransferScreen extends StatefulWidget {
  const ChannelTransferScreen({super.key});

  @override
  State<ChannelTransferScreen> createState() => _ChannelTransferScreenState();
}

class _ChannelTransferScreenState extends State<ChannelTransferScreen> {
  List<Map<String, dynamic>> _channels = [];
  int? _fromId;
  int? _toId;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
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
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getPaymentOptions();
      if (!mounted) return;
      setState(() {
        _channels = list;
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

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (_fromId == null || _toId == null || amount <= 0) {
      setState(() => _error = 'Select channels and valid amount.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await createPaymentTransfer(
        fromChannelId: _fromId!,
        toChannelId: _toId!,
        amount: amount,
        description: _descController.text,
      );
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
      title: 'Transfer funds',
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
                DropdownButtonFormField<int>(
                  value: _fromId,
                  decoration: const InputDecoration(labelText: 'From channel', border: OutlineInputBorder()),
                  items: _channels
                      .map((c) => DropdownMenuItem<int>(value: (c['id'] as num).toInt(), child: Text(c['name'].toString())))
                      .toList(),
                  onChanged: (v) => setState(() => _fromId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _toId,
                  decoration: const InputDecoration(labelText: 'To channel', border: OutlineInputBorder()),
                  items: _channels
                      .map((c) => DropdownMenuItem<int>(value: (c['id'] as num).toInt(), child: Text(c['name'].toString())))
                      .toList(),
                  onChanged: (v) => setState(() => _toId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving ? const CircularProgressIndicator() : const Text('Submit transfer'),
                ),
              ],
            ),
    );
  }
}
