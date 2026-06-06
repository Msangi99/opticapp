import 'package:flutter/material.dart';

import '../../api/superadmin_api.dart';
import '../../theme/app_theme.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'superadmin_scaffold.dart';

class SuperadminRegionsScreen extends StatefulWidget {
  const SuperadminRegionsScreen({super.key});

  @override
  State<SuperadminRegionsScreen> createState() => _SuperadminRegionsScreenState();
}

class _SuperadminRegionsScreenState extends State<SuperadminRegionsScreen> {
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
      final list = await getSuperadminRegions();
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

  Future<void> _openForm({Map<String, dynamic>? region}) async {
    final isEdit = region != null;
    final name = TextEditingController(text: region?['name']?.toString() ?? '');

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
              Text(isEdit ? 'Edit region' : 'Add region', style: Theme.of(ctx).textTheme.titleLarge),
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
                      await updateSuperadminRegion((region!['id'] as num).toInt(), name.text.trim());
                    } else {
                      await createSuperadminRegion(name.text.trim());
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

  Future<void> _confirmDelete(int id, String regionName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete region?'),
        content: Text('Remove "$regionName"?'),
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
      await deleteSuperadminRegion(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuperadminScaffold(
      title: 'Regions',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _list.isEmpty
                      ? const AdminPageEmpty(icon: Icons.public_outlined, title: 'No regions yet')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final r = _list[index];
                            final id = (r['id'] as num?)?.toInt();
                            final name = r['name']?.toString() ?? '–';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: sectionCardDecoration(context),
                              child: Row(
                                children: [
                                  Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  if (id != null)
                                    PopupMenuButton<String>(
                                      onSelected: (action) {
                                        if (action == 'edit') _openForm(region: r);
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
