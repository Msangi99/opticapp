import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/admin_device_returns_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class AdminDeviceReturnsScreen extends StatefulWidget {
  const AdminDeviceReturnsScreen({super.key});

  @override
  State<AdminDeviceReturnsScreen> createState() => _AdminDeviceReturnsScreenState();
}

class _AdminDeviceReturnsScreenState extends State<AdminDeviceReturnsScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) return '–';
    try {
      return DateFormat('MMM dd, yyyy · HH:mm').format(DateTime.parse(value).toLocal());
    } catch (_) {
      return value ?? '–';
    }
  }

  bool _boolFlag(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

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
      final list = await listAdminDeviceReturns(status: _statusFilter);
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

  Future<void> _accept(Map<String, dynamic> row) async {
    final id = row['id'];
    final int? rid = id is int ? id : (id is num ? id.toInt() : null);
    if (rid == null) return;
    try {
      await acceptAdminDeviceReturn(rid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return accepted.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _decline(Map<String, dynamic> row) async {
    final id = row['id'];
    final int? rid = id is int ? id : (id is num ? id.toInt() : null);
    if (rid == null) return;
    try {
      await declineAdminDeviceReturn(rid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return declined.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Device returns',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
          Expanded(
            child: _loading
                ? const AdminPageLoading()
                : _error != null
                    ? AdminPageError(message: _error!)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _list.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  AdminPageEmpty(icon: Icons.undo_rounded, title: 'No device return requests.'),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: _list.length,
                                itemBuilder: (context, index) {
                                  final r = _list[index];
                                  final from = r['from_regional_manager'] as Map<String, dynamic>?;
                                  final name = from?['name'] as String? ?? 'Regional manager';
                                  final cnt = r['items_count'] as int? ?? (r['items_count'] is num ? (r['items_count'] as num).toInt() : 0);
                                  final status = r['status'] as String? ?? '';
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text('$cnt device(s) · ${_formatDate(r['created_at'] as String?)} · ${status.toUpperCase()}'),
                                          if (_boolFlag(r['can_accept']) || _boolFlag(r['can_decline']))
                                            Padding(
                                              padding: const EdgeInsets.only(top: 10),
                                              child: Wrap(
                                                spacing: 8,
                                                children: [
                                                  if (_boolFlag(r['can_accept'])) FilledButton(onPressed: () => _accept(r), child: const Text('Accept')),
                                                  if (_boolFlag(r['can_decline'])) OutlinedButton(onPressed: () => _decline(r), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Decline')),
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
          ),
        ],
      ),
    );
  }
}
