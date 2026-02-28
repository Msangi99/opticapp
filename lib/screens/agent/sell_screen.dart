import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/client.dart';
import '../../api/product_list_api.dart';
import '../../api/agent_dashboard_api.dart';
import '../../theme/app_theme.dart';

/// Approximate height of 1 cm in logical pixels (device-independent).
const double _scannerStripHeight = 40.0;

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  Map<String, dynamic>? _device;
  List<Map<String, dynamic>> _availableProducts = [];
  int? _selectedProductId;
  String? _error;
  final _customerController = TextEditingController();
  final _priceController = TextEditingController();
  bool _selling = false;
  bool _loadingProducts = false;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  DateTime? _lastScanTime;
  static const _scanCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() => setState(() {}));
    _loadAvailableProducts();
  }

  Future<void> _loadAvailableProducts() async {
    setState(() {
      _loadingProducts = true;
    });
    try {
      final products = await getAvailableProducts();
      if (!mounted) return;
      setState(() {
        _availableProducts = products.isNotEmpty ? products : <Map<String, dynamic>>[];
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableProducts = <Map<String, dynamic>>[];
        _loadingProducts = false;
        // Don't show error, just continue without dropdown
      });
    }
  }

  void _onProductSelected(int? productId) {
    if (productId == null) {
      setState(() {
        _selectedProductId = null;
        _device = null;
        _priceController.clear();
      });
      return;
    }
    if (_availableProducts.isEmpty) return;
    try {
      final product = _availableProducts.firstWhere(
        (p) => p['id'] == productId,
        orElse: () => <String, dynamic>{},
      );
      if (product.isNotEmpty && product['id'] != null) {
        setState(() {
          _selectedProductId = productId;
          _device = product;
          _error = null;
          final sellPrice = product['sell_price'];
          if (sellPrice != null) {
            final n = sellPrice is num ? sellPrice : (double.tryParse(sellPrice.toString()) ?? 0.0);
            _priceController.text = n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
          } else {
            _priceController.text = '';
          }
        });
      } else {
        // Product no longer available, reset selection
        setState(() {
          _selectedProductId = null;
          _error = 'Selected product is no longer available.';
        });
      }
    } catch (e) {
      // Product not found, reset selection
      setState(() {
        _selectedProductId = null;
        _error = 'Selected product is no longer available.';
      });
    }
  }

  /// Scan barcode → use the scanned code as IMEI number (look up device).
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
        _lookupImei(code.trim());
        return;
      }
    }
  }

  Future<void> _lookupImei(String imei) async {
    setState(() {
      _device = null;
      _selectedProductId = null;
      _error = null;
    });
    try {
      final device = await getDeviceByImei(imei);
      if (!mounted) return;
      setState(() {
        _device = device;
        _error = null;
        // Pre-fill sell price from stock (purchase.sell_price); fallback to purchase_price
        final sellPrice = device['sell_price'];
        final price = sellPrice ?? device['purchase_price'];
        if (price != null) {
          final n = price is num ? price : (double.tryParse(price.toString()) ?? 0.0);
          _priceController.text = n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
        } else {
          _priceController.text = '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _device = null;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double? get _unitPrice {
    final s = _priceController.text.trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// Quantity is fixed at 1 for agent sales.
  static const int _quantity = 1;

  double? get _totalAmount {
    final price = _unitPrice;
    if (price == null || price < 0) return null;
    return price * _quantity;
  }

  Future<void> _sell() async {
    if (_device == null) return;
    final customer = _customerController.text.trim();
    if (customer.isEmpty) {
      setState(() => _error = 'Enter customer name.');
      return;
    }
    final total = _totalAmount;
    if (total == null || total < 0) {
      setState(() => _error = 'Enter a valid selling price.');
      return;
    }
    setState(() {
      _error = null;
      _selling = true;
    });
    try {
      // API expects selling_price per unit; quantity is always 1.
      final unitPrice = _unitPrice ?? 0.0;
      await sellDevice(
        productListId: _device!['id'] as int,
        customerName: customer,
        sellingPrice: unitPrice,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sale recorded.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: successColor,
        ),
      );
      // Remove the sold product from the available products list and refresh the list
      setState(() {
        _availableProducts.removeWhere((product) => product['id'] == _device!['id']);
        _selectedProductId = null;
        _device = null;
        _customerController.clear();
        _priceController.clear();
      });
      
      // Refresh the available products list from the backend
      await _loadAvailableProducts();
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _selling = false);
    }
  }

  Future<void> _logout() async {
    await clearStoredAuth();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _customerController.dispose();
    _priceController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalAmount;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sell'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Log out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Product or Scan IMEI',
              style: sectionLabelStyle(context),
            ),
            const SizedBox(height: 16),
            // Product Selection Dropdown
            if (!_loadingProducts && _availableProducts.isNotEmpty) ...[
              Text(
                'Select from available products:',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Select Product',
                  hintText: 'Choose a product',
                  prefixIcon: Icon(Icons.phone_android_rounded, size: 22),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('-- Select Product --'),
                  ),
                  ..._availableProducts.map((product) {
                    final id = product['id'] as int?;
                    final model = product['model'] as String? ?? '–';
                    final imei = product['imei_number'] as String? ?? '–';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text('$model (IMEI: $imei)'),
                    );
                  }).toList(),
                ],
                onChanged: _onProductSelected,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Scan barcode (code = IMEI)',
              style: sectionLabelStyle(context),
            ),
            const SizedBox(height: 4),
            Text(
              'Point camera at barcode. The scanned code is used as the IMEI to find the device.',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.hardEdge,
                child: ClipRect(
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    height: _scannerStripHeight,
                    width: double.infinity,
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: _onScanResult,
                      errorBuilder: (context, error, child) {
                        return Container(
                          height: _scannerStripHeight,
                          width: double.infinity,
                          color: Colors.red.shade50,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Center(
                            child: Text(
                              'Camera error',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!, style: errorStyle()),
              ),
              const SizedBox(height: 20),
            ],
            if (_device != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: sectionCardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.smartphone_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _device!['model'] as String? ?? '—',
                                style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'IMEI: ${_device!['imei_number']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (_device!['stock_name'] != null)
                                Text(
                                  'Stock: ${_device!['stock_name']}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              if (_device!['category_name'] != null)
                                Text(
                                  'Category: ${_device!['category_name']}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: sectionCardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _customerController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Customer name',
                      hintText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    initialValue: '1',
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: 'Fixed at 1',
                      prefixIcon: Icon(Icons.numbers_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Sell price (per unit)',
                      hintText: 'Auto from scan, or edit',
                      prefixIcon: Icon(Icons.attach_money_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total price',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          total != null
                              ? total.toStringAsFixed(2)
                              : '—',
                          style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (_device != null && !_selling) ? _sell : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _selling
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Complete sale'),
            ),
          ],
        ),
      ),
    );
  }
}
