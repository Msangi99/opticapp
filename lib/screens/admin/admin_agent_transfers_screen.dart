import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/admin_agent_transfers_api.dart';
import 'admin_agent_transfer_detail_screen.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

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
  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) return '–';
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(value));
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
                ? const AdminPageLoading()
                : _error != null
                    ? AdminPageError(message: _error!)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _list.isEmpty
                            ? const AdminPageEmpty(
                                icon: Icons.swap_horiz_rounded,
                                title: 'No transfers found',
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
                                  final createdAt = _formatDate(t['created_at']?.toString());
                                  final cnt = t['items_count'] as int? ?? (t['items_count'] is num ? (t['items_count'] as num).toInt() : 0);
                                  final statusColor = status == 'approved'
                                      ? const Color(0xFF047857)
                                      : status == 'rejected'
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFFB45309);
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
                                      child: AdminSectionCard(
                                        padding: const EdgeInsets.all(16),
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
                                                Text(
                                                  '$cnt device(s) · $createdAt',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                ),
                                              ],
                                            ),
                                          ),
                                          StatusChip(label: status, color: statusColor),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                                        ],
                                        ),
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
