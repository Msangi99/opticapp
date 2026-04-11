import 'package:flutter/material.dart';
import '../../api/admin_agent_transfers_api.dart';
import '../../theme/app_theme.dart';
import 'admin_agent_transfer_detail_screen.dart';
import 'admin_scaffold.dart';

class AdminAgentTransfersScreen extends StatefulWidget {
  const AdminAgentTransfersScreen({super.key});

  @override
  State<AdminAgentTransfersScreen> createState() => _AdminAgentTransfersScreenState();
}

class _AdminAgentTransfersScreenState extends State<AdminAgentTransfersScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

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
      final list = await getAdminAgentTransfers(status: _statusFilter);
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
      title: 'Agent transfers',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading…', style: TextStyle(color: Color(0xFF6B7280)))]))
                : _error != null
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
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _list.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 100),
                                  Center(child: Text('No transfers.', style: TextStyle(color: Color(0xFF6B7280)))),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _list.length,
                                itemBuilder: (context, index) {
                                  final t = _list[index];
                                  final id = t['id'];
                                  final int? tid = id is int ? id : (id is num ? id.toInt() : null);
                                  final from = t['from_agent'] as Map<String, dynamic>?;
                                  final to = t['to_agent'] as Map<String, dynamic>?;
                                  final status = t['status'] as String? ?? '';
                                  final cnt = t['items_count'] as int? ?? (t['items_count'] is num ? (t['items_count'] as num).toInt() : 0);
                                  return InkWell(
                                    onTap: tid == null
                                        ? null
                                        : () => Navigator.push<void>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AdminAgentTransferDetailScreen(transferId: tid),
                                              ),
                                            ).then((_) => _load()),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: sectionCardDecoration(context),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${from?['name'] ?? '—'} → ${to?['name'] ?? '—'}',
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                                ),
                                                const SizedBox(height: 4),
                                                Text('$cnt device(s) · $status', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
