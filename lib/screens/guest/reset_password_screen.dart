import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import '../shop/shop_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _token = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _token.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final msg = await resetPasswordWithToken(
        token: _token.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _passwordConfirm.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pushReplacementNamed(context, '/login');
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
      appBar: AppBar(title: const Text('Reset password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Enter the token from your email and choose a new password.', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 20),
            TextField(controller: _token, decoration: const InputDecoration(labelText: 'Reset token', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _passwordConfirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange, minimumSize: const Size.fromHeight(48)),
              child: Text(_loading ? 'Resetting…' : 'Reset password'),
            ),
          ],
        ),
      ),
    );
  }
}
