import 'package:flutter/material.dart';
import '../../api/admin_branch_transfer_api.dart';
import '../../api/branches_api.dart';
import 'admin_branch_transfer_logs_screen.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_page_ui.dart';

class AdminBranchTransferScreen extends StatefulWidget {
  const AdminBranchTransferScreen({super.key});

  @override
  State<AdminBranchTransferScreen> createState() => _AdminBranchTransferScreenState();
}

class _AdminBranchTransferScreenState extends State<AdminBranchTransferScreen> {
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _items = [];
  int? _fromBranchId;
  int? _toBranchId;
  bool _unassigned = false;
  final Set<int> _selected = {};
  bool _loadingBranches = true;
  bool _loadingItems = false;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _loadingBranches = true;
      _error = null;
    });
    try {
      final b = await getBranches();
      if (!mounted) return;
      setState(() {
        _branches = b;
        _loadingBranches = false;
      });
      _refreshItems();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingBranches = false;
      });
    }
  }

  Future<void> _refreshItems() async {
    if (_unassigned) {
      setState(() {
        _loadingItems = true;
        _selected.clear();
        _error = null;
      });
      try {
        final rows = await getBranchTransferItems(unassigned: true);
        if (!mounted) return;
        setState(() {
          _items = rows;
          _loadingItems = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loadingItems = false;
        });
      }
      return;
    }
    if (_fromBranchId == null) {
      setState(() {
        _items = [];
        _selected.clear();
      });
      return;
    }
    setState(() {
      _loadingItems = true;
      _selected.clear();
      _error = null;
    });
    try {
      final rows = await getBranchTransferItems(branchId: _fromBranchId);
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingItems = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_toBranchId == null || _selected.isEmpty) {
      setState(() => _error = 'Select destination branch and at least one device.');
      return;
    }
    if (!_unassigned && _fromBranchId == null) {
      setState(() => _error = 'Select source branch.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await postBranchTransfer(
        toBranchId: _toBranchId!,
        fromBranchId: _unassigned ? null : _fromBranchId,
        unassigned: _unassigned,
        productListIds: _selected.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devices moved.')));
      setState(() => _selected.clear());
      _refreshItems();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Branch transfer',
      actions: [
        TextButton(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const AdminBranchTransferLogsScreen()),
          ),
          child: const Text('History'),
        ),
      ],
      body: _loadingBranches
          ? const AdminPageLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: AdminPageError(message: _error!)),
                  AdminSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  CheckboxListTile(
                    value: _unassigned,
                    onChanged: (v) {
                      setState(() {
                        _unassigned = v ?? false;
                        if (_unassigned) _fromBranchId = null;
                      });
                      _refreshItems();
                    },
                    title: const Text('Unassigned devices only'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!_unassigned) ...[
                    DropdownButtonFormField<int>(
                      value: _fromBranchId,
                      decoration: const InputDecoration(labelText: 'Source branch', border: OutlineInputBorder()),
                      items: _branches
                          .map((b) {
                            final id = b['id'];
                            final int? bid = id is int ? id : (id is num ? id.toInt() : null);
                            if (bid == null) return null;
                            return DropdownMenuItem(value: bid, child: Text(b['name'] as String? ?? ''));
                          })
                          .whereType<DropdownMenuItem<int>>()
                          .toList(),
                      onChanged: (v) {
                        setState(() => _fromBranchId = v);
                        _refreshItems();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<int>(
                    value: _toBranchId,
                    decoration: const InputDecoration(labelText: 'Destination branch', border: OutlineInputBorder()),
                    items: _branches
                        .map((b) {
                          final id = b['id'];
                          final int? bid = id is int ? id : (id is num ? id.toInt() : null);
                          if (bid == null) return null;
                          return DropdownMenuItem(value: bid, child: Text(b['name'] as String? ?? ''));
                        })
                        .whereType<DropdownMenuItem<int>>()
                        .toList(),
                    onChanged: (v) => setState(() => _toBranchId = v),
                  ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Devices', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_loadingItems)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_items.isEmpty)
                    Text(_unassigned || _fromBranchId != null ? 'No devices in this list.' : 'Select source branch.', style: Theme.of(context).textTheme.bodySmall)
                  else
                    ..._items.map((row) {
                      final id = row['id'];
                      final int? lid = id is int ? id : (id is num ? id.toInt() : null);
                      if (lid == null) return const SizedBox.shrink();
                      final label = row['text'] as String? ?? row['imei_number']?.toString() ?? '#$lid';
                      return CheckboxListTile(
                        value: _selected.contains(lid),
                        onChanged: (c) {
                          setState(() {
                            if (c == true) {
                              _selected.add(lid);
                            } else {
                              _selected.remove(lid);
                            }
                          });
                        },
                        title: Text(label, style: const TextStyle(fontSize: 13)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Move selected devices'),
                  ),
                ],
              ),
            ),
    );
  }
}
