import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/admin_modules_api.dart';
import '../../api/branches_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

/// Generic admin list screen used for payables, shop records, payout, passthrough.
class AdminDataListScreen extends StatefulWidget {
  const AdminDataListScreen({
    super.key,
    required this.title,
    required this.loader,
    required this.itemBuilder,
    this.fab,
  });

  final String title;
  final Future<List<Map<String, dynamic>>> Function() loader;
  final Widget Function(Map<String, dynamic> item) itemBuilder;
  final Widget? fab;

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
    return AdminScaffold(
      title: widget.title,
      floatingActionButton: widget.fab,
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _list.isEmpty
                      ? AdminPageEmpty(icon: Icons.inbox_outlined, title: 'No records')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (_, i) => widget.itemBuilder(_list[i]),
                        ),
            ),
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
    return AdminDataListScreen(
      title: 'Pay out',
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
    );
  }
}

class PassthroughSalesScreen extends StatelessWidget {
  const PassthroughSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataListScreen(
      title: 'Passthrough sales',
      loader: getPassthroughSales,
      itemBuilder: (p) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AdminSectionCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p['name']?.toString() ?? 'Purchase', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${p['date'] ?? ''} · ${p['product_name'] ?? ''} · ${p['payment_status'] ?? ''}'),
          ],
        ),
        ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'IMEI / serial', border: OutlineInputBorder()),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _loading ? null : _search, child: const Text('Search')),
              ],
            ),
          ),
          if (_loading) const Expanded(child: AdminPageLoading()),
          if (!_loading && _error != null) Expanded(child: AdminPageError(message: _error!)),
          if (!_loading && _error == null)
            Expanded(
              child: _results.isEmpty
                  ? const AdminPageEmpty(icon: Icons.qr_code_2, title: 'Search for an IMEI')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await getOrganizationTree();
      if (!mounted) return;
      setState(() {
        _data = res['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _section(String title, List<dynamic>? users) {
    final list = users?.cast<Map<String, dynamic>>() ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AdminSectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: sectionLabelStyle(context)),
          const SizedBox(height: 8),
          ...list.map((u) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${u['name']} (${u['email']}) · ${u['status']}'),
              )),
          if (list.isEmpty) const Text('None', style: TextStyle(color: Colors.grey)),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _data?['stats'] as Map<String, dynamic>?;
    return AdminScaffold(
      title: 'Organization',
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (stats != null)
                    Text(
                      'RM ${stats['regional_managers']} · TL ${stats['team_leaders']} · Agents ${stats['agents']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  const SizedBox(height: 12),
                  _section('Regional managers', _data?['regional_managers'] as List?),
                  _section('Team leaders', _data?['team_leaders'] as List?),
                  _section('Agents', _data?['agents'] as List?),
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await getBranches();
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
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
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
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Agent credit sales',
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_stats != null)
                    AdminSectionCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Pending ${NumberFormat('#,##0').format((_stats!['total_pending'] as num?)?.toDouble() ?? 0)} TZS',
                      ),
                    ),
                  ..._list.map((c) {
                    final id = (c['id'] as num?)?.toInt();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                            Text(c['agent_name']?.toString() ?? '–', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${c['product_name'] ?? ''} · pending ${NumberFormat('#,##0').format((c['pending_amount'] as num?)?.toDouble() ?? 0)}'),
                          ],
                        ),
                      ),
                      ),
                    );
                  }),
                ],
              ),
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
