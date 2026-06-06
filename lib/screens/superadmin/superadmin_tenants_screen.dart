import 'package:flutter/material.dart';

import '../../api/superadmin_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import '../admin/widgets/admin_users_ui.dart';
import 'superadmin_scaffold.dart';

class SuperadminTenantsScreen extends StatefulWidget {
  const SuperadminTenantsScreen({super.key});

  @override
  State<SuperadminTenantsScreen> createState() => _SuperadminTenantsScreenState();
}

class _SuperadminTenantsScreenState extends State<SuperadminTenantsScreen> {
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _packages = [];
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
      final result = await getSuperadminTenants();
      final packages = await getSuperadminTenantFormData();
      if (!mounted) return;
      setState(() {
        _list = (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _packages = packages;
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

  Future<void> _openForm({Map<String, dynamic>? tenant}) async {
    final isEdit = tenant != null;
    final name = TextEditingController(text: tenant?['name']?.toString() ?? '');
    final slug = TextEditingController(text: tenant?['slug']?.toString() ?? '');
    final brandName = TextEditingController(text: tenant?['brand_name']?.toString() ?? '');
    String status = tenant?['status']?.toString() ?? 'active';
    int? packageId = (tenant?['package_id'] as num?)?.toInt();

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
                      isEdit ? 'Edit vendor' : 'Add vendor',
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
                      decoration: const InputDecoration(labelText: 'Slug', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: brandName,
                      decoration: const InputDecoration(labelText: 'Brand name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: packageId,
                      decoration: const InputDecoration(labelText: 'Package', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('None')),
                        ..._packages.map((p) {
                          final id = (p['id'] as num).toInt();
                          return DropdownMenuItem<int?>(
                            value: id,
                            child: Text(p['name']?.toString() ?? 'Package $id'),
                          );
                        }),
                      ],
                      onChanged: (v) => setSheetState(() => packageId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                      ],
                      onChanged: (v) => setSheetState(() => status = v ?? 'active'),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        if (name.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Name is required')),
                          );
                          return;
                        }
                        try {
                          final body = {
                            'name': name.text.trim(),
                            if (slug.text.trim().isNotEmpty) 'slug': slug.text.trim(),
                            'brand_name': brandName.text.trim(),
                            'package_id': packageId,
                            'status': status,
                          };
                          if (isEdit) {
                            body['slug'] = slug.text.trim().isNotEmpty ? slug.text.trim() : tenant!['slug'];
                            await updateSuperadminTenant((tenant!['id'] as num).toInt(), body);
                          } else {
                            await createSuperadminTenant(body);
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                          );
                        }
                      },
                      child: Text(isEdit ? 'Save changes' : 'Create vendor'),
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
    brandName.dispose();
    if (saved == true) _load();
  }

  Future<void> _suspend(int id, String vendorName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend vendor?'),
        content: Text('Suspend "$vendorName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Suspend')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await suspendSuperadminTenant(id);
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
      title: 'Vendors',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add vendor'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminUsersPageHeader(
            eyebrow: 'Platform',
            title: 'Vendors',
            subtitle: 'Manage tenant stores on the platform.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const AdminPageLoading()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _error != null
                        ? AdminPageError(message: _error!)
                        : _list.isEmpty
                            ? const AdminPageEmpty(
                                icon: Icons.store_outlined,
                                title: 'No vendors yet',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _list.length,
                                itemBuilder: (context, index) {
                                  final t = _list[index];
                                  final id = (t['id'] as num?)?.toInt();
                                  final name = t['name']?.toString() ?? '–';
                                  final status = t['status']?.toString() ?? '';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: AdminSectionCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                              if (id != null)
                                                PopupMenuButton<String>(
                                                  onSelected: (action) {
                                                    if (action == 'edit') {
                                                      _openForm(tenant: t);
                                                    } else if (action == 'suspend' && status != 'suspended') {
                                                      _suspend(id, name);
                                                    }
                                                  },
                                                  itemBuilder: (_) => [
                                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                                    if (status != 'suspended')
                                                      const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                                                  ],
                                                ),
                                            ],
                                          ),
                                          Text('Slug: ${t['slug'] ?? '–'}', style: bodyMuted(context)),
                                          if (t['package_name'] != null)
                                            Text('Package: ${t['package_name']}', style: bodyMuted(context)),
                                          Text('Status: $status', style: bodyMuted(context)),
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

  TextStyle? bodyMuted(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }
}
