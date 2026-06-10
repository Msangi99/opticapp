import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/admin_modules_api.dart';
import '../../api/stocks_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

/// Lists all IMEI devices in a stock with expandable track/trace info (mirrors web stock-show).
class StockImeiScreen extends StatefulWidget {
  const StockImeiScreen({super.key});

  @override
  State<StockImeiScreen> createState() => _StockImeiScreenState();
}

class _StockImeiScreenState extends State<StockImeiScreen> {
  List<Map<String, dynamic>> _items = [];
  String _stockName = 'Stock';
  bool _loading = true;
  String? _error;
  int? _loadedId;
  final Set<int> _expanded = {};
  final Map<int, Map<String, dynamic>> _trackCache = {};
  final Set<int> _trackLoading = {};

  int? get _stockId {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['id'] != null) {
      final id = args['id'];
      if (id is int) return id;
      return int.tryParse(id.toString());
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['name'] != null) {
      _stockName = args['name'].toString();
    }
    final id = _stockId;
    if (id != null && id != _loadedId) _load();
  }

  Future<void> _load() async {
    final id = _stockId;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await getStockItems(id);
      if (!mounted) return;
      setState(() {
        _items = result['items'] as List<Map<String, dynamic>>;
        _stockName = result['stock_name']?.toString() ?? _stockName;
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

  void _copyImei(String imei) {
    Clipboard.setData(ClipboardData(text: imei));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('IMEI copied'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _stockName,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(_error!, style: errorStyle()),
                        ),
                      ],
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
                                    Text('No devices with IMEI', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 8),
                                    Text('Add products via purchases to register IMEIs.', style: Theme.of(context).textTheme.bodySmall),
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
                            final imei = item['imei_number']?.toString() ?? '–';
                            final product = item['product_name']?.toString() ?? '–';
                            final category = item['category_name']?.toString() ?? '–';
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
                                          : _ImeiTrackPanel(detail: _trackCache[itemId] ?? item),
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

class _ImeiTrackPanel extends StatelessWidget {
  const _ImeiTrackPanel({required this.detail});

  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final track = detail['track'] as Map<String, dynamic>?;
    final sold = track?['sold'] == true || detail['status'] == 'sold';
    final soldAt = detail['sold_at']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                detail['imei_number']?.toString() ?? '–',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: sold ? (track?['sold_label'] == 'installed' ? 'Installed' : 'Sold') : 'In stock',
                color: sold ? const Color(0xFFE5E7EB) : const Color(0xFFD1FAE5),
                textColor: sold ? const Color(0xFF374151) : const Color(0xFF065F46),
              ),
              if (soldAt != null && soldAt.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(soldAt.length > 10 ? soldAt.substring(0, 10) : soldAt, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (track?['purchase_name'] != null)
            _TrackRow(label: 'Purchase / source', value: _purchaseSource(track)),
          if (detail['stock_name'] != null)
            _TrackRow(label: 'Stock', value: detail['stock_name']?.toString() ?? '–'),
          if (!sold) ...[
            if (track?['assigned_agent_name'] != null)
              _TrackRow(
                label: 'Agent assignment',
                value: 'Assigned to ${track!['assigned_agent_name']}${track['assigned_agent_email'] != null ? ' (${track['assigned_agent_email']})' : ''}',
                highlight: true,
              )
            else
              const _TrackRow(label: 'Assignment', value: 'Not assigned — available in warehouse'),
          ],
          if (sold) _SoldTrackSection(track: track),
          const SizedBox(height: 8),
          Text(
            'Product list ID: ${detail['id'] ?? '–'}${detail['product_name'] != null ? ' · Model: ${detail['product_name']}' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _purchaseSource(Map<String, dynamic>? track) {
    if (track == null) return '–';
    final name = track['purchase_name']?.toString() ?? '–';
    final distributor = track['distributor_name']?.toString();
    if (distributor != null && distributor.isNotEmpty) {
      return '$name — Supplier: $distributor';
    }
    return name;
  }
}

class _SoldTrackSection extends StatelessWidget {
  const _SoldTrackSection({this.track});

  final Map<String, dynamic>? track;

  @override
  Widget build(BuildContext context) {
    if (track == null) return const SizedBox.shrink();

    final saleType = track!['sale_type']?.toString();

    if (saleType == 'credit') {
      return _HighlightBox(
        color: const Color(0xFFF5F3FF),
        borderColor: const Color(0xFFDDD6FE),
        title: 'Credit sale (agent)',
        children: [
          if (track!['customer_name'] != null) _TrackRow(label: 'Customer', value: track!['customer_name']?.toString() ?? '–'),
          if (track!['agent_name'] != null) _TrackRow(label: 'Agent', value: track!['agent_name']?.toString() ?? '–'),
          if (track!['payment_status'] != null)
            _TrackRow(
              label: 'Credit status',
              value: '${track!['payment_status']} — Paid ${track!['paid_amount'] ?? 0} / ${track!['total_amount'] ?? 0} TZS',
            ),
          if (track!['payment_channel'] != null) _TrackRow(label: 'Channel', value: track!['payment_channel']?.toString() ?? '–'),
        ],
      );
    }

    if (saleType == 'pending') {
      return _HighlightBox(
        color: const Color(0xFFF0F9FF),
        borderColor: const Color(0xFFBAE6FD),
        title: 'Pending sale',
        children: [
          if (track!['customer_name'] != null) _TrackRow(label: 'Customer', value: track!['customer_name']?.toString() ?? '–'),
          if (track!['seller_name'] != null) _TrackRow(label: 'Seller', value: track!['seller_name']?.toString() ?? '–'),
          if (track!['selling_price'] != null) _TrackRow(label: 'Sale amount', value: '${track!['selling_price']} TZS'),
        ],
      );
    }

    if (saleType == 'agent_sale') {
      return _HighlightBox(
        color: const Color(0xFFFFF7ED),
        borderColor: const Color(0xFFFED7AA),
        title: 'Installed by agent',
        children: [
          if (track!['customer_name'] != null) _TrackRow(label: 'Customer', value: track!['customer_name']?.toString() ?? '–'),
          if (track!['agent_name'] != null) _TrackRow(label: 'Agent', value: track!['agent_name']?.toString() ?? '–'),
          if (track!['total_selling_value'] != null) _TrackRow(label: 'Total value', value: '${track!['total_selling_value']} TZS'),
        ],
      );
    }

    if (saleType == 'unknown') {
      return const _HighlightBox(
        color: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
        title: 'Sold',
        children: [_TrackRow(label: 'Details', value: 'No linked credit, pending sale, or agent sale record')],
      );
    }

    return const SizedBox.shrink();
  }
}

class _HighlightBox extends StatelessWidget {
  const _HighlightBox({required this.color, required this.borderColor, required this.title, required this.children});

  final Color color;
  final Color borderColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: highlight ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color, required this.textColor});

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor, letterSpacing: 0.3)),
    );
  }
}
