import 'package:flutter/material.dart';

import '../../api/superadmin_api.dart';
import '../../theme/app_theme.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'superadmin_scaffold.dart';

const _intervals = {
  'monthly': 'Monthly',
  'quarterly': 'Quarterly',
  'yearly': 'Yearly',
  'one_time': 'One-time',
};

class SuperadminPackagesScreen extends StatefulWidget {
  const SuperadminPackagesScreen({super.key});

  @override
  State<SuperadminPackagesScreen> createState() => _SuperadminPackagesScreenState();
}

class _SuperadminPackagesScreenState extends State<SuperadminPackagesScreen> {
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
      final list = await getSuperadminPackages();
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

  Future<void> _openForm({Map<String, dynamic>? pkg}) async {
    final isEdit = pkg != null;
    final name = TextEditingController(text: pkg?['name']?.toString() ?? '');
    final slug = TextEditingController(text: pkg?['slug']?.toString() ?? '');
    final price = TextEditingController(text: pkg?['price']?.toString() ?? '0');
    final description = TextEditingController(text: pkg?['description']?.toString() ?? '');
    String interval = pkg?['interval']?.toString() ?? 'monthly';
    bool isActive = pkg?['is_active'] != false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEdit ? 'Edit package' : 'Add package',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: slug,
                      decoration: const InputDecoration(labelText: 'Slug (optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (TZS)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: interval,
                      decoration: const InputDecoration(labelText: 'Interval', border: OutlineInputBorder()),
                      items: _intervals.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setSheetState(() => interval = v ?? 'monthly'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (v) => setSheetState(() => isActive = v),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        if (name.text.trim().isEmpty) return;
                        try {
                          final body = {
                            'name': name.text.trim(),
                            if (slug.text.trim().isNotEmpty) 'slug': slug.text.trim(),
                            'price': double.tryParse(price.text.trim()) ?? 0,
                            'interval': interval,
                            'description': description.text.trim(),
                            'is_active': isActive,
                          };
                          if (isEdit) {
                            await updateSuperadminPackage((pkg!['id'] as num).toInt(), body);
                          } else {
                            await createSuperadminPackage(body);
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                      child: Text(isEdit ? 'Save changes' : 'Create package'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    name.dispose();
    slug.dispose();
    price.dispose();
    description.dispose();
    if (saved == true) _load();
  }

  Future<void> _confirmDelete(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete package?'),
        content: Text('Remove "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await deleteSuperadminPackage(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuperadminScaffold(
      title: 'Packages',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add package'),
      ),
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _list.isEmpty
                      ? const AdminPageEmpty(icon: Icons.inventory_2_outlined, title: 'No packages yet')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final p = _list[index];
                            final id = (p['id'] as num?)?.toInt();
                            final name = p['name']?.toString() ?? '–';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: sectionCardDecoration(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                      ),
                                      if (id != null)
                                        PopupMenuButton<String>(
                                          onSelected: (action) {
                                            if (action == 'edit') _openForm(pkg: p);
                                            if (action == 'delete') _confirmDelete(id, name);
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                                          ],
                                        ),
                                    ],
                                  ),
                                  Text(
                                    '${p['formatted_price'] ?? p['price']} · ${_intervals[p['interval']] ?? p['interval']}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${p['tenants_count'] ?? 0} vendors · ${p['is_active'] == true ? 'Active' : 'Inactive'}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}
