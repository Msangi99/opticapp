import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../api/orders_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
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
      final o = await getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = o;
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

  String _formatCurrency(double v) => '${NumberFormat('#,##0').format(v)} TZS';

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '–';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat.yMMMd().add_jm().format(dt.toLocal());
  }

  List<Map<String, dynamic>> _parseItems(Map<String, dynamic> order) {
    final raw = order['items'];
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  Map<String, dynamic>? _parseAddress(Map<String, dynamic> order) {
    final a = order['address'];
    if (a is Map) return Map<String, dynamic>.from(a);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Order #${widget.orderId}',
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
          : _error != null
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_error!, style: errorStyle()),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _order == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SummaryCard(order: _order!, formatCurrency: _formatCurrency, formatDate: _formatDate),
                            const SizedBox(height: 12),
                            _CustomerCard(order: _order!),
                            const SizedBox(height: 12),
                            _ItemsCard(items: _parseItems(_order!), formatCurrency: _formatCurrency),
                            const SizedBox(height: 12),
                            _AddressCard(address: _parseAddress(_order!)),
                            const SizedBox(height: 12),
                            _PaymentCard(order: _order!),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.order,
    required this.formatCurrency,
    required this.formatDate,
  });

  final Map<String, dynamic> order;
  final String Function(double) formatCurrency;
  final String Function(String?) formatDate;

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final total = (order['total_price'] as num?)?.toDouble() ?? 0.0;
    final created = order['created_at'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Text(
                formatCurrency(total),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatDate(created),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final c = order['customer'];
    final name = c is Map ? (c['name'] as String? ?? 'Guest') : 'Guest';
    final email = c is Map ? (c['email'] as String? ?? '—') : '—';
    final role = c is Map ? (c['role'] as String? ?? 'customer') : 'customer';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(
                      role,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items, required this.formatCurrency});

  final List<Map<String, dynamic>> items;
  final String Function(double) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No line items',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          else
            ...items.map((item) {
              final name = item['product_name'] as String? ?? '–';
              final qty = (item['quantity'] as num?)?.toInt() ?? 0;
              final unit = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
              final line = (item['line_total'] as num?)?.toDouble() ?? (unit * qty);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          Text('Qty $qty · ${formatCurrency(unit)} each',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  )),
                        ],
                      ),
                    ),
                    Text(formatCurrency(line), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final Map<String, dynamic>? address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipping / location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (address == null)
            Text(
              'No address on file.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            )
          else ...[
            _addrLine(context, 'Type', address!['type']?.toString()),
            _addrLine(context, 'Address', address!['address']?.toString()),
            _addrLine(context, 'City', address!['city']?.toString()),
            _addrLine(context, 'State', address!['state']?.toString()),
            _addrLine(context, 'ZIP', address!['zip']?.toString()),
            _addrLine(context, 'Country', address!['country']?.toString()),
            Builder(
              builder: (context) {
                final lat = address!['latitude'];
                final lng = address!['longitude'];
                if (lat == null || lng == null) return const SizedBox.shrink();
                final latS = lat.toString();
                final lngS = lng.toString();
                final url = 'https://maps.google.com/?q=$latS,$lngS';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Map link copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Copy map link'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  static Widget _addrLine(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final method = order['payment_method']?.toString() ?? 'N/A';
    final channel = order['payment_channel']?.toString() ?? '—';
    final payStatus = order['payment_status']?.toString() ?? 'pending';
    final shipNote = order['shipping_address']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _row(context, 'Method', method.toUpperCase()),
          _row(context, 'Channel', channel),
          _row(context, 'Payment status', _capitalizeStatus(payStatus)),
          if (shipNote != null && shipNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Shipping note', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(shipNote, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  static String _capitalizeStatus(String s) {
    final t = s.trim();
    if (t.isEmpty) return '—';
    if (t.length == 1) return t.toUpperCase();
    return '${t[0].toUpperCase()}${t.substring(1)}';
  }

  static Widget _row(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(k, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            flex: 3,
            child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
