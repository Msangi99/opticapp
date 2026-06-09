import 'package:flutter/material.dart';

import '../../api/admin_branch_transfer_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class BranchTransferItemsScreen extends StatefulWidget {
  const BranchTransferItemsScreen({super.key});

  @override
  State<BranchTransferItemsScreen> createState() => _BranchTransferItemsScreenState();
}

class _BranchTransferItemsScreenState extends State<BranchTransferItemsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final branchId = (args is Map<String, dynamic>) ? args['branch_id'] as int? : null;
    setState(() { _loading = true; _error = null; });
    try {
      final list = branchId != null
          ? await getBranchTransferItems(branchId: branchId)
          : await getBranchTransferItems(unassigned: true);
      if (!mounted) return;
      setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Branch Inventory',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : _items.isEmpty
                  ? const AdminPageEmpty(icon: Icons.inventory_2_outlined, title: 'No items')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: AdminSectionCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['imei']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                                        if (item['model_name'] != null)
                                          Text(item['model_name'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                        if (item['branch_name'] != null)
                                          Text(item['branch_name'].toString(), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
    );
  }
}
