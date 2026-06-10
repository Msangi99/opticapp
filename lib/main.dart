import 'package:flutter/material.dart';
import 'api/client.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/stocks_screen.dart';
import 'screens/admin/purchases_screen.dart';
import 'screens/admin/purchase_detail_screen.dart';
import 'screens/admin/purchase_info_screen.dart';
import 'screens/admin/purchase_form_screen.dart';
import 'screens/admin/distribution_form_screen.dart';
import 'screens/admin/purchase_receipts_screen.dart';
import 'screens/admin/stock_detail_screen.dart';
import 'screens/admin/stock_imei_screen.dart';
import 'screens/admin/regions_screen.dart';
import 'screens/admin/add_product_screen.dart';
import 'screens/admin/expenses_screen.dart';
import 'screens/admin/channels_screen.dart';
import 'screens/admin/agent_sales_screen.dart';
import 'screens/admin/orders_screen.dart';
import 'screens/admin/all_users_screen.dart';
import 'screens/admin/dealers_screen.dart';
import 'screens/admin/agents_screen.dart';
import 'screens/admin/categories_screen.dart';
import 'screens/admin/distribution_screen.dart';
import 'screens/admin/distribution_info_screen.dart';
import 'screens/admin/pending_sales_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/admin/settings_screen.dart';
import 'screens/agent/agent_dashboard_screen.dart';
import 'screens/agent/sell_screen.dart';
import 'screens/agent/agent_credits_screen.dart';
import 'screens/agent/agent_transfer_screen.dart';
import 'screens/agent/agent_my_transfers_screen.dart';
import 'screens/agent/agent_transfer_detail_screen.dart';
import 'screens/agent/agent_credit_detail_screen.dart';
import 'screens/agent/agent_sales_history_screen.dart';
import 'screens/agent/agent_sale_detail_screen.dart';
import 'screens/agent/agent_leads_screen.dart';
import 'screens/agent/agent_lead_detail_screen.dart';
import 'screens/agent/agent_return_devices_screen.dart';
import 'screens/admin/admin_agent_transfers_screen.dart';
import 'screens/admin/admin_branch_transfer_screen.dart';
import 'screens/regional_manager/regional_manager_assign_team_leader_screen.dart';
import 'screens/regional_manager/regional_manager_dashboard_screen.dart';
import 'screens/regional_manager/regional_manager_imei_register_screen.dart';
import 'screens/regional_manager/regional_manager_profile_screen.dart';
import 'screens/regional_manager/regional_manager_return_devices_screen.dart';
import 'screens/team_leader/team_leader_assign_agent_screen.dart';
import 'screens/team_leader/team_leader_dashboard_screen.dart';
import 'screens/team_leader/team_leader_imei_register_screen.dart';
import 'screens/team_leader/team_leader_profile_screen.dart';
import 'screens/team_leader/team_leader_return_devices_screen.dart';
import 'screens/admin/admin_more_screens.dart';
import 'screens/admin/product_detail_screen.dart';
import 'screens/admin/passthrough_detail_screen.dart';
import 'screens/admin/stock_receipts_screen.dart';
import 'screens/admin/branch_transfer_items_screen.dart';
import 'screens/admin/admin_assign_agent_products_screen.dart';
import 'screens/admin/selcom_payout_status_screen.dart';
import 'screens/admin/subadmins_screen.dart';
import 'screens/admin/regional_managers_screen.dart';
import 'screens/admin/team_leaders_screen.dart';
import 'screens/admin/assign_regional_manager_devices_screen.dart';
import 'screens/admin/vendors_screen.dart';
import 'screens/superadmin/superadmin_dashboard_screen.dart';
import 'screens/superadmin/superadmin_tenants_screen.dart';
import 'screens/superadmin/superadmin_packages_screen.dart';
import 'screens/superadmin/superadmin_subscription_profits_screen.dart';
import 'screens/superadmin/superadmin_command_center_screen.dart';
import 'screens/superadmin/superadmin_settings_screen.dart';
import 'screens/superadmin/superadmin_regions_screen.dart';
import 'screens/superadmin/superadmin_brands_screen.dart';
import 'screens/superadmin/superadmin_models_screen.dart';
import 'screens/superadmin/superadmin_profile_screen.dart';
import 'screens/shop/shop_dashboard_screen.dart';
import 'screens/shop/shop_browse_screen.dart';
import 'screens/shop/shop_cart_screen.dart';
import 'screens/shop/shop_orders_screen.dart';
import 'screens/shop/shop_addresses_screen.dart';
import 'screens/shop/shop_profile_screen.dart';
import 'screens/shop/dealer_pending_screen.dart';
import 'screens/shop/shop_scaffold.dart';
import 'screens/guest/welcome_screen.dart';
import 'screens/guest/vendor_subscribe_screen.dart';
import 'screens/guest/reset_password_screen.dart';
import 'screens/guest/email_verification_screen.dart';
import 'screens/guest/db_setup_screen.dart';
import 'screens/agent/agent_profile_screen.dart';

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
        '/admin/stocks': (context) => const StocksScreen(pageTitle: 'Stocks'),
        '/admin/purchases': (context) => const PurchasesScreen(),
        '/admin/purchases/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final id = args is Map ? args['id'] as int? : null;
          final isPassthrough = args is Map && args['passthrough'] == true;
          return PurchaseFormScreen(purchaseId: id, isPassthrough: isPassthrough);
        },
        '/admin/passthrough/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final id = args is Map ? args['id'] as int? : null;
          return PurchaseFormScreen(purchaseId: id, isPassthrough: true);
        },
        '/admin/purchases/receipts': (context) => const PurchaseReceiptsScreen(),
        '/admin/purchases/info': (context) => const PurchaseInfoScreen(),
        '/admin/stocks/purchase': (context) => const PurchaseDetailScreen(),
        '/admin/stocks/detail': (context) => const StockDetailScreen(),
        '/admin/stocks/imei': (context) => const StockImeiScreen(),
        '/admin/add-product': (context) => const AddProductScreen(),
        '/admin/expenses': (context) => const ExpensesScreen(),
        '/admin/channels': (context) => const ChannelsScreen(),
        '/admin/stock/agent-sales': (context) => const AgentSalesScreen(),
        '/admin/categories': (context) => const CategoriesScreen(),
        '/admin/orders': (context) => const OrdersScreen(),
        '/admin/customers': (context) => const AllUsersScreen(),
        '/admin/users': (context) => const AllUsersScreen(),
        '/admin/dealers': (context) => const DealersScreen(),
        '/admin/vendors': (context) => const VendorsScreen(),
        '/admin/agents': (context) => const AgentsScreen(),
        '/admin/stock/distribution': (context) => const DistributionScreen(),
        '/admin/stock/distribution/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final id = args is Map ? args['id'] as int? : null;
          return DistributionFormScreen(saleId: id);
        },
        '/admin/stock/distribution/info': (context) => const DistributionInfoScreen(),
        '/admin/stock/pending-sales': (context) => const PendingSalesScreen(),
        '/admin/stock/agent-transfers': (context) => const AdminAgentTransfersScreen(),
        '/admin/assign-agent-products': (context) => const AdminAssignAgentProductsScreen(),
        '/admin/stock/branch-transfer': (context) => const AdminBranchTransferScreen(),
        '/admin/reports': (context) => const ReportsScreen(),
        '/admin/settings': (context) => const SettingsScreen(),
        '/admin/regions': (context) => const RegionsScreen(),
        '/admin/models': (context) => const ModelsScreen(),
        '/admin/imei-search': (context) => const ImeiSearchScreen(),
        '/admin/branches': (context) => const BranchesScreen(),
        '/admin/passthrough': (context) => const PassthroughSalesScreen(),
        '/admin/passthrough-detail': (context) => const PassthroughDetailScreen(),
        '/admin/product-detail': (context) => const ProductDetailScreen(),
        '/admin/stock-receipts': (context) => const StockReceiptsScreen(),
        '/admin/branch-transfer-items': (context) => const BranchTransferItemsScreen(),
        '/admin/agent-credits': (context) => const AdminAgentCreditsScreen(),
        '/admin/leads': (context) => const LeadsReportScreen(),
        '/admin/subscription': (context) => const SubscriptionScreen(),
        '/admin/vendor-profile': (context) => const VendorProfileScreen(),
        '/admin/organization': (context) => const OrganizationTreeScreen(),
        '/admin/payables': (context) => const PayablesScreen(),
        '/admin/shop-records': (context) => const ShopRecordsScreen(),
        '/admin/payout': (context) => const PayoutScreen(),
        '/admin/payout/selcom-status': (context) => const SelcomPayoutStatusScreen(),
        '/admin/profile': (context) => const AdminProfileScreen(),
        '/admin/subadmins': (context) => const SubadminsScreen(),
        '/admin/regional-managers': (context) => const RegionalManagersScreen(),
        '/admin/regional-managers/assign-devices': (context) => const AssignRegionalManagerDevicesScreen(),
        '/admin/team-leaders': (context) => const TeamLeadersScreen(),
        '/shop/dashboard': (context) => const ShopDashboardScreen(),
        '/shop/browse': (context) => const ShopBrowseScreen(),
        '/shop/cart': (context) => const ShopCartScreen(),
        '/shop/orders': (context) => const ShopOrdersScreen(),
        '/shop/addresses': (context) => const ShopAddressesScreen(),
        '/shop/profile': (context) => const ShopProfileScreen(),
        '/shop/dealer-pending': (context) => const DealerPendingScreen(),
        '/team-leader/shop/browse': (context) => const ShopBrowseScreen(apiPrefix: 'team-leader', mode: ShopPortalMode.teamLeader),
        '/team-leader/cart': (context) => const ShopCartScreen(apiPrefix: 'team-leader', mode: ShopPortalMode.teamLeader),
        '/team-leader/orders': (context) => const ShopOrdersScreen(apiPrefix: 'team-leader', mode: ShopPortalMode.teamLeader),
        '/team-leader/addresses': (context) => const ShopAddressesScreen(apiPrefix: 'team-leader', mode: ShopPortalMode.teamLeader),
        '/regional-manager/shop/browse': (context) => const ShopBrowseScreen(apiPrefix: 'regional-manager', mode: ShopPortalMode.regionalManager),
        '/regional-manager/shop/cart': (context) => const ShopCartScreen(apiPrefix: 'regional-manager', mode: ShopPortalMode.regionalManager),
        '/regional-manager/shop/orders': (context) => const ShopOrdersScreen(apiPrefix: 'regional-manager', mode: ShopPortalMode.regionalManager),
        '/regional-manager/shop/addresses': (context) => const ShopAddressesScreen(apiPrefix: 'regional-manager', mode: ShopPortalMode.regionalManager),
        '/welcome': (context) => const WelcomeScreen(),
        '/guest/shop': (context) => const ShopBrowseScreen(publicBrowse: true),
        '/guest/vendor-subscribe': (context) {
          final pkg = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return VendorSubscribeScreen(package: pkg);
        },
        '/guest/reset-password': (context) => const ResetPasswordScreen(),
        '/guest/verify-email': (context) => const EmailVerificationScreen(),
        '/guest/db-setup': (context) => const DbSetupScreen(),
        '/agent/dashboard': (context) => const AgentDashboardScreen(),
        '/agent/sell': (context) => const SellScreen(),
        '/agent/credits': (context) => const AgentCreditsScreen(),
        '/agent/transfer': (context) => const AgentTransferScreen(),
        '/agent/return-devices': (context) => const AgentReturnDevicesScreen(),
        '/agent/transfers': (context) => const AgentMyTransfersScreen(),
        '/agent/transfers/detail': (context) => const AgentTransferDetailScreen(),
        '/agent/credits/detail': (context) => const AgentCreditDetailScreen(),
        '/agent/sales': (context) => const AgentSalesHistoryScreen(),
        '/agent/sales/detail': (context) => const AgentSaleDetailScreen(),
        '/agent/leads': (context) => const AgentLeadsScreen(),
        '/agent/leads/detail': (context) => const AgentLeadDetailScreen(),
        '/agent/profile': (context) => const AgentProfileScreen(),
        '/regional-manager/dashboard': (context) => const RegionalManagerDashboardScreen(),
        '/regional-manager/imei-register': (context) => const RegionalManagerImeiRegisterScreen(),
        '/regional-manager/assign-team-leader': (context) => const RegionalManagerAssignTeamLeaderScreen(),
        '/regional-manager/return-devices': (context) => const RegionalManagerReturnDevicesScreen(),
        '/regional-manager/profile': (context) => const RegionalManagerProfileScreen(),
        '/team-leader/dashboard': (context) => const TeamLeaderDashboardScreen(),
        '/team-leader/imei-register': (context) => const TeamLeaderImeiRegisterScreen(),
        '/team-leader/assign-agent': (context) => const TeamLeaderAssignAgentScreen(),
        '/team-leader/return-devices': (context) => const TeamLeaderReturnDevicesScreen(),
        '/team-leader/profile': (context) => const TeamLeaderProfileScreen(),
        '/superadmin/dashboard': (context) => const SuperadminDashboardScreen(),
        '/superadmin/tenants': (context) => const SuperadminTenantsScreen(),
        '/superadmin/packages': (context) => const SuperadminPackagesScreen(),
        '/superadmin/subscription-profits': (context) => const SuperadminSubscriptionProfitsScreen(),
        '/superadmin/command-center': (context) => const SuperadminCommandCenterScreen(),
        '/superadmin/settings': (context) => const SuperadminSettingsScreen(),
        '/superadmin/regions': (context) => const SuperadminRegionsScreen(),
        '/superadmin/brands': (context) => const SuperadminBrandsScreen(),
        '/superadmin/models': (context) => const SuperadminModelsScreen(),
        '/superadmin/profile': (context) => const SuperadminProfileScreen(),
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

  Future<void> _routeShopUser(Map<String, dynamic>? user) async {
    final role = user?['role'] as String?;
    final status = user?['status'] as String? ?? 'active';
    if (role == 'dealer' && status != 'active') {
      Navigator.pushReplacementNamed(context, '/shop/dealer-pending');
    } else {
      Navigator.pushReplacementNamed(context, '/shop/dashboard');
    }
  }

  Future<void> _check() async {
    final token = await getStoredToken();
    final user = await getStoredUser();
    if (!mounted) return;
    if (token != null && user != null) {
      final role = user['role'] as String?;
      if (role == 'admin' || role == 'subadmin') {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
        return;
      }
      if (role == 'superadmin') {
        Navigator.pushReplacementNamed(context, '/superadmin/dashboard');
        return;
      }
      if (role == 'customer' || role == 'dealer') {
        await _routeShopUser(user);
        return;
      }
      if (role == 'agent') {
        Navigator.pushReplacementNamed(context, '/agent/dashboard');
        return;
      }
      if (role == 'regional_manager') {
        Navigator.pushReplacementNamed(context, '/regional-manager/dashboard');
        return;
      }
      if (role == 'teamleader') {
        Navigator.pushReplacementNamed(context, '/team-leader/dashboard');
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
