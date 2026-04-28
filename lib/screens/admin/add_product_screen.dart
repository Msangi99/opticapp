import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/product_list_api.dart';
import 'admin_scaffold.dart';
import '../../theme/app_theme.dart';
import 'widgets/admin_page_ui.dart';

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

  // ── Camera: capture image first, then scan ─────
  Future<void> _captureAndScan() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null || !mounted) return;
    
    setState(() {
      _decoding = true;
      _error = null;
    });
    
    try {
      final barcodes = await _barcodesFromFilePath(image.path);
      if (!mounted) return;
      
      if (barcodes.isEmpty) {
        setState(() {
          _decoding = false;
          _error = 'No barcode detected in the captured image. '
              'Make sure the barcode is clear and visible. Try again.';
        });
        return;
      }
      
      final merged = _imeisFromField();
      merged.addAll(barcodes);
      
      setState(() {
        _syncFieldFromSet(merged);
        _decoding = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${barcodes.length} barcode(s)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _decoding = false;
        _error = 'Error scanning image: ${e.toString()}';
      });
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
              'Make sure the photo is clear and the barcode is visible. '
              'Try using the Capture & scan button for better results.';
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
      setState(() => _error = 'Select a purchase first.');
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
      
      if (created.isNotEmpty) {
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
      } else if (failed.isNotEmpty) {
        setState(() {
          _error = _buildDetailedFailureMessage(failed);
        });
      } else {
        setState(() => _error = 'No devices added. Please verify the IMEIs and try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _buildDetailedFailureMessage(List<dynamic> failed) {
    if (failed.isEmpty) return 'No devices added.';
    
    int duplicates = 0;
    int limitExhausted = 0;
    
    for (final item in failed) {
      final msg = item['message']?.toString() ?? '';
      if (msg.contains('already')) duplicates++;
      if (msg.contains('limit')) limitExhausted++;
    }
    
    final messages = ['No devices added:'];
    
    if (duplicates > 0) {
      messages.add('• $duplicates IMEI(s) already exist in the system');
    }
    if (limitExhausted > 0) {
      messages.add('• $limitExhausted IMEI(s): Purchase limit exhausted');
    }
    
    return messages.join('\n');
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
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Scan / import section ──────────────────────────────
                    AdminSectionCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add barcodes', style: sectionLabelStyle(context)),
                          const SizedBox(height: 4),
                          Text(
                            'Capture a photo of the barcode, then scan. Gallery reads saved photos.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _decoding ? null : _captureAndScan,
                                  icon: const Icon(Icons.camera_alt_rounded),
                                  label: const Text('Capture & scan'),
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
                              'Reading barcodes from photos…',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Error banner ───────────────────────────────────────
                    if (_error != null) ...[
                      AdminPageError(message: _error!),
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
