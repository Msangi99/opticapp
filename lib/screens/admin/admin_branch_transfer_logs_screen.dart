import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/admin_branch_transfer_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class AdminBranchTransferLogsScreen extends StatefulWidget {
  const AdminBranchTransferLogsScreen({super.key});

  @override
  State<AdminBranchTransferLogsScreen> createState() => _AdminBranchTransferLogsScreenState();
}

class _AdminBranchTransferLogsScreenState extends State<AdminBranchTransferLogsScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) return '–';
    try {
      return DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

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
      final list = await getBranchTransferLogs();
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
      title: 'Branch transfer history',
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _list.isEmpty
                      ? const AdminPageEmpty(
                          icon: Icons.history_rounded,
                          title: 'No history yet',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final l = _list[index];
                            final imei = l['imei_number'] as String? ?? '—';
                            final prod = l['product_name'] as String? ?? '';
                            final from = l['from_branch'] as String? ?? '—';
                            final to = l['to_branch'] as String? ?? '—';
                            final admin = l['admin'] as Map<String, dynamic>?;
                            final an = admin?['name'] as String? ?? '—';
                            final when = _formatDate(l['created_at'] as String?);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: AdminSectionCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(imei, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600)),
                                    if (prod.isNotEmpty) KeyValueRow(label: 'Product', value: prod),
                                    KeyValueRow(label: 'From', value: from),
                                    KeyValueRow(label: 'To', value: to),
                                    KeyValueRow(label: 'Admin', value: an),
                                    KeyValueRow(label: 'When', value: when),
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
