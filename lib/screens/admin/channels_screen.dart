import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/payment_options_api.dart';
import 'admin_scaffold.dart';
import 'channel_detail_screen.dart';
import 'channel_form_screen.dart';
import 'channel_transfer_history_screen.dart';
import 'channel_transfer_screen.dart';
import 'widgets/admin_page_ui.dart';

/// Admin: list payment options (channels).
class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
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
      final list = await getPaymentOptions();
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

  String _formatCurrency(double value) => '${NumberFormat('#,##0').format(value)} TZS';

  IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.payments_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Channels',
      actions: [
        IconButton(
          icon: const Icon(Icons.swap_horiz_rounded),
          tooltip: 'Transfer funds',
          onPressed: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const ChannelTransferScreen()),
            );
            if (changed == true) _load();
          },
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded),
          tooltip: 'Transfer history',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChannelTransferHistoryScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Add channel',
          onPressed: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const ChannelFormScreen()),
            );
            if (changed == true) _load();
          },
        ),
      ],
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _list.isEmpty
                      ? const AdminPageEmpty(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No payment channels',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final o = _list[index];
                            final name = o['name'] as String? ?? '–';
                            final type = o['type'] as String? ?? '–';
                            final balance = (o['balance'] as num?)?.toDouble() ?? 0.0;
                            final hidden = o['is_hidden'] as bool? ?? false;
                            final id = (o['id'] as num?)?.toInt();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: AdminSectionCard(
                                padding: const EdgeInsets.all(16),
                                child: InkWell(
                                  onTap: id == null
                                      ? null
                                      : () async {
                                          final changed = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChannelDetailScreen(channelId: id),
                                            ),
                                          );
                                          if (changed == true) _load();
                                        },
                                  child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_iconForType(type), color: Colors.blue.shade700, size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              type.toUpperCase(),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                            if (hidden) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'HIDDEN',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                    Text(
                                      _formatCurrency(balance),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
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
