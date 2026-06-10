import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/admin_modules_api.dart';
import '../../api/product_list_api.dart';
import '../../api/purchases_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/imei_track_widgets.dart';

/// Detail page for one purchase/stock: list of IMEIs with expandable track info.
class PurchaseDetailScreen extends StatefulWidget {
  const PurchaseDetailScreen({super.key});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _purchaseName = '';
  int? _loadedId;
  final Set<int> _expanded = {};
  final Map<int, Map<String, dynamic>> _trackCache = {};
  final Set<int> _trackLoading = {};

  int? get _purchaseId {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final id = args['id'];
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? '');
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['name'] != null) {
      _purchaseName = args['name'].toString();
    }
    final id = _purchaseId;
    if (id != null && id != _loadedId) _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    final id = _purchaseId;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getPurchaseItems(id);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _loadedId = id;
        _expanded.clear();
        _trackCache.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _toggleExpand(int itemId) async {
    if (_expanded.contains(itemId)) {
      setState(() => _expanded.remove(itemId));
      return;
    }
    setState(() => _expanded.add(itemId));
    if (_trackCache.containsKey(itemId)) return;

    setState(() => _trackLoading.add(itemId));
    try {
      final detail = await getImeiItem(itemId);
      if (!mounted) return;
      setState(() {
        _trackCache[itemId] = detail;
        _trackLoading.remove(itemId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _trackLoading.remove(itemId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteItem(int itemId) async {
    final id = _purchaseId;
    if (id == null) return;
    try {
      await deletePurchaseItem(id, itemId);
      await _loadIfNeeded();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _copyImei(String imei) {
    Clipboard.setData(ClipboardData(text: imei));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('IMEI copied'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _purchaseName,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIfNeeded,
              child: _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [Text(_error!, style: errorStyle())],
                    )
                  : _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.devices_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                    const SizedBox(height: 16),
                                    Text('No IMEIs registered yet', style: Theme.of(context).textTheme.titleMedium),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final itemId = (item['id'] as num?)?.toInt();
                            if (itemId == null) return const SizedBox.shrink();

                            final model = item['model']?.toString() ?? '–';
                            final category = item['category_name']?.toString() ?? item['category']?.toString() ?? '–';
                            final product = item['product_name']?.toString() ?? '–';
                            final imei = item['imei_number']?.toString() ?? '–';
                            final status = item['status']?.toString() ?? 'available';
                            final isAvailable = status == 'available';
                            final expanded = _expanded.contains(itemId);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: sectionCardDecoration(context),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () => _toggleExpand(itemId),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(model, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 4),
                                                SelectableText(
                                                  imei,
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: 'monospace', letterSpacing: 0.5),
                                                ),
                                                const SizedBox(height: 2),
                                                Text('$product / $category', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isAvailable ? const Color(0xFFD1FAE5) : const Color(0xFFE5E7EB),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isAvailable ? 'Available' : 'Sold',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isAvailable ? const Color(0xFF065F46) : const Color(0xFF374151),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy_rounded, size: 18),
                                            tooltip: 'Copy IMEI',
                                            onPressed: () => _copyImei(imei),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20),
                                            onPressed: () => _deleteItem(itemId),
                                            tooltip: 'Delete IMEI',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (expanded)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                      child: _trackLoading.contains(itemId)
                                          ? const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                                            )
                                          : ImeiTrackPanel(detail: _trackCache[itemId] ?? item),
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
