import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/admin_modules_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';
import 'widgets/admin_users_ui.dart';

class PassthroughDetailScreen extends StatefulWidget {
  const PassthroughDetailScreen({super.key});

  @override
  State<PassthroughDetailScreen> createState() => _PassthroughDetailScreenState();
}

class _PassthroughDetailScreenState extends State<PassthroughDetailScreen> {
  Map<String, dynamic>? _sale;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) return;
    final id = args['id'] as int?;
    if (id == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final s = await getPassthroughSale(id);
      if (!mounted) return;
      setState(() { _sale = s; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Passthrough',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AdminSectionCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Passthrough Sale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _field('Product', _sale?['product_name']?.toString() ?? '—'),
                          const SizedBox(height: 12),
                          _field('Customer', _sale?['customer_name']?.toString() ?? '—'),
                          const SizedBox(height: 12),
                          _field('Amount', NumberFormat('#,##0').format((_sale?['amount'] as num?)?.toDouble() ?? 0)),
                          const SizedBox(height: 12),
                          _field('Date', _sale?['date']?.toString() ?? '—'),
                          const SizedBox(height: 12),
                          _field('Payment Method', _sale?['payment_method']?.toString() ?? '—'),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAdminTextMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kAdminBrandDark)),
      ],
    );
  }
}
