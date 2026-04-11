import 'package:flutter/material.dart';
import '../../api/admin_branch_transfer_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

class AdminBranchTransferLogsScreen extends StatefulWidget {
  const AdminBranchTransferLogsScreen({super.key});

  @override
  State<AdminBranchTransferLogsScreen> createState() => _AdminBranchTransferLogsScreenState();
}

class _AdminBranchTransferLogsScreenState extends State<AdminBranchTransferLogsScreen> {
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
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(padding: const EdgeInsets.all(20), child: Text(_error!, style: errorStyle()))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _list.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('No history yet.', style: TextStyle(color: Color(0xFF6B7280)))),
                          ],
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
                            final when = l['created_at'] as String? ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: sectionCardDecoration(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(imei, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600)),
                                  if (prod.isNotEmpty) Text(prod, style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(height: 4),
                                  Text('$from → $to', style: Theme.of(context).textTheme.bodySmall),
                                  Text('By $an · $when', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
