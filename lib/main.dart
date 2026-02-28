import 'package:flutter/material.dart';
import 'api/client.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/stocks_screen.dart';
import 'screens/admin/purchase_detail_screen.dart';
import 'screens/admin/add_product_screen.dart';
import 'screens/agent/agent_dashboard_screen.dart';
import 'screens/agent/sell_screen.dart';

void main() {
  runApp(const OpticApp());
}

class OpticApp extends StatelessWidget {
  const OpticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Optic',
      theme: appThemeLight,
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/admin/stocks': (context) => const StocksScreen(),
        '/admin/stocks/purchase': (context) => const PurchaseDetailScreen(),
        '/admin/add-product': (context) => const AddProductScreen(),
        '/agent/dashboard': (context) => const AgentDashboardScreen(),
        '/agent/sell': (context) => const SellScreen(),
        '/home': (context) => const _PlaceholderHome(),
      },
      home: const _AuthChecker(),
    );
  }
}

/// On startup, if user is already logged in, go to role-based screen.
class _AuthChecker extends StatefulWidget {
  const _AuthChecker();

  @override
  State<_AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<_AuthChecker> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await getStoredToken();
    final user = await getStoredUser();
    if (!mounted) return;
    if (token != null && user != null) {
      final role = user['role'] as String?;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
        return;
      }
      if (role == 'agent') {
        Navigator.pushReplacementNamed(context, '/agent/dashboard');
        return;
      }
    }
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Optic',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('No specific role screen.')),
    );
  }
}
