import 'package:flutter/material.dart';

import '../../api/guest_api.dart';
import '../shop/shop_scaffold.dart';

class DbSetupScreen extends StatefulWidget {
  const DbSetupScreen({super.key});

  @override
  State<DbSetupScreen> createState() => _DbSetupScreenState();
}

class _DbSetupScreenState extends State<DbSetupScreen> {
  final _pass = TextEditingController();
  String? _output;
  bool _loading = false;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _run(String action) async {
    setState(() {
      _loading = true;
      _output = null;
    });
    try {
      final result = await runDbSetupAction(action, _pass.text.trim());
      if (!mounted) return;
      setState(() => _output = result.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _output = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DB setup (dev)')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Calls web /db/* routes. Requires OPTIC_DB_SEED_PASS from server .env.', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Setup password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _loading ? null : () => _run('migrate'), child: const Text('Migrate')),
                FilledButton(onPressed: _loading ? null : () => _run('seed'), child: const Text('Seed')),
                FilledButton(onPressed: _loading ? null : () => _run('setup'), style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange), child: const Text('Setup (migrate+seed)')),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_output != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_output!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
