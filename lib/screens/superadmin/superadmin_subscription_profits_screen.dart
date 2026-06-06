import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/superadmin_api.dart';
import '../../theme/app_theme.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'superadmin_scaffold.dart';

class SuperadminSubscriptionProfitsScreen extends StatefulWidget {
  const SuperadminSubscriptionProfitsScreen({super.key});

  @override
  State<SuperadminSubscriptionProfitsScreen> createState() => _SuperadminSubscriptionProfitsScreenState();
}

class _SuperadminSubscriptionProfitsScreenState extends State<SuperadminSubscriptionProfitsScreen> {
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
      final data = await getSuperadminSubscriptionProfits();
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

  String _money(num? v) => '${NumberFormat('#,##0').format(v ?? 0)} TZS';

  @override
  Widget build(BuildContext context) {
    final packages = (_data?['packages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final subs = (_data?['active_subscriptions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SuperadminScaffold(
      title: 'Subscription',
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                label: 'Monthly revenue',
                                value: _money(_data?['monthly_revenue'] as num?),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryTile(
                                label: 'Monthly profit',
                                value: _money(_data?['monthly_profit'] as num?),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Packages', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ...packages.map((p) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: sectionCardDecoration(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${p['tenants_count'] ?? 0} vendors · Est. ${_money(p['estimated_monthly_revenue'] as num?)} / mo'),
                                ],
                              ),
                            )),
                        const SizedBox(height: 20),
                        Text('Active subscriptions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (subs.isEmpty)
                          const AdminPageEmpty(icon: Icons.receipt_long_outlined, title: 'No active subscriptions')
                        else
                          ...subs.map((s) {
                            final pkg = s['package'] as Map<String, dynamic>?;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: sectionCardDecoration(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (pkg != null) Text('${pkg['name']} · ${_money(pkg['price'] as num?)}'),
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
