import 'package:flutter/material.dart';
import '../../api/purchases_api.dart';
import 'admin_scaffold.dart';

class PurchaseReceiptsScreen extends StatefulWidget {
  const PurchaseReceiptsScreen({super.key});

  @override
  State<PurchaseReceiptsScreen> createState() => _PurchaseReceiptsScreenState();
}

class _PurchaseReceiptsScreenState extends State<PurchaseReceiptsScreen> {
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
      final list = await getPurchaseReceipts();
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

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Purchase receipts',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _list.isEmpty
                      ? ListView(children: const [SizedBox(height: 120, child: Center(child: Text('No receipts found')))])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, i) {
                            final r = _list[i];
                            final url = r['payment_receipt_url']?.toString();
                            return Card(
                              child: ListTile(
                                leading: url != null
                                    ? Image.network(url, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.receipt))
                                    : const Icon(Icons.receipt),
                                title: Text(r['name']?.toString() ?? 'Purchase'),
                                subtitle: Text('${r['date'] ?? ''} · ${r['distributor_name'] ?? ''}'),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
