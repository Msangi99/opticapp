import 'package:flutter/material.dart';

import '../../api/superadmin_api.dart';
import '../../theme/app_theme.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'superadmin_scaffold.dart';

class SuperadminSettingsScreen extends StatefulWidget {
  const SuperadminSettingsScreen({super.key});

  @override
  State<SuperadminSettingsScreen> createState() => _SuperadminSettingsScreenState();
}

class _SuperadminSettingsScreenState extends State<SuperadminSettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _selcomVendorId = TextEditingController();
  final _selcomApiKey = TextEditingController();
  final _selcomApiSecret = TextEditingController();
  final _mailHost = TextEditingController();
  final _mailPort = TextEditingController();
  final _mailUsername = TextEditingController();
  final _mailPassword = TextEditingController();
  final _mailFromAddress = TextEditingController();
  final _mailFromName = TextEditingController();

  String _paymentMode = 'demo';
  String _selcomIsLive = '0';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _selcomVendorId.dispose();
    _selcomApiKey.dispose();
    _selcomApiSecret.dispose();
    _mailHost.dispose();
    _mailPort.dispose();
    _mailUsername.dispose();
    _mailPassword.dispose();
    _mailFromAddress.dispose();
    _mailFromName.dispose();
    super.dispose();
  }

  void _applySettings(Map<String, dynamic> s) {
    _paymentMode = s['vendor_subscription_payment_mode']?.toString() ?? 'demo';
    _selcomVendorId.text = s['selcom_vendor_id']?.toString() ?? '';
    _selcomApiKey.text = s['selcom_api_key']?.toString() ?? '';
    _selcomApiSecret.text = s['selcom_api_secret']?.toString() ?? '';
    _selcomIsLive = s['selcom_is_live']?.toString() ?? '0';
    _mailHost.text = s['mail_host']?.toString() ?? '';
    _mailPort.text = s['mail_port']?.toString() ?? '';
    _mailUsername.text = s['mail_username']?.toString() ?? '';
    _mailPassword.text = s['mail_password']?.toString() ?? '';
    _mailFromAddress.text = s['mail_from_address']?.toString() ?? '';
    _mailFromName.text = s['mail_from_name']?.toString() ?? '';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getSuperadminSettings();
      if (!mounted) return;
      setState(() {
        _settings = data;
        _applySettings(data);
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
    setState(() => _saving = true);
    try {
      await updateSuperadminSettings({
        'vendor_subscription_payment_mode': _paymentMode,
        'selcom_vendor_id': _selcomVendorId.text.trim(),
        'selcom_api_key': _selcomApiKey.text.trim(),
        'selcom_api_secret': _selcomApiSecret.text.trim(),
        'selcom_is_live': _selcomIsLive,
        'mail_host': _mailHost.text.trim(),
        'mail_port': int.tryParse(_mailPort.text.trim()) ?? '',
        'mail_username': _mailUsername.text.trim(),
        'mail_password': _mailPassword.text.trim(),
        'mail_from_address': _mailFromAddress.text.trim(),
        'mail_from_name': _mailFromName.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testSelcom() async {
    try {
      final result = await testSuperadminSelcom();
      if (!mounted) return;
      final ok = result['ok'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? (ok ? 'Connection OK' : 'Test failed'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuperadminScaffold(
      title: 'Platform Settings',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: sectionCardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Payment mode', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _paymentMode,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'demo', child: Text('Demo')),
                              DropdownMenuItem(value: 'live', child: Text('Live')),
                            ],
                            onChanged: (v) => setState(() => _paymentMode = v ?? 'demo'),
                          ),
                          const SizedBox(height: 16),
                          Text('Selcom', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextField(controller: _selcomVendorId, decoration: const InputDecoration(labelText: 'Vendor ID', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _selcomApiKey, decoration: const InputDecoration(labelText: 'API key', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _selcomApiSecret, obscureText: true, decoration: const InputDecoration(labelText: 'API secret', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selcomIsLive,
                            decoration: const InputDecoration(labelText: 'Selcom live mode', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: '0', child: Text('Sandbox')),
                              DropdownMenuItem(value: '1', child: Text('Live')),
                            ],
                            onChanged: (v) => setState(() => _selcomIsLive = v ?? '0'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(onPressed: _testSelcom, child: const Text('Test Selcom connection')),
                          const SizedBox(height: 16),
                          Text('Mail', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextField(controller: _mailHost, decoration: const InputDecoration(labelText: 'Host', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _mailPort, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _mailUsername, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _mailPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _mailFromAddress, decoration: const InputDecoration(labelText: 'From address', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _mailFromName, decoration: const InputDecoration(labelText: 'From name', border: OutlineInputBorder())),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Save settings'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
