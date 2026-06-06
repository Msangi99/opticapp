import 'package:flutter/material.dart';

import '../../api/superadmin_api.dart';
import '../../theme/app_theme.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'superadmin_scaffold.dart';

class SuperadminModelsScreen extends StatefulWidget {
  const SuperadminModelsScreen({super.key});

  @override
  State<SuperadminModelsScreen> createState() => _SuperadminModelsScreenState();
}

class _SuperadminModelsScreenState extends State<SuperadminModelsScreen> {
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _brands = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getSuperadminModels(search: search);
      final brands = await getSuperadminModelFormData();
      if (!mounted) return;
      setState(() {
        _list = list;
        _brands = brands;
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

  Future<void> _openForm({Map<String, dynamic>? model}) async {
    final isEdit = model != null;
    final name = TextEditingController(text: model?['name']?.toString() ?? '');
    final description = TextEditingController(text: model?['description']?.toString() ?? '');
    int? categoryId = (model?['category_id'] as num?)?.toInt();
    if (categoryId == null && _brands.isNotEmpty) {
      categoryId = (_brands.first['id'] as num?)?.toInt();
    }

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
                    Text(isEdit ? 'Edit model' : 'Add model', style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: categoryId,
                      decoration: const InputDecoration(labelText: 'Brand *', border: OutlineInputBorder()),
                      items: _brands.map((b) {
                        final id = (b['id'] as num).toInt();
                        return DropdownMenuItem(value: id, child: Text(b['name']?.toString() ?? 'Brand $id'));
                      }).toList(),
                      onChanged: (v) => setSheetState(() => categoryId = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Model name *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        if (name.text.trim().isEmpty || categoryId == null) return;
                        try {
                          final body = {
                            'category_id': categoryId,
                            'name': name.text.trim(),
                            'description': description.text.trim(),
                          };
                          if (isEdit) {
                            await updateSuperadminModel((model!['id'] as num).toInt(), body);
                          } else {
                            await createSuperadminModel(body);
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
              ),
            );
          },
        );
      },
    );

    name.dispose();
    description.dispose();
    if (saved == true) _load(search: _searchController.text);
  }

  Future<void> _confirmDelete(int id, String modelName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete model?'),
        content: Text('Remove "$modelName"?'),
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
      await deleteSuperadminModel(id);
      _load(search: _searchController.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuperadminScaffold(
      title: 'Models',
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search models…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _load();
                  },
                ),
              ),
              onSubmitted: (v) => _load(search: v),
            ),
          ),
          Expanded(
            child: _loading
                ? const AdminPageLoading()
                : RefreshIndicator(
                    onRefresh: () => _load(search: _searchController.text),
                    child: _error != null
                        ? AdminPageError(message: _error!)
                        : _list.isEmpty
                            ? const AdminPageEmpty(icon: Icons.view_in_ar_outlined, title: 'No models found')
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _list.length,
                                itemBuilder: (context, index) {
                                  final m = _list[index];
                                  final id = (m['id'] as num?)?.toInt();
                                  final name = m['name']?.toString() ?? '–';
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
                                              Text(m['category_name']?.toString() ?? '–', style: Theme.of(context).textTheme.bodySmall),
                                            ],
                                          ),
                                        ),
                                        if (id != null)
                                          PopupMenuButton<String>(
                                            onSelected: (action) {
                                              if (action == 'edit') _openForm(model: m);
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
          ),
        ],
      ),
    );
  }
}
