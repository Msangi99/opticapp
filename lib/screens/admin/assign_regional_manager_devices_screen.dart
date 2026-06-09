import 'package:flutter/material.dart';

import '../../api/users_api.dart';
import 'admin_scaffold.dart';
import 'widgets/admin_users_ui.dart';

class AssignRegionalManagerDevicesScreen extends StatefulWidget {
  const AssignRegionalManagerDevicesScreen({super.key, this.initialRegionalManagerId});

  final int? initialRegionalManagerId;

  @override
  State<AssignRegionalManagerDevicesScreen> createState() => _AssignRegionalManagerDevicesScreenState();
}

class _AssignRegionalManagerDevicesScreenState extends State<AssignRegionalManagerDevicesScreen> {
  Map<String, dynamic>? _formData;
  List<Map<String, dynamic>> _models = [];
  List<Map<String, dynamic>> _imeis = [];
  Map<String, dynamic>? _imeiSummary;

  bool _loading = true;
  bool _loadingModels = false;
  bool _loadingImeis = false;
  bool _saving = false;

  int? _regionalManagerId;
  int? _purchaseId;
  int? _productId;
  final Set<int> _selectedImeiIds = {};

  @override
  void initState() {
    super.initState();
    _regionalManagerId = widget.initialRegionalManagerId;
    _loadForm();
  }

  Future<void> _loadForm() async {
    try {
      final data = await getAssignDevicesFormData();
      if (!mounted) return;
      setState(() {
        _formData = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _loadModels() async {
    if (_purchaseId == null) return;
    setState(() {
      _loadingModels = true;
      _models = [];
      _productId = null;
      _imeis = [];
      _selectedImeiIds.clear();
    });
    try {
      final models = await getAssignDevicesModels(_purchaseId!);
      if (!mounted) return;
      setState(() {
        _models = models;
        _loadingModels = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingModels = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _loadImeis() async {
    if (_purchaseId == null || _productId == null) return;
    setState(() {
      _loadingImeis = true;
      _imeis = [];
      _selectedImeiIds.clear();
    });
    try {
      final res = await getAssignDevicesImeis(purchaseId: _purchaseId!, productId: _productId!);
      if (!mounted) return;
      setState(() {
        _imeis = (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _imeiSummary = res['summary'] as Map<String, dynamic>?;
        _loadingImeis = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingImeis = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _submit() async {
    if (_regionalManagerId == null || _purchaseId == null || _productId == null || _selectedImeiIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select regional manager, purchase, model, and at least one IMEI')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await storeAssignDevices(
        regionalManagerId: _regionalManagerId!,
        purchaseId: _purchaseId!,
        productId: _productId!,
        productListIds: _selectedImeiIds.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  List<Map<String, dynamic>> _managers() {
    final raw = _formData?['regional_managers'];
    if (raw is! List) return [];
    return raw.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _purchases() {
    final raw = _formData?['purchases'];
    if (raw is! List) return [];
    return raw.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Assign devices',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AdminUsersPageHeader(
                  eyebrow: 'Staff',
                  title: 'Assign devices',
                  subtitle: 'Assign stock IMEIs from a purchase to a regional manager.',
                ),
                const SizedBox(height: 16),
                _stepCard(
                  step: 1,
                  title: 'Regional manager',
                  child: DropdownButtonFormField<int>(
                    value: _regionalManagerId,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _managers()
                        .map(
                          (m) => DropdownMenuItem(
                            value: (m['id'] as num).toInt(),
                            child: Text(
                              '${m['name']} (${m['email']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _regionalManagerId = v),
                  ),
                ),
                _stepCard(
                  step: 2,
                  title: 'Purchase',
                  child: DropdownButtonFormField<int>(
                    value: _purchaseId,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _purchases()
                        .map(
                          (p) => DropdownMenuItem(
                            value: (p['id'] as num).toInt(),
                            child: Text(
                              p['label']?.toString() ?? 'Purchase',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => _purchaseId = v);
                      _loadModels();
                    },
                  ),
                ),
                _stepCard(
                  step: 3,
                  title: 'Model',
                  child: _loadingModels
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<int>(
                          value: _productId,
                          isExpanded: true,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: _models
                              .map(
                                (m) => DropdownMenuItem(
                                  value: (m['product_id'] as num).toInt(),
                                  child: Text(
                                    '${m['label']} (${m['available_imeis']} available)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => _productId = v);
                            _loadImeis();
                          },
                        ),
                ),
                _stepCard(
                  step: 4,
                  title: 'IMEIs',
                  child: _loadingImeis
                      ? const LinearProgressIndicator()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_imeiSummary != null)
                              Text(
                                'Available: ${_imeiSummary!['available']} / ${_imeiSummary!['total']}',
                                style: TextStyle(color: kAdminTextMuted, fontSize: 13),
                              ),
                            const SizedBox(height: 8),
                            ..._imeis.map((imei) {
                              final id = (imei['id'] as num).toInt();
                              final selectable = imei['selectable'] == true;
                              return CheckboxListTile(
                                value: _selectedImeiIds.contains(id),
                                onChanged: selectable
                                    ? (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedImeiIds.add(id);
                                          } else {
                                            _selectedImeiIds.remove(id);
                                          }
                                        });
                                      }
                                    : null,
                                title: Text(imei['text']?.toString() ?? imei['imei_number']?.toString() ?? ''),
                                subtitle: Text(imei['status_label']?.toString() ?? ''),
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            }),
                            if (_imeis.isEmpty && !_loadingImeis)
                              const Text('No IMEIs on this purchase for the selected model.'),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: kAdminBrandDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Assign ${_selectedImeiIds.length} device(s)'),
                ),
              ],
            ),
    );
  }

  Widget _stepCard({required int step, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: kAdminBrandOrange,
                child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: kAdminBrandDark)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
