import 'package:flutter/material.dart';
import '../../api/settings_api.dart';
import 'admin_scaffold.dart';

class SettingsRolesScreen extends StatefulWidget {
  const SettingsRolesScreen({super.key});

  @override
  State<SettingsRolesScreen> createState() => _SettingsRolesScreenState();
}

class _SettingsRolesScreenState extends State<SettingsRolesScreen> {
  List<Map<String, dynamic>> _roles = [];
  Map<String, dynamic> _abilityMatrix = {};
  int? _selectedRoleId;
  Set<String> _granted = {};
  bool _loading = true;
  bool _saving = false;
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
      final data = await getSettingsRoles();
      final rolesRaw = data['roles'];
      final roles = rolesRaw is List ? rolesRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];
      final selected = roles.isNotEmpty ? (roles.first['id'] as num).toInt() : null;
      Set<String> granted = {};
      if (selected != null) {
        granted = (await getRolePermissions(selected)).toSet();
      }
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _abilityMatrix = Map<String, dynamic>.from(data['ability_matrix'] as Map? ?? {});
        _selectedRoleId = selected;
        _granted = granted;
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

  Future<void> _changeRole(int? roleId) async {
    if (roleId == null) return;
    setState(() => _loading = true);
    try {
      final granted = (await getRolePermissions(roleId)).toSet();
      if (!mounted) return;
      setState(() {
        _selectedRoleId = roleId;
        _granted = granted;
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

  Future<void> _save() async {
    if (_selectedRoleId == null) return;
    setState(() => _saving = true);
    try {
      await updateRolePermissions(roleId: _selectedRoleId!, permissions: _granted.toList()..sort());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions updated.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Roles & permissions',
      actions: [
        IconButton(
          icon: const Icon(Icons.save_rounded),
          onPressed: _saving ? null : _save,
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                DropdownButtonFormField<int>(
                  value: _selectedRoleId,
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                  items: _roles
                      .map((r) => DropdownMenuItem<int>(
                            value: (r['id'] as num).toInt(),
                            child: Text(r['name']?.toString() ?? 'Role'),
                          ))
                      .toList(),
                  onChanged: _changeRole,
                ),
                const SizedBox(height: 16),
                ..._abilityMatrix.entries.map((entry) {
                  final module = entry.key;
                  final actions = entry.value is List ? (entry.value as List).map((e) => e.toString()).toList() : <String>[];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(module, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ...actions.map((action) {
                          final key = '$module.$action';
                          return CheckboxListTile(
                            value: _granted.contains(key),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _granted.add(key);
                                } else {
                                  _granted.remove(key);
                                }
                              });
                            },
                            title: Text(action),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
