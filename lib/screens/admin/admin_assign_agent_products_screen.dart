import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../api/admin_agent_assignment_api.dart';
import '../../api/users_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

/// Assign unsold devices (IMEIs) from stock to an agent. Optional: capture a label photo and read the barcode.
class AdminAssignAgentProductsScreen extends StatefulWidget {
  const AdminAssignAgentProductsScreen({super.key});

  @override
  State<AdminAssignAgentProductsScreen> createState() => _AdminAssignAgentProductsScreenState();
}

class _AdminAssignAgentProductsScreenState extends State<AdminAssignAgentProductsScreen> {
  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _imeiRows = [];

  int? _agentId;
  int? _productId;
  final Set<int> _selectedListIds = {};

  bool _loadingMeta = true;
  bool _loadingImeis = false;
  bool _scanning = false;
  bool _submitting = false;
  String? _error;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _manualImeiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _manualImeiController.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _error = null;
    });
    try {
      final agents = await getAgents();
      final products = await getProductsForAssign();
      if (!mounted) return;
      setState(() {
        _agents = agents;
        _products = products;
        _loadingMeta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingMeta = false;
      });
    }
  }

  Future<void> _onProductChanged(int? id) async {
    setState(() {
      _productId = id;
      _imeiRows = [];
      _selectedListIds.clear();
      _error = null;
    });
    if (id == null) return;
    setState(() => _loadingImeis = true);
    try {
      final rows = await getAssignableImeisForAgent(id);
      if (!mounted) return;
      setState(() {
        _imeiRows = rows;
        _loadingImeis = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loadingImeis = false;
      });
    }
  }

  Future<Set<String>> _barcodesFromImagePath(String path) async {
    final found = <String>{};
    final controller = MobileScannerController(autoStart: false);
    try {
      final result = await controller.analyzeImage(path);
      if (result is BarcodeCapture) {
        for (final b in result.barcodes) {
          final c = (b.rawValue ?? b.displayValue ?? '').trim();
          if (c.isNotEmpty) found.add(c);
        }
      }
    } catch (_) {
      /* unreadable */
    } finally {
      controller.dispose();
    }
    return found;
  }

  Future<void> _tryAddValidatedImei(String raw) async {
    final pid = _productId;
    if (pid == null) {
      setState(() => _error = 'Select a catalog model first.');
      return;
    }
    final vr = await validateImeiForAssignment(productId: pid, imei: raw);
    if (!mounted) return;
    if (!vr.ok) {
      setState(() => _error = vr.message ?? 'Validation failed.');
      return;
    }
    final lid = vr.productListId;
    if (lid == null) {
      setState(() => _error = 'Unexpected validation response.');
      return;
    }
    if (_selectedListIds.contains(lid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Already selected: ${vr.imeiNumber ?? raw}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _error = null);
      return;
    }
    setState(() {
      _selectedListIds.add(lid);
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${vr.imeiNumber ?? "IMEI"}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: successColor,
      ),
    );
  }

  Future<void> _captureAndScanImei() async {
    final pid = _productId;
    if (pid == null) {
      setState(() => _error = 'Select a catalog model before scanning.');
      return;
    }
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null || !mounted) return;

    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final codes = await _barcodesFromImagePath(image.path);
      if (!mounted) return;
      if (codes.isEmpty) {
        setState(() => _error = 'No barcode found in the photo. Try better lighting, hold steady, or pick from the list.');
        return;
      }
      for (final code in codes) {
        final vr = await validateImeiForAssignment(productId: pid, imei: code);
        if (!mounted) return;
        if (vr.ok && vr.productListId != null) {
          final lid = vr.productListId!;
          final label = vr.imeiNumber ?? code;
          if (_selectedListIds.contains(lid)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Already selected: $label'), behavior: SnackBarBehavior.floating),
            );
          } else {
            setState(() => _selectedListIds.add(lid));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added $label'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: successColor,
              ),
            );
          }
          return;
        }
      }
      setState(() => _error = 'Scanned value(s) did not match any assignable IMEI for this model.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _validateManualImei() async {
    final text = _manualImeiController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Enter an IMEI or use the camera scan.');
      return;
    }
    setState(() => _error = null);
    await _tryAddValidatedImei(text);
    if (mounted) _manualImeiController.clear();
  }

  Future<void> _submit() async {
    final aid = _agentId;
    final pid = _productId;
    if (aid == null || pid == null) {
      setState(() => _error = 'Choose an agent and a catalog model.');
      return;
    }
    if (_selectedListIds.isEmpty) {
      setState(() => _error = 'Select or add at least one device.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final count = await postAssignProductsToAgent(
        agentId: aid,
        productId: pid,
        productListIds: _selectedListIds.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assigned $count device(s).'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: successColor,
        ),
      );
      setState(() {
        _selectedListIds.clear();
        _submitting = false;
      });
      await _onProductChanged(pid);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  List<DropdownMenuItem<int>> get _agentMenuItems {
    return _agents
        .map((u) {
          final id = _parseInt(u['id']);
          if (id == null) return null;
          final name = u['name'] as String? ?? 'User #$id';
          final status = u['status'] as String? ?? 'active';
          if (status != 'active') return null;
          return DropdownMenuItem(value: id, child: Text(name, overflow: TextOverflow.ellipsis));
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();
  }

  List<DropdownMenuItem<int>> get _productMenuItems {
    return _products
        .map((p) {
          final id = _parseInt(p['id']);
          if (id == null) return null;
          final name = p['name'] as String? ?? '#$id';
          return DropdownMenuItem(value: id, child: Text(name, overflow: TextOverflow.ellipsis));
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();
  }

  Widget _intro(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ASSIGNMENT', style: sectionLabelStyle(context)),
          const SizedBox(height: 6),
          Text(
            'Pick an active agent and catalog model, then choose IMEIs from stock or scan a device label.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(_error!, style: errorStyle()),
      ),
    );
  }

  Widget _cardShell({required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _agentAndProductCard(BuildContext context) {
    final agentItems = _agentMenuItems;
    final productItems = _productMenuItems;

    return _cardShell(
      title: 'Agent & model',
      subtitle: 'Only unsold devices in stock for the chosen model appear below.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (agentItems.isEmpty)
            _emptyInlineHint(context, Icons.person_off_outlined, 'No active agents. Activate an agent account first.')
          else
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: _agentId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Agent',
                prefixIcon: Icon(Icons.person_search_rounded),
              ),
              items: agentItems,
              onChanged: (v) => setState(() => _agentId = v),
            ),
          const SizedBox(height: 14),
          if (productItems.isEmpty)
            _emptyInlineHint(context, Icons.inventory_2_outlined, 'No catalog models available for assignment.')
          else
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: _productId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Catalog model',
                prefixIcon: Icon(Icons.smartphone_rounded),
              ),
              items: productItems,
              onChanged: _onProductChanged,
            ),
        ],
      ),
    );
  }

  Widget _emptyInlineHint(BuildContext context, IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.85)),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _addDevicesCard(BuildContext context) {
    final disabled = _productId == null;
    return _cardShell(
      title: 'Add devices to selection',
      subtitle: 'Scan a barcode from a label photo, or type an IMEI and validate.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: (_scanning || disabled) ? null : _captureAndScanImei,
            icon: _scanning
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.photo_camera_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(_scanning ? 'Reading barcode…' : 'Capture label & read barcode'),
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _manualImeiController,
                  enabled: !disabled,
                  decoration: const InputDecoration(
                    labelText: 'IMEI',
                    hintText: 'Type or paste',
                    prefixIcon: Icon(Icons.dialpad_rounded),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => disabled ? null : _validateManualImei(),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton.tonal(
                  onPressed: disabled ? null : _validateManualImei,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imeiListCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = _imeiRows.length;
    final nSel = _selectedListIds.length;

    Widget body;
    if (_productId == null) {
      body = _emptyState(
        context,
        icon: Icons.touch_app_outlined,
        title: 'Choose a catalog model',
        subtitle: 'Select a model above to load assignable IMEIs from stock.',
      );
    } else if (_loadingImeis) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_imeiRows.isEmpty) {
      body = _emptyState(
        context,
        icon: Icons.check_circle_outline,
        title: 'No devices in stock',
        subtitle: 'Nothing assignable for this model right now, or all units are already assigned.',
      );
    } else {
      body = Column(
        children: _imeiRows.map((row) {
          final lid = _parseInt(row['id']);
          if (lid == null) return const SizedBox.shrink();
          final label = row['text'] as String? ?? row['imei_number']?.toString() ?? '#$lid';
          final selected = _selectedListIds.contains(lid);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedListIds.remove(lid);
                    } else {
                      _selectedListIds.add(lid);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? cs.primary.withValues(alpha: 0.55) : cs.outline.withValues(alpha: 0.28),
                      width: selected ? 1.5 : 1,
                    ),
                    color: selected ? cs.primaryContainer.withValues(alpha: 0.42) : cs.surface,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: selected,
                        onChanged: (c) {
                          setState(() {
                            if (c == true) {
                              _selectedListIds.add(lid);
                            } else {
                              _selectedListIds.remove(lid);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
                      Icon(Icons.sim_card_outlined, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return _cardShell(
      title: 'Stock — assignable IMEIs',
      subtitle: total > 0 ? '$total in list · $nSel selected' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (total > 0 && nSel > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedListIds.clear()),
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear selection'),
              ),
            ),
          if (total > 0 && nSel > 0) const SizedBox(height: 4),
          body,
        ],
      ),
    );
  }

  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _submitArea(BuildContext context) {
    final n = _selectedListIds.length;
    final label = n == 0 ? 'Assign to agent' : 'Assign $n device${n == 1 ? '' : 's'} to agent';
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Assign devices to agent',
      body: _loadingMeta
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading…', style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMeta,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _intro(context),
                    if (_error != null) _errorBanner(context),
                    const SizedBox(height: 16),
                    _agentAndProductCard(context),
                    const SizedBox(height: 14),
                    _addDevicesCard(context),
                    const SizedBox(height: 14),
                    _imeiListCard(context),
                    const SizedBox(height: 20),
                    _submitArea(context),
                  ],
                ),
              ),
            ),
    );
  }
}
