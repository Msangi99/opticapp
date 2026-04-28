import 'package:flutter/material.dart';
import '../../api/settings_api.dart';
import 'admin_scaffold.dart';
import 'settings_roles_screen.dart';
import 'widgets/admin_page_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _loading = true;
  String? _error;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await getSettings();
      if (!mounted) return;
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      for (final k in data.keys) {
        _controllers[k.toString()] = TextEditingController(text: '${data[k]}');
      }
      setState(() { _settings = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _save() async {
    final toSave = <String, String>{};
    for (final e in _controllers.entries) {
      toSave[e.key] = e.value.text;
    }
    if (toSave.isEmpty) return;
    setState(() { _error = null; });
    try {
      await updateSettings(toSave);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved.'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Settings',
      actions: [
        IconButton(
          icon: const Icon(Icons.admin_panel_settings_rounded),
          tooltip: 'Roles',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsRolesScreen()),
          ),
        ),
        if (_settings.isNotEmpty) IconButton(icon: const Icon(Icons.save_rounded), onPressed: _save, tooltip: 'Save'),
      ],
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : _settings.isEmpty
                  ? const AdminPageEmpty(icon: Icons.settings_outlined, title: 'No settings')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ..._settings.keys.map<Widget>((key) {
                            final k = key.toString();
                            final c = _controllers[k];
                            if (c == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextField(
                                controller: c,
                                decoration: InputDecoration(
                                  labelText: k,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                maxLines: k.toLowerCase().contains('address') || k.toLowerCase().contains('description') ? 3 : 1,
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('Save settings')),
                        ],
                      ),
                    ),
    );
  }
}
