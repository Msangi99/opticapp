import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../api/client.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      final user = await getStoredUser();
      final role = user?['role'] as String?;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else if (role == 'agent') {
        Navigator.pushReplacementNamed(context, '/agent/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'OpticEdge',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            TextSpan(
                              text: 'Africa',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Admin or Agent login',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _error!,
                                  style: errorStyle(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.com',
                                prefixIcon: Icon(Icons.email_outlined, size: 22),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Enter email' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (_formKey.currentState!.validate()) _submit();
                              },
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline, size: 22),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Enter password' : null,
                            ),
                            const SizedBox(height: 28),
                            FilledButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) _submit();
                                    },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign in'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
