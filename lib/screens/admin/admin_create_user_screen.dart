import 'package:flutter/material.dart';

import '../../api/users_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_users_ui.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key, required this.role});

  final String role;

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _businessName = TextEditingController();
  final _notes = TextEditingController();

  Map<String, dynamic>? _formData;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  int? _branchId;
  int? _regionId;
  int? _teamLeaderId;
  int? _regionalManagerId;
  int? _subadminRoleId;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _businessName.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    try {
      final data = await getUserCreateFormData(widget.role);
      if (!mounted) return;
      setState(() {
        _formData = data;
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

  String get _title {
    switch (widget.role) {
      case 'subadmin':
        return 'Add admin';
      case 'agent':
        return 'Add agent';
      case 'teamleader':
        return 'Add team leader';
      case 'regional_manager':
        return 'Add regional manager';
      case 'dealer':
        return 'Add dealer';
      default:
        return 'Add user';
    }
  }

  String get _eyebrow {
    switch (widget.role) {
      case 'dealer':
        return 'Partners';
      case 'subadmin':
        return 'Administration';
      default:
        return 'Staff';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'role': widget.role,
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'password': _password.text,
        'password_confirmation': _passwordConfirm.text,
      };
      if (widget.role == 'dealer') {
        payload['business_name'] = _businessName.text.trim();
      }
      if (widget.role == 'subadmin') {
        payload['subadmin_role_id'] = _subadminRoleId;
      }
      if (_branchId != null) payload['branch_id'] = _branchId;
      if (_regionId != null) payload['region_id'] = _regionId;
      if (_teamLeaderId != null) payload['team_leader_id'] = _teamLeaderId;
      if (_regionalManagerId != null) payload['regional_manager_id'] = _regionalManagerId;
      if (_businessName.text.trim().isNotEmpty &&
          (widget.role == 'regional_manager' || widget.role == 'teamleader')) {
        payload['business_name'] = _businessName.text.trim();
      }
      if (_notes.text.trim().isNotEmpty) payload['notes'] = _notes.text.trim();

      await createUser(payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  List<Map<String, dynamic>> _listField(String key) {
    final raw = _formData?[key];
    if (raw is! List) return [];
    return raw.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _title,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AdminUsersPageHeader(
                        eyebrow: _eyebrow,
                        title: _title,
                        subtitle: _subtitleForRole(),
                      ),
                      const SizedBox(height: 16),
                      _field('Name', _name, required: true),
                      _field('Email', _email, required: true, email: true),
                      _field('Phone', _phone, phone: true),
                      if (widget.role == 'dealer') _field('Business name', _businessName, required: true),
                      if (widget.role == 'subadmin') _subadminRoleDropdown(),
                      if (widget.role == 'agent') ...[
                        _branchDropdown(required: false),
                        _teamLeaderDropdown(),
                      ],
                      if (widget.role == 'regional_manager') ...[
                        _regionDropdown(required: true),
                        _field('Organization / title (optional)', _businessName),
                        _field('Notes (optional)', _notes, multiline: true),
                      ],
                      if (widget.role == 'teamleader') ...[
                        _regionDropdown(required: true),
                        _branchDropdown(required: true),
                        _regionalManagerDropdown(),
                        _field('Organization / title (optional)', _businessName),
                        _field('Notes (optional)', _notes, multiline: true),
                      ],
                      _field('Password', _password, required: true, obscure: true),
                      _field('Confirm password', _passwordConfirm, required: true, obscure: true),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AdminOutlineButton(
                              label: 'Cancel',
                              onPressed: _saving ? null : () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saving ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: kAdminBrandDark,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text('Create ${widget.role == 'subadmin' ? 'leader' : widget.role.replaceAll('_', ' ')}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  String? _subtitleForRole() {
    switch (widget.role) {
      case 'agent':
        return 'Create a new agent. They get a dashboard and can sell products you assign.';
      case 'subadmin':
        return 'Create a leader and assign a role from Settings → Roles & Permissions.';
      case 'dealer':
        return 'Create a dealer account. They are active immediately and can log in.';
      case 'regional_manager':
        return 'Create a regional manager account tied to a region.';
      case 'teamleader':
        return 'Create a team leader tied to a branch and regional manager.';
      default:
        return null;
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool obscure = false,
    bool email = false,
    bool phone = false,
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: email
            ? TextInputType.emailAddress
            : phone
                ? TextInputType.phone
                : TextInputType.text,
        maxLines: multiline ? 3 : 1,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) return '$label is required';
          if (email && v != null && v.isNotEmpty && !v.contains('@')) return 'Enter a valid email';
          if (obscure && required && (v == null || v.length < 8)) return 'Minimum 8 characters';
          return null;
        },
      ),
    );
  }

  Widget _branchDropdown({required bool required}) {
    final branches = _listField('branches');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        value: _branchId,
        decoration: InputDecoration(
          labelText: required ? 'Branch *' : 'Branch',
          border: const OutlineInputBorder(),
        ),
        items: [
          if (!required) const DropdownMenuItem(value: null, child: Text('— No branch —')),
          ...branches.map(
            (b) => DropdownMenuItem(
              value: (b['id'] as num).toInt(),
              child: Text(b['name']?.toString() ?? ''),
            ),
          ),
        ],
        onChanged: (v) => setState(() => _branchId = v),
        validator: required ? (v) => v == null ? 'Branch is required' : null : null,
      ),
    );
  }

  Widget _regionDropdown({required bool required}) {
    final regions = _listField('regions');
    if (regions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Text('No regions found. Run migrations and seed regions first.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        value: _regionId,
        decoration: InputDecoration(
          labelText: required ? 'Region *' : 'Region',
          border: const OutlineInputBorder(),
        ),
        items: regions
            .map(
              (r) => DropdownMenuItem(
                value: (r['id'] as num).toInt(),
                child: Text(r['name']?.toString() ?? ''),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _regionId = v),
        validator: required ? (v) => v == null ? 'Region is required' : null : null,
      ),
    );
  }

  Widget _teamLeaderDropdown() {
    final leaders = _listField('team_leaders');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        value: _teamLeaderId,
        decoration: const InputDecoration(
          labelText: 'Team leader',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('— None —')),
          ...leaders.map(
            (tl) => DropdownMenuItem(
              value: (tl['id'] as num).toInt(),
              child: Text(tl['name']?.toString() ?? ''),
            ),
          ),
        ],
        onChanged: (v) => setState(() => _teamLeaderId = v),
      ),
    );
  }

  Widget _regionalManagerDropdown() {
    final managers = _listField('regional_managers');
    if (managers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Text('Create at least one regional manager first.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        value: _regionalManagerId,
        decoration: const InputDecoration(
          labelText: 'Regional manager *',
          border: OutlineInputBorder(),
        ),
        items: managers
            .map(
              (rm) => DropdownMenuItem(
                value: (rm['id'] as num).toInt(),
                child: Text(
                  '${rm['name']}${rm['region_name'] != null ? ' — ${rm['region_name']}' : ''}',
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _regionalManagerId = v),
        validator: (v) => v == null ? 'Regional manager is required' : null,
      ),
    );
  }

  Widget _subadminRoleDropdown() {
    final roles = _listField('subadmin_roles');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        value: _subadminRoleId,
        decoration: const InputDecoration(
          labelText: 'Role *',
          border: OutlineInputBorder(),
        ),
        items: roles
            .map(
              (r) => DropdownMenuItem(
                value: (r['id'] as num).toInt(),
                child: Text(r['name']?.toString() ?? ''),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _subadminRoleId = v),
        validator: (v) => v == null ? 'Role is required' : null,
      ),
    );
  }
}
