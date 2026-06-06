import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'shop_scaffold.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await getCustomerProfile();
      if (!mounted) return;
      setState(() {
        _name.text = profile['name']?.toString() ?? '';
        _email.text = profile['email']?.toString() ?? '';
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

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      await updateCustomerProfile(name: _name.text.trim(), email: _email.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    setState(() => _savingPassword = true);
    try {
      await updateCustomerPassword(
        currentPassword: _currentPassword.text,
        password: _password.text,
        passwordConfirmation: _passwordConfirm.text,
      );
      if (!mounted) return;
      _currentPassword.clear();
      _password.clear();
      _passwordConfirm.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Profile',
      showDrawer: true,
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _savingProfile ? null : _saveProfile,
                        style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange),
                        child: Text(_savingProfile ? 'Saving…' : 'Save profile'),
                      ),
                      const Divider(height: 40),
                      TextField(controller: _currentPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Current password', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: _passwordConfirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password', border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _savingPassword ? null : _savePassword,
                        child: Text(_savingPassword ? 'Updating…' : 'Update password'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
