import 'package:flutter/material.dart';

import '../../api/superadmin_api.dart';
import '../../theme/app_theme.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'superadmin_scaffold.dart';

class SuperadminCommandCenterScreen extends StatefulWidget {
  const SuperadminCommandCenterScreen({super.key});

  @override
  State<SuperadminCommandCenterScreen> createState() => _SuperadminCommandCenterScreenState();
}

class _SuperadminCommandCenterScreenState extends State<SuperadminCommandCenterScreen> {
  final _customCmdCtrl = TextEditingController();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String? _output;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customCmdCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await getSuperadminCommandCenter();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  Future<void> _run(Future<String> Function() action) async {
    setState(() {
      _running = true;
      _output = null;
    });
    try {
      final msg = await action();
      if (!mounted) return;
      setState(() => _output = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _output = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commands = (_data?['allowed_commands'] as List?)?.cast<String>() ?? [];
    final migrations = (_data?['migration_files'] as List?)?.cast<String>() ?? [];
    final seeders = (_data?['seeder_classes'] as List?)?.cast<String>() ?? [];
    final tables = (_data?['db_tables'] as List?)?.cast<String>() ?? [];

    return SuperadminScaffold(
      title: 'Command Center',
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: sectionCardDecoration(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Environment', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              Text('PHP ${_data?['php_version']} · ${_data?['php_sapi']}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('PHP Extensions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: sectionCardDecoration(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tracked', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final ext in (_data?['tracked_extensions'] as List?)?.cast<String>() ?? [])
                                    Chip(
                                      label: Text(ext, style: const TextStyle(fontSize: 12)),
                                      deleteIcon: const Icon(Icons.close, size: 16),
                                      onDeleted: _running ? null : () => _run(() async {
                                        final r = await untrackSuperadminExtension(ext);
                                        await _load();
                                        return 'Untracked $ext';
                                      }),
                                    ),
                                  if (((_data?['tracked_extensions'] as List?)?.length ?? 0) == 0)
                                    Text('None tracked', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('All loaded', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final ext in (_data?['extensions'] as List?)?.cast<String>() ?? [])
                                    ActionChip(
                                      label: Text(ext, style: const TextStyle(fontSize: 11)),
                                      onPressed: _running ? null : () => _run(() async {
                                        await trackSuperadminExtension(ext);
                                        await _load();
                                        return 'Tracking $ext';
                                      }),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Artisan commands', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: commands.take(12).map((cmd) {
                            return ActionChip(
                              label: Text(cmd, style: const TextStyle(fontSize: 12)),
                              onPressed: _running
                                  ? null
                                  : () => _run(() => executeSuperadminCommand(command: cmd, force: true)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Text('Run migration file', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (migrations.isNotEmpty)
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Migration'),
                            items: migrations
                                .map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: _running
                                ? null
                                : (v) {
                                    if (v != null) _run(() => migrateSuperadminPath(v));
                                  },
                          ),
                        const SizedBox(height: 20),
                        Text('Run seeder', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (seeders.isNotEmpty)
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Seeder class'),
                            items: seeders
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: _running
                                ? null
                                : (v) {
                                    if (v != null) _run(() => seedSuperadminClass(v, force: true));
                                  },
                          ),
                        const SizedBox(height: 20),
                        Text('Run custom command', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customCmdCtrl,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g. cache:clear',
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _running || _customCmdCtrl.text.trim().isEmpty
                                  ? null
                                  : () => _run(() async {
                                      final r = await runSuperadminCommand(_customCmdCtrl.text.trim(), force: true);
                                      return r['output']?.toString() ?? 'Command finished.';
                                    }),
                              child: const Text('Run'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Empty table', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (tables.isNotEmpty)
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Table'),
                            items: tables
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: _running
                                ? null
                                : (v) async {
                                    if (v == null) return;
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Empty table?'),
                                        content: Text('Truncate all rows in "$v"?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          FilledButton(
                                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Empty'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) _run(() => emptySuperadminTable(v));
                                  },
                          ),
                        if (_running) ...[
                          const SizedBox(height: 24),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        if (_output != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_output!, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }
}
