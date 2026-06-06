import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/superadmin_api.dart';
import '../../theme/app_theme.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'superadmin_scaffold.dart';

class SuperadminDashboardScreen extends StatefulWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  State<SuperadminDashboardScreen> createState() => _SuperadminDashboardScreenState();
}

class _SuperadminDashboardScreenState extends State<SuperadminDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getSuperadminDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    final stats = _data?['stats'] as Map<String, dynamic>? ?? {};
    final recent = (_data?['recent_tenants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final fmt = NumberFormat('#,##0');

    return SuperadminScaffold(
      showDrawer: true,
      title: 'Platform Dashboard',
      body: _loading
          ? const AdminPageLoading(label: 'Loading dashboard…')
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Platform overview',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _StatCard(label: 'Total vendors', value: fmt.format(stats['tenants_total'] ?? 0)),
                            _StatCard(label: 'Active', value: fmt.format(stats['tenants_active'] ?? 0)),
                            _StatCard(label: 'Suspended', value: fmt.format(stats['tenants_suspended'] ?? 0)),
                            _StatCard(label: 'Packages', value: fmt.format(stats['packages'] ?? 0)),
                            _StatCard(label: 'Regions', value: fmt.format(stats['regions'] ?? 0)),
                            _StatCard(label: 'Brands', value: fmt.format(stats['brands'] ?? 0)),
                            _StatCard(label: 'Models', value: fmt.format(stats['models'] ?? 0)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Recent vendors',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (recent.isEmpty)
                          const AdminPageEmpty(
                            icon: Icons.store_outlined,
                            title: 'No vendors yet',
                          )
                        else
                          ...recent.map((t) {
                            final status = t['status']?.toString() ?? '';
                            final isActive = status == 'active';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: sectionCardDecoration(context),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t['name']?.toString() ?? '–',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        if (t['package_name'] != null)
                                          Text(
                                            t['package_name'].toString(),
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isActive ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
