import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/guest_api.dart';
import '../shop/shop_scaffold.dart';

class VendorSubscribeScreen extends StatefulWidget {
  const VendorSubscribeScreen({super.key, required this.package});

  final Map<String, dynamic> package;

  @override
  State<VendorSubscribeScreen> createState() => _VendorSubscribeScreenState();
}

class _VendorSubscribeScreenState extends State<VendorSubscribeScreen> {
  int _step = 1;
  int? _intentId;
  final _vendorName = TextEditingController();
  final _brandName = TextEditingController();
  final _adminName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _paymentPhone = TextEditingController();
  bool _loading = false;
  String? _status;
  String? _message;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _vendorName.dispose();
    _brandName.dispose();
    _adminName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _paymentPhone.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 1) {
      if (_vendorName.text.trim().isEmpty) return;
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      setState(() => _loading = true);
      try {
        final res = await createVendorSubscribeIntent(
          packageSlug: widget.package['slug']?.toString() ?? '',
          vendorName: _vendorName.text.trim(),
          brandName: _brandName.text.trim(),
          adminName: _adminName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          passwordConfirmation: _passwordConfirm.text,
        );
        _intentId = (res['data'] as Map<String, dynamic>?)?['id'] as int?;
        if (!mounted) return;
        setState(() {
          _step = 3;
          _loading = false;
          _paymentPhone.text = _phone.text.trim();
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }
    if (_step == 3 && _intentId != null) {
      setState(() => _loading = true);
      try {
        await startVendorPayment(intentId: _intentId!, paymentPhone: _paymentPhone.text.trim());
        if (!mounted) return;
        setState(() {
          _loading = false;
          _status = 'pending';
          _message = 'Approve payment on your phone…';
        });
        _poll();
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _poll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_intentId == null || _status == 'completed') return;
      try {
        final res = await pollVendorSubscribeStatus(_intentId!);
        if (!mounted) return;
        setState(() {
          _status = res['status']?.toString();
          _message = res['message']?.toString();
        });
        if (_status == 'completed') _pollTimer?.cancel();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.package['name']?.toString() ?? 'Subscribe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: _step / 3, color: kShopBrandOrange, backgroundColor: Colors.grey.shade200),
            const SizedBox(height: 20),
            if (_status == 'completed') ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 12),
              Text(_message ?? 'Subscription completed!', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Sign in')),
            ] else if (_step == 1) ...[
              TextField(controller: _vendorName, decoration: const InputDecoration(labelText: 'Business / vendor name')),
              const SizedBox(height: 12),
              TextField(controller: _brandName, decoration: const InputDecoration(labelText: 'Brand name (optional)')),
            ] else if (_step == 2) ...[
              TextField(controller: _adminName, decoration: const InputDecoration(labelText: 'Admin name')),
              const SizedBox(height: 12),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 12),
              TextField(controller: _passwordConfirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
            ] else ...[
              Text('Total: ${widget.package['price']} TZS', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: _paymentPhone, decoration: const InputDecoration(labelText: 'Payment phone')),
              if (_message != null) ...[const SizedBox(height: 12), Text(_message!, textAlign: TextAlign.center)],
            ],
            if (_status != 'completed') ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _next,
                style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange, minimumSize: const Size.fromHeight(48)),
                child: Text(_loading ? 'Please wait…' : (_step < 3 ? 'Continue' : 'Pay now')),
              ),
              if (_step > 1)
                TextButton(onPressed: _loading ? null : () => setState(() => _step -= 1), child: const Text('Back')),
            ],
          ],
        ),
      ),
    );
  }
}
