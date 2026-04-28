import 'package:flutter/material.dart';
import '../../api/payment_options_api.dart';
import 'admin_scaffold.dart';

class ChannelFormScreen extends StatefulWidget {
  const ChannelFormScreen({super.key, this.channelId});

  final int? channelId;

  @override
  State<ChannelFormScreen> createState() => _ChannelFormScreenState();
}

class _ChannelFormScreenState extends State<ChannelFormScreen> {
  final _nameController = TextEditingController();
  String _type = 'mobile';
  bool _loading = false;
  bool _saving = false;
  final _addAmountController = TextEditingController(text: '0');
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.channelId != null) _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addAmountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getPaymentOptionDetail(widget.channelId!);
      if (!mounted) return;
      setState(() {
        _nameController.text = data['name']?.toString() ?? '';
        _type = data['type']?.toString() ?? 'mobile';
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
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Channel name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.channelId == null) {
        await createPaymentOption(type: _type, name: _nameController.text.trim());
      } else {
        await updatePaymentOption(
          id: widget.channelId!,
          type: _type,
          name: _nameController.text.trim(),
          addAmount: double.tryParse(_addAmountController.text.trim()) ?? 0,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
      return;
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.channelId == null ? 'Create channel' : 'Edit channel',
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
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'mobile'),
                ),
                if (widget.channelId != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Top up amount (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator() : const Text('Save'),
                ),
              ],
            ),
    );
  }
}
