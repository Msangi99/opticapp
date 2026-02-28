import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/product_list_api.dart';
import '../../theme/app_theme.dart';

/// Detail page for one purchase: list of model, category, IMEI.
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

  int? get _purchaseId {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) return args['id'] as int?;
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _purchaseName = args['name'] as String? ?? 'Purchase';
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_purchaseName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading…', style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadIfNeeded,
              child: _error != null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_error!, style: errorStyle()),
                        ),
                      ),
                    )
                  : _items.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.devices_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No items found',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No products (model / category / IMEI)\nfor this purchase yet.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${_items.length} ${_items.length == 1 ? 'item' : 'items'} in this purchase',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  final model = item['model']?.toString() ?? '–';
                                  final category = item['category']?.toString() ?? '–';
                                  final imei = item['imei_number']?.toString() ?? '–';
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Model Header
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primaryContainer,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.phone_android_rounded,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      model,
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                            color: Theme.of(context).colorScheme.onSurface,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.category_rounded,
                                                            size: 14,
                                                            color: Colors.blue.shade700,
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            category,
                                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                                  color: Colors.blue.shade700,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          // IMEI Section
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.qr_code_rounded,
                                                      size: 18,
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'IMEI Number',
                                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: SelectableText(
                                                        imei,
                                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                              fontFamily: 'monospace',
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 1.2,
                                                              color: Theme.of(context).colorScheme.onSurface,
                                                            ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.copy_rounded),
                                                      onPressed: () => _copyToClipboard(imei, 'IMEI'),
                                                      tooltip: 'Copy IMEI',
                                                      iconSize: 20,
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
