import 'package:flutter/material.dart';
import 'api/client.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/stocks_screen.dart';
import 'screens/admin/purchase_detail_screen.dart';
import 'screens/admin/add_product_screen.dart';
import 'screens/admin/expenses_screen.dart';
import 'screens/admin/channels_screen.dart';
import 'screens/admin/agent_sales_screen.dart';
import 'screens/admin/orders_screen.dart';
import 'screens/admin/customers_screen.dart';
import 'screens/admin/dealers_screen.dart';
import 'screens/admin/agents_screen.dart';
import 'screens/admin/categories_screen.dart';
import 'screens/admin/distribution_screen.dart';
import 'screens/admin/pending_sales_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/admin/settings_screen.dart';
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
        '/admin/expenses': (context) => const ExpensesScreen(),
        '/admin/channels': (context) => const ChannelsScreen(),
        '/admin/stock/agent-sales': (context) => const AgentSalesScreen(),
        '/admin/categories': (context) => const CategoriesScreen(),
        '/admin/orders': (context) => const OrdersScreen(),
        '/admin/customers': (context) => const CustomersScreen(),
        '/admin/dealers': (context) => const DealersScreen(),
        '/admin/agents': (context) => const AgentsScreen(),
        '/admin/stock/distribution': (context) => const DistributionScreen(),
        '/admin/stock/pending-sales': (context) => const PendingSalesScreen(),
        '/admin/reports': (context) => const ReportsScreen(),
        '/admin/settings': (context) => const SettingsScreen(),
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
