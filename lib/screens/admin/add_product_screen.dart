import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/product_list_api.dart';
import '../../theme/app_theme.dart';
import '../shared/scanner_dialog.dart';
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

  // Separate controller used solely for analyzeImage (gallery photos).
  // autoStart: false – camera never opens; it just provides the ML-Kit pipeline.
  late final MobileScannerController _imageDecodeController;

  @override
  void initState() {
    super.initState();
    _imageDecodeController = MobileScannerController(autoStart: false);
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

  void _addCodeToField(String code) {
    final existing = _imeisFromField();
    existing.add(code);
    _syncFieldFromSet(existing);
  }

  // ── Camera: live scanner dialog (reliable for Code128 / IMEI labels) ─────
  Future<void> _scanWithCamera() async {
    final code = await showBarcodeScannerDialog(context);
    if (!mounted || code == null) return;
    setState(() {
      _addCodeToField(code);
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added: $code'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: successColor,
        duration: const Duration(seconds: 2),
      ),
    );
    // Keep scanning – ask if user wants to scan another
    if (!mounted) return;
    final again = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan another?'),
        content: Text('Added "$code". Scan another barcode?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Done')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Scan more')),
        ],
      ),
    );
    if (again == true && mounted) {
      await _scanWithCamera();
    }
  }

  // ── Gallery: try analyzeImage via ML Kit (works for QR; 1D may vary) ─────
  Future<Set<String>> _barcodesFromFilePath(String path) async {
    final found = <String>{};
    try {
      final result = await _imageDecodeController.analyzeImage(path);
      if (result is BarcodeCapture) {
        for (final b in result.barcodes) {
          final c = (b.rawValue ?? b.displayValue ?? '').trim();
          if (c.isNotEmpty) found.add(c);
        }
      } else if (result != null) {
        // mobile_scanner may return BarcodeCapture directly depending on version
        final capture = result as BarcodeCapture?;
        for (final b in capture?.barcodes ?? []) {
          final c = (b.rawValue ?? b.displayValue ?? '').trim();
          if (c.isNotEmpty) found.add(c);
        }
      }
    } catch (_) {
      /* no code readable in this image */
    }
    return found;
  }

  Future<void> _pickFromGallery() async {
    final list = await _picker.pickMultiImage(imageQuality: 88);
    if (list.isEmpty) return;
    setState(() {
      _decoding = true;
      _error = null;
    });
    final merged = _imeisFromField();
    try {
      for (final f in list) {
        merged.addAll(await _barcodesFromFilePath(f.path));
      }
      if (!mounted) return;
      setState(() {
        _syncFieldFromSet(merged);
        _decoding = false;
        if (merged.isEmpty) {
          _error =
              'No barcode found in the selected photo(s). '
              'For IMEI labels (Code 128), use the Camera button to scan live — '
              'it works reliably for all barcode types.';
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

  Future<void> _save() async {
    if (_selectedPurchaseId == null) {
      setState(() => _error = 'Select a purchase.');
      return;
    }
    final imeis = _imeisFromField().toList();
    if (imeis.isEmpty) {
      setState(() => _error = 'Add at least one IMEI.');
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
      if (failed.isNotEmpty) msg.write(' ${failed.length} skipped.');
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
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _imageDecodeController.dispose();
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
                    // ── Scan / import section ──────────────────────────────
                    Text('Add barcodes', style: sectionLabelStyle(context)),
                    const SizedBox(height: 4),
                    Text(
                      'Use Camera to scan live (recommended for IMEI labels). '
                      'Gallery reads QR codes from saved photos.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _decoding ? null : _scanWithCamera,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Camera (scan live)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _decoding ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery (QR)'),
                          ),
                        ),
                      ],
                    ),
                    if (_decoding) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 4),
                      Text(
                        'Reading barcodes from photos…',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Error banner ───────────────────────────────────────
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!, style: errorStyle()),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Form card ──────────────────────────────────────────
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
                                      child: Text(
                                        p['name'] as String? ??
                                            'Purchase #${p['id']}',
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedPurchaseId = v),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Category', style: sectionLabelStyle(context)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              _selectedPurchase != null
                                  ? (_selectedPurchase!['category_name']
                                          as String? ??
                                      '–')
                                  : '–',
                              style:
                                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Model', style: sectionLabelStyle(context)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              _selectedPurchase != null
                                  ? (_selectedPurchase!['model'] as String? ??
                                      '–')
                                  : '–',
                              style:
                                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('IMEI list (one per line)',
                              style: sectionLabelStyle(context)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _imeiController,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              hintText: 'Scanned codes appear here, or type / paste',
                              border: OutlineInputBorder(),
                              isDense: true,
                              alignLabelWithHint: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
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
