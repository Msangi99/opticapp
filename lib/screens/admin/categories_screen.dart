import 'package:flutter/material.dart';
import '../../api/categories_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'category_models_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getCategoriesWithCounts();
      if (!mounted) return;
      setState(() { _list = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Categories',
      body: _loading
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading…', style: TextStyle(color: Color(0xFF6B7280)))]))
          : _error != null
              ? SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: Padding(padding: const EdgeInsets.all(20), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)), child: Text(_error!, style: errorStyle()))))
              : _list.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.category_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)), const SizedBox(height: 16), Text('No categories yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (context, index) {
                          final c = _list[index];
                          final name = c['name'] as String? ?? '–';
                          final count = c['products_count'] as int? ?? 0;
                          final rawId = c['id'];
                          final int? categoryId = switch (rawId) {
                            int i => i,
                            num n => n.toInt(),
                            String s => int.tryParse(s),
                            _ => null,
                          };
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: categoryId == null
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (context) => CategoryModelsScreen(
                                            categoryId: categoryId,
                                            categoryName: name,
                                          ),
                                        ),
                                      );
                                    },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: sectionCardDecoration(context),
                                child: Row(
                                  children: [
                                    Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(10)),
                                        child: Icon(Icons.category_rounded,
                                            color: Theme.of(context).colorScheme.primary, size: 22)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Text(name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(fontWeight: FontWeight.w600))),
                                    Text('$count models',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    if (categoryId != null) ...[
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
