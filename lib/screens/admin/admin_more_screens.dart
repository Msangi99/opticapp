import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/admin_modules_api.dart';
import '../../api/invoice_api.dart';
import '../../api/branches_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_users_ui.dart';
import 'widgets/admin_stock_ui.dart';

/// Generic admin list screen used for payables, shop records, payout, passthrough.
class AdminDataListScreen extends StatefulWidget {
  const AdminDataListScreen({
    super.key,
    required this.title,
    required this.loader,
    required this.itemBuilder,
    this.fab,
    this.eyebrow,
    this.shellTitle,
    this.subtitle,
  });

  final String title;
  final Future<List<Map<String, dynamic>>> Function() loader;
  final Widget Function(Map<String, dynamic> item) itemBuilder;
  final Widget? fab;
  final String? eyebrow;
  final String? shellTitle;
  final String? subtitle;

  @override
  State<AdminDataListScreen> createState() => _AdminDataListScreenState();
}

class _AdminDataListScreenState extends State<AdminDataListScreen> {
  List<Map<String, dynamic>> _list = [];
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
      final list = await widget.loader();
      if (!mounted) return;
      setState(() {
        _list = list;
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
    final listBody = _loading
        ? const AdminPageLoading()
        : RefreshIndicator(
            onRefresh: _load,
            child: _error != null
                ? AdminPageError(message: _error!)
                : _list.isEmpty
                    ? AdminPageEmpty(icon: Icons.inbox_outlined, title: 'No records')
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, widget.eyebrow == null ? 16 : 0, 16, 16),
                        itemCount: _list.length,
                        itemBuilder: (_, i) => widget.itemBuilder(_list[i]),
                      ),
          );

    final body = widget.eyebrow != null
        ? AdminStockPageShell(
            eyebrow: widget.eyebrow!,
            title: widget.shellTitle ?? widget.title,
            subtitle: widget.subtitle,
            body: listBody,
          )
        : listBody;

    return AdminScaffold(
      title: widget.title,
      floatingActionButton: widget.fab,
      body: body,
    );
  }
}

class PayablesScreen extends StatelessWidget {
  const PayablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataListScreen(
      title: 'Payables',
      loader: getPayables,
      itemBuilder: (p) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AdminSectionCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p['item_name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${p['date'] ?? ''} · ${NumberFormat('#,##0').format((p['amount'] as num?)?.toDouble() ?? 0)} TZS'),
          ],
        ),
        ),
      ),
    );
  }
}

class ShopRecordsScreen extends StatelessWidget {
  const ShopRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataListScreen(
      title: 'Shop records',
      loader: getShopRecords,
      itemBuilder: (r) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['product_name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${r['date'] ?? ''} · sold ${r['quantity_sold'] ?? 0} · opening ${r['opening_stock'] ?? 0}'),
            ],
          ),
        ),
      ),
    );
  }
}

class PayoutScreen extends StatelessWidget {
  const PayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Pay out',
      actions: [
        IconButton(
          icon: const Icon(Icons.payments_outlined),
          tooltip: 'Bulk Selcom payout',
          onPressed: () async {
            try {
              await bulkSelcomPayout();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk Selcom payout initiated.')));
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.check_circle_outline),
          tooltip: 'Check Selcom status',
          onPressed: () => Navigator.pushNamed(context, '/admin/payout/selcom-status'),
        ),
      ],
      body: AdminDataListScreen(
      title: 'Pay out',
      eyebrow: 'Operations',
      shellTitle: 'Pay out',
      subtitle: 'Agent commission payouts awaiting processing.',
      loader: getPayoutRows,
      itemBuilder: (r) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['agent_name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${r['source']} #${r['source_id']} · ${r['mobile'] ?? ''}'),
                  ],
                ),
              ),
              Text(
                NumberFormat('#,##0').format((r['commission_amount'] as num?)?.toDouble() ?? 0),
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green.shade700),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class PassthroughSalesScreen extends StatefulWidget {
  const PassthroughSalesScreen({super.key});

  @override
  State<PassthroughSalesScreen> createState() => _PassthroughSalesScreenState();
}

class _PassthroughSalesScreenState extends State<PassthroughSalesScreen> {
  List<Map<String, dynamic>> _list = [];
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
      final list = await getPassthroughSales();
      if (!mounted) return;
      setState(() {
        _list = list;
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

  List<AdminStockStat> _summaryStats() {
    var paid = 0;
    var partial = 0;
    var unpaid = 0;
    for (final p in _list) {
      final st = (p['payment_status']?.toString() ?? '').toLowerCase();
      if (st == 'paid') {
        paid++;
      } else if (st == 'partial') {
        partial++;
      } else {
        unpaid++;
      }
    }
    return [
      AdminStockStat(label: 'Entries', value: formatCount(_list.length)),
      AdminStockStat(label: 'Paid', value: formatCount(paid), highlight: true, highlightColor: const Color(0xFF059669)),
      AdminStockStat(label: 'Partial', value: formatCount(partial)),
      AdminStockStat(label: 'Unpaid', value: formatCount(unpaid), highlight: true, highlightColor: const Color(0xFFDC2626)),
    ];
  }

  Future<void> _openForm({int? id}) async {
    final ok = await Navigator.pushNamed(
      context,
      '/admin/passthrough/form',
      arguments: id != null ? {'id': id} : null,
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Passthrough sales',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: AdminStockPageShell(
        eyebrow: 'Inventory',
        title: 'Passthrough',
        subtitle: 'Stock passthrough entries (no IMEI tracking), payments, and sell prices.',
        summaryLabel: _list.isEmpty ? null : 'Summary',
        summaryStats: _list.isEmpty ? null : _summaryStats(),
        summaryColumns: 2,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AdminPageLoading();
    if (_error != null) return AdminPageError(message: _error!);
    if (_list.isEmpty) {
      return const AdminPageEmpty(icon: Icons.swap_horiz_rounded, title: 'No passthrough sales yet');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final p = _list[i];
          final pid = p['id'] is int ? p['id'] as int : int.tryParse(p['id']?.toString() ?? '');
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: pid != null ? () => _openForm(id: pid) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: AdminSectionCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name']?.toString() ?? 'Passthrough', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${p['date'] ?? ''} · ${p['product_name'] ?? ''}', style: TextStyle(color: kAdminTextMuted, fontSize: 13)),
                            Text('Status: ${p['payment_status'] ?? ''}', style: TextStyle(color: kAdminTextMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        tooltip: 'View details',
                        onPressed: pid != null
                            ? () => Navigator.pushNamed(context, '/admin/passthrough-detail', arguments: {'id': pid})
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ImeiSearchScreen extends StatefulWidget {
  const ImeiSearchScreen({super.key});

  @override
  State<ImeiSearchScreen> createState() => _ImeiSearchScreenState();
}

class _ImeiSearchScreenState extends State<ImeiSearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.length < 3) {
      setState(() => _error = 'Enter at least 3 characters');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await searchImei(q);
      if (!mounted) return;
      setState(() {
        _results = list;
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
    return AdminScaffold(
      title: 'IMEI search',
      body: AdminStockPageShell(
        eyebrow: 'Stock',
        title: 'IMEI search',
        subtitle: 'Enter part or all of an IMEI or serial. Open a row for the full device record.',
        trailing: TextButton.icon(
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin/stocks'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to stocks'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AdminSectionCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'IMEI / serial',
                        hintText: 'e.g. 352123456789012',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'At least 3 characters. Up to 100 matches.',
                      style: TextStyle(fontSize: 12, color: kAdminTextMuted),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _loading ? null : _search,
                      style: FilledButton.styleFrom(backgroundColor: kAdminBrandDark),
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading) const Expanded(child: AdminPageLoading()),
            if (!_loading && _error != null) Expanded(child: AdminPageError(message: _error!)),
            if (!_loading && _error == null)
              Expanded(
                child: _results.isEmpty
                    ? const AdminPageEmpty(icon: Icons.qr_code_2, title: 'Search for an IMEI')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                        final r = _results[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: AdminSectionCard(
                          padding: const EdgeInsets.all(16),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(r['imei_number']?.toString() ?? '–'),
                            subtitle: Text(
                              '${r['product_name'] ?? ''} · ${r['category_name'] ?? ''} · ${r['status'] ?? ''}',
                            ),
                            onTap: () async {
                              final id = (r['id'] as num?)?.toInt();
                              if (id == null) return;
                              try {
                                final detail = await getImeiItem(id);
                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(detail['imei_number']?.toString() ?? 'IMEI'),
                                    content: Text(
                                      'Stock: ${detail['stock_name']}\nAgent: ${detail['agent_name'] ?? '–'}\nStatus: ${detail['status']}',
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            },
                          ),
                        ),
                        );
                      },
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class LeadsReportScreen extends StatefulWidget {
  const LeadsReportScreen({super.key});

  @override
  State<LeadsReportScreen> createState() => _LeadsReportScreenState();
}

class _LeadsReportScreenState extends State<LeadsReportScreen> {
  String _period = 'week';
  List<Map<String, dynamic>> _list = [];
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
      final res = await getLeadsReport(period: _period);
      if (!mounted) return;
      setState(() {
        _list = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
    return AdminScaffold(
      title: 'Leads report',
      body: AdminStockPageShell(
        eyebrow: 'Operations',
        title: 'Leads report',
        subtitle: 'Customer needs and product interest captured by agents.',
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'week', label: Text('Week')),
                  ButtonSegment(value: 'month', label: Text('Month')),
                  ButtonSegment(value: 'year', label: Text('Year')),
                ],
                selected: {_period},
                onSelectionChanged: (s) {
                  setState(() => _period = s.first);
                  _load();
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const AdminPageLoading()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _error != null
                          ? AdminPageError(message: _error!)
                          : _list.isEmpty
                              ? const AdminPageEmpty(icon: Icons.leaderboard_outlined, title: 'No leads for this period')
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: _list.length,
                                  itemBuilder: (_, i) {
                                    final n = _list[i];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: AdminSectionCard(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(n['customer_name']?.toString() ?? 'Lead', style: const TextStyle(fontWeight: FontWeight.w600)),
                                            Text('${n['product_name'] ?? ''} · Agent: ${n['agent_name'] ?? ''}'),
                                            Text('${n['customer_phone'] ?? ''} · ${n['branch_name'] ?? ''}'),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map<String, dynamic>? _tenant;
  bool _loading = true;
  bool _renewing = false;
  String? _error;
  String? _renewStatus;

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
      final t = await getTenantProfile();
      if (!mounted) return;
      setState(() {
        _tenant = t;
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

  Future<void> _renew() async {
    final phoneCtrl = TextEditingController();
    final slug = _tenant?['package_slug']?.toString();
    if (slug == null || slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No package assigned — contact support.')));
      return;
    }
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renew subscription'),
        content: TextField(
          controller: phoneCtrl,
          decoration: const InputDecoration(labelText: 'Payment phone', hintText: 'e.g. 0712345678'),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, phoneCtrl.text.trim()), child: const Text('Pay')),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return;
    setState(() {
      _renewing = true;
      _renewStatus = 'Initiating payment…';
    });
    try {
      final result = await subscribeTenant(slug, phone);
      final intentId = result['id'] as int?;
      if (!mounted) return;
      if (intentId == null) {
        setState(() => _renewStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription initiated. Approve on your phone.')));
        return;
      }
      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() => _renewStatus = 'Checking payment status…');
        final status = await getTenantSubscriptionStatus(intentId);
        final s = status['status']?.toString() ?? '';
        if (s == 'completed') {
          setState(() {
            _renewing = false;
            _renewStatus = null;
          });
          await _load();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription renewed!')));
          return;
        }
        if (s == 'failed' || s == 'timeout' || s == 'error') {
          setState(() {
            _renewing = false;
            _renewStatus = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status['message']?.toString() ?? 'Payment failed.')));
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _renewing = false;
        _renewStatus = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Still processing — check back later.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _renewing = false;
        _renewStatus = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Widget _field(String label, String value, {Widget? trailing}) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAdminTextMuted),
          ),
          const SizedBox(height: 4),
          trailing ??
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kAdminBrandDark),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _tenant?['status']?.toString() ?? '';
    final isActive = status == 'active';

    return AdminScaffold(
      title: 'Subscription',
      body: AdminStockPageShell(
        eyebrow: 'Account',
        title: 'Subscription',
        subtitle: 'View your package and billing status. Contact platform support to change package or status.',
        body: _loading
            ? const AdminPageLoading()
            : _error != null
                ? AdminPageError(message: _error!)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        AdminSectionCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Subscription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                isActive
                                    ? 'Your subscription is active.'
                                    : 'Your subscription is suspended. Renew to restore access.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 20),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final half = (constraints.maxWidth - 16) / 2;
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: [
                                      SizedBox(
                                        width: half,
                                        child: _field('Package', _tenant?['package_name']?.toString() ?? '—'),
                                      ),
                                      SizedBox(
                                        width: half,
                                        child: _field('Billing', _tenant?['billing']?.toString() ?? '—'),
                                      ),
                                      SizedBox(
                                        width: half,
                                        child: _field(
                                          'Status',
                                          '',
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isActive ? 'Active' : (status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1)),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isActive ? Colors.green.shade800 : Colors.orange.shade800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: half,
                                        child: _field(
                                          'Subscription ends',
                                          _tenant?['subscription_ends_at_formatted']?.toString() ?? '—',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              if (!isActive) ...[
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _renewing ? null : _renew,
                                    icon: _renewing
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.refresh),
                                    label: Text(_renewing ? (_renewStatus ?? 'Renewing…') : 'Renew Subscription'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _brand = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await getTenantProfile();
      if (!mounted) return;
      _name.text = t['name']?.toString() ?? '';
      _slug.text = t['slug']?.toString() ?? '';
      _brand.text = t['brand_name']?.toString() ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Vendor profile',
      body: _loading
          ? const AdminPageLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _slug, decoration: const InputDecoration(labelText: 'Slug', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _brand, decoration: const InputDecoration(labelText: 'Brand name', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await updateTenantProfile(name: _name.text.trim(), slug: _slug.text.trim(), brandName: _brand.text.trim());
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ],
              ),
            ),
    );
  }
}

class OrganizationTreeScreen extends StatefulWidget {
  const OrganizationTreeScreen({super.key});

  @override
  State<OrganizationTreeScreen> createState() => _OrganizationTreeScreenState();
}

class _OrganizationTreeScreenState extends State<OrganizationTreeScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _stats;
  bool _loading = true;

  static const _branchColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFAD1457),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await getOrganizationTree();
      if (!mounted) return;
      setState(() {
        _data = res['data'] as Map<String, dynamic>?;
        _stats = res['stats'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _node(String title, Color bg, {String? subtitle, Color textColor = Colors.white, double fontSize = 13}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: fontSize),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(color: textColor.withValues(alpha: 0.88), fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _teamColumn(Map<String, dynamic> tl, int colorIndex) {
    final color = _branchColors[colorIndex % _branchColors.length];
    final agents = (tl['agents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Column(
      children: [
        _node(tl['name']?.toString() ?? '–', color),
        const SizedBox(height: 8),
        if (agents.isEmpty)
          const Text('No agents', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))
        else
          ...agents.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _node(
                a['name']?.toString() ?? '–',
                color.withValues(alpha: 0.18),
                subtitle: a['branch_name']?.toString(),
                textColor: color.withValues(alpha: 0.95),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _managerSection(Map<String, dynamic> rm, int index) {
    final tls = (rm['team_leaders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        children: [
          _node(
            rm['name']?.toString() ?? '–',
            const Color(0xFFC0392B),
            subtitle: rm['region_name']?.toString(),
            fontSize: 15,
          ),
          const SizedBox(height: 12),
          if (tls.isEmpty)
            const Text('No team leaders assigned', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: tls.asMap().entries.map((e) => _teamColumn(e.value, e.key + index)).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tree = (_data?['tree'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final unassignedTls = (_data?['unassigned_team_leaders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final unassignedAgents = (_data?['unassigned_agents'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return AdminScaffold(
      title: 'Organization tree',
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const AdminUsersPageHeader(
                    eyebrow: 'Staff',
                    title: 'Organization tree',
                    subtitle: 'Visual hierarchy: regional managers → team leaders → agents.',
                  ),
                  if (_stats != null) ...[
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: [
                        AdminStatCard(value: '${_stats!['regional_managers']}', label: 'Regional managers'),
                        AdminStatCard(value: '${_stats!['team_leaders']}', label: 'Team leaders'),
                        AdminStatCard(value: '${_stats!['agents']}', label: 'Agents'),
                        if ((_stats!['unassigned_team_leaders'] as num? ?? 0) > 0)
                          AdminStatCard(
                            value: '${_stats!['unassigned_team_leaders']}',
                            label: 'Unassigned TLs',
                            highlight: true,
                          ),
                        if ((_stats!['unassigned_agents'] as num? ?? 0) > 0)
                          AdminStatCard(
                            value: '${_stats!['unassigned_agents']}',
                            label: 'Unassigned agents',
                            highlight: true,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (tree.isEmpty && unassignedTls.isEmpty && unassignedAgents.isEmpty)
                    const AdminPageEmpty(
                      icon: Icons.account_tree_outlined,
                      title: 'No organization data yet',
                    )
                  else ...[
                    ...tree.asMap().entries.map((e) => _managerSection(e.value, e.key)),
                    if (unassignedTls.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: sectionCardDecoration(context),
                        child: Column(
                          children: [
                            _node('Unassigned team leaders', const Color(0xFFD97706), fontSize: 14),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: unassignedTls.asMap().entries.map((e) => _teamColumn(e.value, e.key)).toList(),
                            ),
                          ],
                        ),
                      ),
                    if (unassignedAgents.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: sectionCardDecoration(context),
                        child: Column(
                          children: [
                            _node(
                              'Unassigned agents',
                              const Color(0xFFD97706),
                              subtitle: '${unassignedAgents.length} total',
                              fontSize: 14,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: unassignedAgents
                                  .map(
                                    (a) => _node(
                                      a['name']?.toString() ?? '–',
                                      const Color(0xFFF1F5F9),
                                      subtitle: a['branch_name']?.toString(),
                                      textColor: const Color(0xFF475569),
                                      fontSize: 12,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getBranches();
      if (!mounted) return;
      setState(() {
        _list = list;
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

  Future<void> _add() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New branch'),
        content: TextField(controller: name, decoration: const InputDecoration(hintText: 'Branch name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await createBranch(name.text.trim());
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Branches',
      body: AdminStockPageShell(
        eyebrow: 'Organization',
        title: 'Branches',
        subtitle: 'Store or office locations for purchases and reporting.',
        trailing: AdminPrimaryButton(
          label: 'Add branch',
          icon: Icons.add,
          onPressed: _add,
        ),
        summaryLabel: _list.isEmpty ? null : 'Summary',
        summaryStats: _list.isEmpty
            ? null
            : [
                AdminStockStat(label: 'Branches', value: formatCount(_list.length)),
                AdminStockStat(
                  label: 'Purchases linked',
                  value: formatCount(_list.fold<int>(0, (sum, b) => sum + ((b['purchases_count'] as num?)?.toInt() ?? 0))),
                ),
              ],
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AdminPageLoading();
    if (_error != null) return AdminPageError(message: _error!);
    return RefreshIndicator(
      onRefresh: _load,
      child: _list.isEmpty
          ? const AdminPageEmpty(icon: Icons.store_mall_directory_outlined, title: 'No branches yet')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _list.length,
              itemBuilder: (_, i) {
                  final b = _list[i];
                  final id = (b['id'] as num?)?.toInt();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: AdminSectionCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(child: Text(b['name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w600))),
                        if (id != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              try {
                                await deleteBranch(id);
                                _load();
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            },
                          ),
                      ],
                    ),
                    ),
                  );
                },
              ),
    );
  }
}

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await getProducts();
      if (!mounted) return;
      setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Models',
      body: AdminStockPageShell(
        eyebrow: 'Management',
        title: 'Models',
        subtitle: 'Product models linked to brands and stock quantities.',
        body: _loading
            ? const AdminPageLoading()
            : _list.isEmpty
                ? const AdminPageEmpty(icon: Icons.view_in_ar_outlined, title: 'No models yet')
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _list.length,
                      itemBuilder: (_, i) {
                        final p = _list[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: AdminSectionCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${p['category_name'] ?? ''} · stock ${p['stock_quantity'] ?? 0}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class AdminAgentCreditsScreen extends StatefulWidget {
  const AdminAgentCreditsScreen({super.key});

  @override
  State<AdminAgentCreditsScreen> createState() => _AdminAgentCreditsScreenState();
}

class _AdminAgentCreditsScreenState extends State<AdminAgentCreditsScreen> {
  List<Map<String, dynamic>> _list = [];
  Map<String, dynamic>? _stats;
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
      final res = await getAdminAgentCredits();
      if (!mounted) return;
      setState(() {
        _list = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _stats = res['stats'] as Map<String, dynamic>?;
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
    final stats = _stats;
    final summary = stats == null
        ? null
        : [
            AdminStockStat(label: 'Credits', value: formatCount(stats['count'])),
            AdminStockStat(label: 'Total selling', value: formatTzs((stats['total_credit'] as num?)?.toDouble())),
            AdminStockStat(label: 'Total profit', value: formatTzs((stats['total_profit'] as num?)?.toDouble()), highlight: true, highlightColor: const Color(0xFF059669)),
            AdminStockStat(label: 'Pending', value: formatTzs((stats['total_pending'] as num?)?.toDouble()), highlight: true, highlightColor: const Color(0xFFD97706)),
            AdminStockStat(label: 'Paid', value: formatTzs((stats['total_paid'] as num?)?.toDouble())),
          ];

    return AdminScaffold(
      title: 'Agent credit sales',
      body: AdminStockPageShell(
        eyebrow: 'Agents',
        title: 'Agent credit',
        subtitle: 'Loans from agents to customers; record repayments per credit.',
        summaryLabel: summary == null ? null : 'Summary (current filter)',
        summaryStats: summary,
        summaryColumns: 2,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AdminPageLoading();
    if (_error != null) return AdminPageError(message: _error!);
    if (_list.isEmpty) {
      return const AdminPageEmpty(icon: Icons.credit_card_outlined, title: 'No agent credits yet');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final c = _list[i];
          final id = (c['id'] as num?)?.toInt();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: AdminSectionCard(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: id == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdminAgentCreditDetailScreen(creditId: id)),
                        ).then((_) => _load()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['agent_name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '${c['product_name'] ?? ''} · pending ${NumberFormat('#,##0').format((c['pending_amount'] as num?)?.toDouble() ?? 0)}',
                      style: TextStyle(color: kAdminTextMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdminAgentCreditDetailScreen extends StatefulWidget {
  const AdminAgentCreditDetailScreen({super.key, required this.creditId});

  final int creditId;

  @override
  State<AdminAgentCreditDetailScreen> createState() => _AdminAgentCreditDetailScreenState();
}

class _AdminAgentCreditDetailScreenState extends State<AdminAgentCreditDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  final _amount = TextEditingController();
  final _date = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await getAdminAgentCredit(widget.creditId);
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _data;
    return AdminScaffold(
      title: 'Credit detail',
      body: _loading
          ? const AdminPageLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (c != null) ...[
                    Text(c['agent_name']?.toString() ?? '', style: Theme.of(context).textTheme.titleLarge),
                    Text('Total ${c['total_amount']} · Paid ${c['paid_amount']} · Pending ${c['pending_amount']}'),
                  ],
                  const SizedBox(height: 16),
                  TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Payment amount', border: OutlineInputBorder())),
                  TextField(controller: _date, decoration: const InputDecoration(labelText: 'Paid date (YYYY-MM-DD)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await payAdminAgentCredit(
                          agentCreditId: widget.creditId,
                          paidDate: _date.text.trim(),
                          amount: double.parse(_amount.text.trim()),
                        );
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    child: const Text('Record payment'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await payRemainingAdminAgentCredit(widget.creditId);
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    child: const Text('Pay remaining balance'),
                  ),
                  OutlinedButton(
                    onPressed: () => downloadReceiptAndNotify(
                      context,
                      endpoint: '/admin/agent-credits/${widget.creditId}/invoice',
                      fallbackFilename: 'agent-credit-${widget.creditId}.pdf',
                    ),
                    child: const Text('Download invoice'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final total = TextEditingController(text: c?['total_amount']?.toString() ?? '');
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Edit credit'),
                          content: TextField(
                            controller: total,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Total amount'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      try {
                        await updateAdminAgentCredit(widget.creditId, {
                          'total_amount': double.tryParse(total.text.trim()) ?? 0,
                        });
                        if (!mounted) return;
                        await _load();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    child: const Text('Edit credit'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      try {
                        await deleteAdminAgentCredit(widget.creditId);
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    child: const Text('Delete credit'),
                  ),
                ],
              ),
            ),
    );
  }
}

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _currentPw = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await getAdminProfile();
      if (!mounted) return;
      _name.text = p['name']?.toString() ?? '';
      _email.text = p['email']?.toString() ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Profile',
      showDrawer: true,
      body: _loading
          ? const AdminPageLoading()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    try {
                      await updateAdminProfile(name: _name.text.trim(), email: _email.text.trim());
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                  child: const Text('Save profile'),
                ),
                const Divider(height: 32),
                TextField(controller: _currentPw, obscureText: true, decoration: const InputDecoration(labelText: 'Current password', border: OutlineInputBorder())),
                TextField(controller: _pw, obscureText: true, decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder())),
                TextField(controller: _pw2, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    try {
                      await updateAdminPassword(
                        currentPassword: _currentPw.text,
                        password: _pw.text,
                        passwordConfirmation: _pw2.text,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                  child: const Text('Change password'),
                ),
              ],
            ),
    );
  }
}

class WebShopScreen extends StatelessWidget {
  const WebShopScreen({super.key, this.shopUrl = 'https://opticedgeafrica.net/shop'});

  final String shopUrl;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(shopUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open shop')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse shop')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('Online shop (cart & checkout) runs in your browser.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _open(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
