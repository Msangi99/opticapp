import 'package:flutter/material.dart';

import '../../api/guest_api.dart';
import '../shop/shop_scaffold.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<dynamic> _packages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final packages = await getPublicPackages();
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: kShopBrandDark),
                children: const [
                  TextSpan(text: 'optic'),
                  TextSpan(text: 'edge', style: TextStyle(color: kShopBrandOrange)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Premium phones. Trusted deals.', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange, minimumSize: const Size.fromHeight(48)),
              child: const Text('Sign in'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/guest/shop'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Browse products'),
            ),
            const SizedBox(height: 32),
            Text('Vendor subscription', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator())
            else if (_packages.isEmpty)
              Text('No packages available', style: TextStyle(color: Colors.grey.shade600))
            else
              ..._packages.map((p) {
                final pkg = p as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(pkg['name']?.toString() ?? ''),
                    subtitle: Text('${pkg['price']} TZS / ${pkg['interval_label']}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(context, '/guest/vendor-subscribe', arguments: pkg),
                  ),
                );
              }),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(onPressed: () => Navigator.pushNamed(context, '/guest/reset-password'), child: const Text('Reset password')),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/guest/verify-email'), child: const Text('Verify email')),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/guest/db-setup'), child: const Text('DB setup (dev)')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
