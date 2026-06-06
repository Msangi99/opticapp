import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/guest_api.dart';
import '../shop/shop_scaffold.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _userId = TextEditingController();
  final _hash = TextEditingController();
  bool _loading = false;
  bool _sending = false;

  @override
  void dispose() {
    _userId.dispose();
    _hash.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    final token = await getStoredToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in first to resend verification email')));
      Navigator.pushNamed(context, '/login');
      return;
    }
    setState(() => _sending = true);
    try {
      final msg = await sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      final msg = await verifyEmailWithHash(
        userId: int.parse(_userId.text.trim()),
        hash: _hash.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(onPressed: _sending ? null : _sendLink, child: Text(_sending ? 'Sending…' : 'Resend verification email')),
            const Divider(height: 32),
            Text('Or enter verification details from your email link:', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            TextField(controller: _userId, decoration: const InputDecoration(labelText: 'User ID', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: _hash, decoration: const InputDecoration(labelText: 'Verification hash', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _verify,
              style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange, minimumSize: const Size.fromHeight(48)),
              child: Text(_loading ? 'Verifying…' : 'Verify email'),
            ),
          ],
        ),
      ),
    );
  }
}
