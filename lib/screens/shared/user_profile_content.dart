import 'package:flutter/material.dart';

import '../../api/user_profile_api.dart';
import '../../theme/app_theme.dart';

/// Shared profile form for regional manager and team leader portals.
class UserProfileContent extends StatefulWidget {
  const UserProfileContent({
    super.key,
    required this.rolePrefix,
  });

  /// API prefix: `regional-manager` or `team-leader`.
  final String rolePrefix;

  @override
  State<UserProfileContent> createState() => _UserProfileContentState();
}

class _UserProfileContentState extends State<UserProfileContent> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  String? _error;

  bool get _profileInformationEditable {
    const readOnlyPrefixes = {'team-leader', 'regional-manager', 'agent'};
    return !readOnlyPrefixes.contains(widget.rolePrefix);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await getUserProfileForRole(widget.rolePrefix);
      if (!mounted) return;
      setState(() {
        _nameController.text = profile['name']?.toString() ?? '';
        _emailController.text = profile['email']?.toString() ?? '';
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
    setState(() {
      _savingProfile = true;
      _error = null;
    });
    try {
      await updateUserProfileForRole(
        rolePrefix: widget.rolePrefix,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _savingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _savingProfile = false;
      });
    }
  }

  Future<void> _savePassword() async {
    setState(() {
      _savingPassword = true;
      _error = null;
    });
    try {
      await updateUserPasswordForRole(
        rolePrefix: widget.rolePrefix,
        currentPassword: _currentPasswordController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _passwordController.clear();
      _passwordConfirmController.clear();
      setState(() => _savingPassword = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _savingPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _profileInformationEditable
                  ? 'Update your name and email, or change your password.'
                  : 'Your name and email are managed by an administrator. You can change your password below.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: errorStyle()),
            ],
            const SizedBox(height: 20),
            Text('Profile information', style: sectionLabelStyle(context)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              readOnly: !_profileInformationEditable,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              readOnly: !_profileInformationEditable,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
            if (_profileInformationEditable) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _savingProfile ? null : _saveProfile,
                child: _savingProfile
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save profile'),
              ),
            ],
            const SizedBox(height: 28),
            Text('Password', style: sectionLabelStyle(context)),
            const SizedBox(height: 12),
            TextField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New password',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordConfirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _savingPassword ? null : _savePassword,
              child: _savingPassword
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update password'),
            ),
          ],
        ),
      ),
    );
  }
}
