import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/client.dart';
import '../../api/product_list_api.dart';
import '../../theme/app_theme.dart';

/// Scanner strip height ~1 cm, full width.
const double _scannerStripHeight = 40.0;

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
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  DateTime? _lastScanTime;
  static const _scanCooldown = Duration(seconds: 2);

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

  /// Scan barcode → use the scanned code as IMEI number (fill IMEI field).
  void _onScanResult(BarcodeCapture capture) {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!) < _scanCooldown) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue ?? barcode.displayValue;
      if (code != null && code.trim().isNotEmpty) {
        _lastScanTime = now;
        final imei = code.trim();
        setState(() {
          _imeiController.text = imei;
          _error = null;
        });
        return;
      }
    }
  }

  Future<void> _save() async {
    if (_selectedPurchaseId == null) {
      setState(() => _error = 'Select a purchase.');
      return;
    }
    final imei = _imeiController.text.trim();
    if (imei.isEmpty) {
      setState(() => _error = 'Enter or scan IMEI.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await addProductToListByPurchase(
        purchaseId: _selectedPurchaseId!,
        imeiNumber: imei,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product added.'),
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

  Future<void> _logout() async {
    await clearStoredAuth();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _imeiController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin/stocks'),
          tooltip: 'Back to Stocks',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Log out',
          ),
        ],
      ),
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
                      'Scan barcode (code = IMEI)',
                      style: sectionLabelStyle(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Point camera at barcode. The scanned code is used as the IMEI number.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: _scannerStripHeight,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: _onScanResult,
                        ),
                      ),
                    ),
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
                          Text('IMEI', style: sectionLabelStyle(context)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _imeiController,
                            decoration: const InputDecoration(
                              hintText: 'From scan above or type manually',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
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
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
