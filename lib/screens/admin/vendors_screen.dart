import 'package:flutter/material.dart';

import '../../api/vendors_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_users_ui.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
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
      final list = await getVendors();
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

  Future<void> _openForm({Map<String, dynamic>? vendor}) async {
    final isEdit = vendor != null;
    final name = TextEditingController(text: vendor?['name']?.toString() ?? '');
    final phone = TextEditingController(text: vendor?['phone']?.toString() ?? '');
    final email = TextEditingController(text: vendor?['email']?.toString() ?? '');
    final office = TextEditingController(text: vendor?['office_name']?.toString() ?? '');
    final location = TextEditingController(text: vendor?['location']?.toString() ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
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
                  decoration: const InputDecoration(labelText: 'Vendor name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: office,
                  decoration: const InputDecoration(labelText: 'Office name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(labelText: 'Location / address', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (name.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Vendor name is required')),
                      );
                      return;
                    }
                    try {
                      if (isEdit) {
                        await updateVendor(
                          id: (vendor!['id'] as num).toInt(),
                          name: name.text.trim(),
                          phone: phone.text.trim(),
                          email: email.text.trim(),
                          officeName: office.text.trim(),
                          location: location.text.trim(),
                        );
                      } else {
                        await createVendor(
                          name: name.text.trim(),
                          phone: phone.text.trim(),
                          email: email.text.trim(),
                          officeName: office.text.trim(),
                          location: location.text.trim(),
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                      );
                    }
                  },
                  child: Text(isEdit ? 'Save changes' : 'Save vendor'),
                ),
              ],
            ),
          ),
        );
      },
    );

    name.dispose();
    phone.dispose();
    email.dispose();
    office.dispose();
    location.dispose();

    if (saved == true) _load();
  }

  Future<void> _confirmDelete(int id, String vendorName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vendor?'),
        content: Text('Remove "$vendorName"? This cannot be undone.'),
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
      await deleteVendor(id);
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
    return AdminScaffold(
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
            eyebrow: 'Partners',
            title: 'Vendors',
            subtitle: 'Manage distributors used on purchase forms.',
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
                          icon: Icons.local_shipping_outlined,
                          title: 'No vendors yet',
                          subtitle: 'Add distributors used on purchase forms.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final v = _list[index];
                            final id = (v['id'] as num?)?.toInt();
                            final name = v['name']?.toString() ?? '–';
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
                                                _openForm(vendor: v);
                                              } else if (action == 'delete') {
                                                _confirmDelete(id, name);
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                                            ],
                                          ),
                                      ],
                                    ),
                                    if (v['phone'] != null && v['phone'].toString().isNotEmpty)
                                      Text(v['phone'].toString(), style: bodyMuted(context)),
                                    if (v['email'] != null && v['email'].toString().isNotEmpty)
                                      Text(v['email'].toString(), style: bodyMuted(context)),
                                    if (v['office_name'] != null && v['office_name'].toString().isNotEmpty)
                                      Text('Office: ${v['office_name']}', style: bodyMuted(context)),
                                    if (v['location'] != null && v['location'].toString().isNotEmpty)
                                      Text(v['location'].toString(), style: bodyMuted(context)),
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
