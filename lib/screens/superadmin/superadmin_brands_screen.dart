import 'package:flutter/material.dart';

import '../../api/superadmin_api.dart';
import '../../theme/app_theme.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'superadmin_scaffold.dart';

class SuperadminBrandsScreen extends StatefulWidget {
  const SuperadminBrandsScreen({super.key});

  @override
  State<SuperadminBrandsScreen> createState() => _SuperadminBrandsScreenState();
}

class _SuperadminBrandsScreenState extends State<SuperadminBrandsScreen> {
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
      final list = await getSuperadminBrands();
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

  Future<void> _openForm({Map<String, dynamic>? brand}) async {
    final isEdit = brand != null;
    final name = TextEditingController(text: brand?['name']?.toString() ?? '');

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Edit brand' : 'Add brand', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  try {
                    if (isEdit) {
                      await updateSuperadminBrand((brand!['id'] as num).toInt(), name.text.trim());
                    } else {
                      await createSuperadminBrand(name.text.trim());
                    }
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          ),
        );
      },
    );

    name.dispose();
    if (saved == true) _load();
  }

  Future<void> _confirmDelete(int id, String brandName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete brand?'),
        content: Text('Remove "$brandName"?'),
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
      await deleteSuperadminBrand(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuperadminScaffold(
      title: 'Brands',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _list.isEmpty
                      ? const AdminPageEmpty(icon: Icons.category_outlined, title: 'No brands yet')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final b = _list[index];
                            final id = (b['id'] as num?)?.toInt();
                            final name = b['name']?.toString() ?? '–';
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
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text('${b['products_count'] ?? 0} models', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  if (id != null)
                                    PopupMenuButton<String>(
                                      onSelected: (action) {
                                        if (action == 'edit') _openForm(brand: b);
                                        if (action == 'delete') _confirmDelete(id, name);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ],
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
