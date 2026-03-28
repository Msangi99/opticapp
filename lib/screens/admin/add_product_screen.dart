import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/product_list_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  List<Map<String, dynamic>> _purchases = [];
  bool _loading = true;
  String? _error;
  int? _selectedPurchaseId;
  final _imeiController = TextEditingController();
  bool _saving = false;
  bool _decoding = false;
  final ImagePicker _picker = ImagePicker();
  late final MobileScannerController _decodeController;

  @override
  void initState() {
    super.initState();
    _decodeController = MobileScannerController(autoStart: false);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final purchases = await getPurchasesForAddProduct();
      if (!mounted) return;
      setState(() {
        _purchases = purchases;
        _loading = false;
        if (_purchases.isNotEmpty && _selectedPurchaseId == null) {
          _selectedPurchaseId = _purchases.first['id'] as int?;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? get _selectedPurchase {
    if (_selectedPurchaseId == null) return null;
    for (final p in _purchases) {
      if (p['id'] == _selectedPurchaseId) return p;
    }
    return null;
  }

  Set<String> _imeisFromField() {
    final lines = _imeiController.text.split(RegExp(r'[\r\n,;\t]+'));
    final out = <String>{};
    for (final line in lines) {
      final t = line.trim();
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }

  void _syncFieldFromSet(Set<String> codes) {
    final sorted = codes.toList()..sort();
    _imeiController.text = sorted.join('\n');
  }

  Future<Set<String>> _barcodesFromFilePath(String path) async {
    final found = <String>{};
    try {
      final dynamic raw = await _decodeController.analyzeImage(path);
      if (raw is BarcodeCapture) {
        for (final b in raw.barcodes) {
          final c = b.rawValue ?? b.displayValue;
          if (c != null && c.trim().isNotEmpty) found.add(c.trim());
        }
      }
    } catch (_) {
      /* no code in image */
    }
    return found;
  }

  Future<void> _decodePaths(List<String> paths) async {
    if (paths.isEmpty) return;
    setState(() {
      _decoding = true;
      _error = null;
    });
    final merged = _imeisFromField();
    try {
      for (final p in paths) {
        merged.addAll(await _barcodesFromFilePath(p));
      }
      if (!mounted) return;
      setState(() {
        _syncFieldFromSet(merged);
        _decoding = false;
        if (merged.isEmpty) {
          _error = 'No barcode found in the selected photo(s). Try another angle or type IMEIs manually.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _decoding = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 88);
    if (x == null) return;
    await _decodePaths([x.path]);
  }

  Future<void> _pickFromGallery() async {
    final list = await _picker.pickMultiImage(imageQuality: 88);
    if (list.isEmpty) return;
    await _decodePaths(list.map((e) => e.path).toList());
  }

  Future<void> _save() async {
    if (_selectedPurchaseId == null) {
      setState(() => _error = 'Select a purchase.');
      return;
    }
    final imeis = _imeisFromField().toList();
    if (imeis.isEmpty) {
      setState(() => _error = 'Add at least one IMEI from photos or typing.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final result = await addProductBatchByPurchase(
        purchaseId: _selectedPurchaseId!,
        imeiNumbers: imeis,
      );
      if (!mounted) return;
      final data = result['data'] as Map<String, dynamic>?;
      final created = (data?['created'] as List?) ?? [];
      final failed = (data?['failed'] as List?) ?? [];
      final msg = StringBuffer('Added ${created.length} product(s).');
      if (failed.isNotEmpty) {
        msg.write(' ${failed.length} skipped.');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: successColor,
        ),
      );
      _imeiController.clear();
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _decodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Add Product',
      body: _loading
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
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Barcode from camera or gallery',
                      style: sectionLabelStyle(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Take a photo or choose one or more pictures of labels. All detected codes are added as IMEIs. You can edit the list below before saving.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _decoding ? null : _pickFromCamera,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _decoding ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    if (_decoding) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 4),
                      Text(
                        'Reading barcodes…',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!, style: errorStyle()),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: sectionCardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Purchase name', style: sectionLabelStyle(context)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedPurchaseId,
                            items: _purchases
                                .map((p) => DropdownMenuItem<int>(
                                      value: p['id'] as int,
                                      child: Text(p['name'] as String? ?? 'Purchase #${p['id']}'),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedPurchaseId = v),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Category', style: sectionLabelStyle(context)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              _selectedPurchase != null
                                  ? (_selectedPurchase!['category_name'] as String? ?? '–')
                                  : '–',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Model', style: sectionLabelStyle(context)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              _selectedPurchase != null
                                  ? (_selectedPurchase!['model'] as String? ?? '–')
                                  : '–',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('IMEI list (one per line)', style: sectionLabelStyle(context)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _imeiController,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              hintText: 'From photos above or type / paste',
                              border: OutlineInputBorder(),
                              isDense: true,
                              alignLabelWithHint: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: (_saving || _decoding) ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save all'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
