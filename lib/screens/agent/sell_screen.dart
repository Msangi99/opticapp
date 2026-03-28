import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/product_list_api.dart';
import '../../api/agent_dashboard_api.dart';
import '../../api/payment_options_api.dart';
import '../../theme/app_theme.dart';
import 'agent_scaffold.dart';

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
  /// Product list IDs sold in this session so they never appear in the dropdown.
  final Set<int> _soldInSessionIds = {};
  int? _selectedProductId;
  String? _error;
  final _customerController = TextEditingController();
  final _priceController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _intervalDaysController = TextEditingController();
  final _creditNotesController = TextEditingController();
  bool _creditSale = false;
  DateTime? _firstDueDate;
  List<Map<String, dynamic>> _paymentOptions = [];
  int? _paymentOptionId;
  bool _loadingPaymentOptions = false;
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
    _downPaymentController.addListener(() => setState(() {}));
    _loadAvailableProducts();
    _loadPaymentOptions();
  }

  Future<void> _loadPaymentOptions() async {
    setState(() => _loadingPaymentOptions = true);
    try {
      final opts = await getAgentPaymentOptions();
      if (!mounted) return;
      setState(() {
        _paymentOptions = opts;
        _loadingPaymentOptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentOptions = [];
        _loadingPaymentOptions = false;
      });
    }
  }

  Future<void> _loadAvailableProducts() async {
    setState(() {
      _loadingProducts = true;
    });
    try {
      final products = await getAvailableProducts();
      if (!mounted) return;
      setState(() {
        final list = products.isNotEmpty ? products : <Map<String, dynamic>>[];
        // Exclude any items already sold in this session (safety if API returns stale data).
        _availableProducts = list
            .where((p) {
              final id = p['id'];
              if (id == null) return true;
              final int? idInt = id is int ? id : (id is num ? id.toInt() : null);
              return idInt == null || !_soldInSessionIds.contains(idInt);
            })
            .toList();
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

  Future<void> _pickFirstDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstDueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _firstDueDate = picked);
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
    final unitPrice = _unitPrice ?? 0.0;
    double down = 0;
    if (_creditSale) {
      final ds = _downPaymentController.text.trim();
      if (ds.isNotEmpty) {
        down = double.tryParse(ds) ?? 0;
      }
      if (down > unitPrice + 0.0001) {
        setState(() => _error = 'Down payment cannot exceed sell price.');
        return;
      }
      if (down > 0 && _paymentOptionId == null) {
        setState(() => _error = 'Select a payment channel for the down payment.');
        return;
      }
    }
    setState(() {
      _error = null;
      _selling = true;
    });
    try {
      if (_creditSale) {
        final ic = _installmentCountController.text.trim();
        final ia = _installmentAmountController.text.trim();
        final idays = _intervalDaysController.text.trim();
        await sellDeviceCredit(
          productListId: _device!['id'] as int,
          customerName: customer,
          sellingPrice: unitPrice,
          downPayment: down,
          paymentOptionId: _paymentOptionId,
          installmentCount: ic.isEmpty ? null : int.tryParse(ic),
          installmentAmount: ia.isEmpty ? null : double.tryParse(ia),
          installmentIntervalDays: idays.isEmpty ? null : int.tryParse(idays),
          firstDueDate: _firstDueDate != null
              ? '${_firstDueDate!.year.toString().padLeft(4, '0')}-${_firstDueDate!.month.toString().padLeft(2, '0')}-${_firstDueDate!.day.toString().padLeft(2, '0')}'
              : null,
          installmentNotes: _creditNotesController.text.trim().isEmpty
              ? null
              : _creditNotesController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Credit sale recorded.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: successColor,
          ),
        );
      } else {
        await sellDevice(
          productListId: _device!['id'] as int,
          customerName: customer,
          sellingPrice: unitPrice,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sale recorded (instant).'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: successColor,
          ),
        );
      }
      if (!mounted) return;
      final soldId = _device!['id'] as int?;
      if (soldId != null) _soldInSessionIds.add(soldId);
      setState(() {
        _availableProducts.removeWhere((product) => product['id'] == _device!['id']);
        _selectedProductId = null;
        _device = null;
        _customerController.clear();
        _priceController.clear();
        _downPaymentController.clear();
        _installmentCountController.clear();
        _installmentAmountController.clear();
        _intervalDaysController.clear();
        _creditNotesController.clear();
        _firstDueDate = null;
        _paymentOptionId = null;
      });
      await _loadAvailableProducts();
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _selling = false);
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _priceController.dispose();
    _downPaymentController.dispose();
    _installmentCountController.dispose();
    _installmentAmountController.dispose();
    _intervalDaysController.dispose();
    _creditNotesController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalAmount;
    final theme = Theme.of(context);

    return AgentScaffold(
      title: 'Record Sale',
      showDrawer: true,
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
              DropdownButtonFormField<int?>(
                value: _selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Select Product',
                  hintText: 'Choose a product',
                  prefixIcon: Icon(Icons.phone_android_rounded, size: 22),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('-- Select Product --'),
                  ),
                  ..._availableProducts.map((product) {
                    final id = product['id'] as int?;
                    final model = product['model'] as String? ?? '–';
                    final imei = product['imei_number'] as String? ?? '–';
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text('$model (IMEI: $imei)'),
                    );
                  }),
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
                  const SizedBox(height: 16),
                  Text('Sale type', style: sectionLabelStyle(context)),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Instant'),
                        icon: Icon(Icons.payments_outlined, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Credit'),
                        icon: Icon(Icons.schedule_outlined, size: 18),
                      ),
                    ],
                    selected: {_creditSale},
                    onSelectionChanged: (s) {
                      setState(() => _creditSale = s.first);
                    },
                  ),
                  if (_creditSale) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _downPaymentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Down payment (optional)',
                        prefixIcon: Icon(Icons.savings_outlined, size: 22),
                      ),
                    ),
                    if (_loadingPaymentOptions)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(),
                      )
                    else if (_paymentOptions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: _paymentOptionId,
                        decoration: const InputDecoration(
                          labelText: 'Payment channel (for down payment)',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 22),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._paymentOptions.map((o) {
                            final id = o['id'] as int?;
                            final name = o['name']?.toString() ?? '';
                            final bal = o['balance'];
                            return DropdownMenuItem<int?>(
                              value: id,
                              child: Text('$name (${bal ?? '—'})'),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _paymentOptionId = v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _installmentCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number of installments (optional)',
                        prefixIcon: Icon(Icons.numbers_rounded, size: 22),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _installmentAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Installment amount (optional)',
                        prefixIcon: Icon(Icons.repeat_rounded, size: 22),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _intervalDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Payment interval (days, optional)',
                        hintText: 'e.g. 7 or 30',
                        prefixIcon: Icon(Icons.date_range_outlined, size: 22),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('First due date (optional)'),
                      subtitle: Text(
                        _firstDueDate == null
                            ? 'Not set'
                            : '${_firstDueDate!.year}-${_firstDueDate!.month.toString().padLeft(2, '0')}-${_firstDueDate!.day.toString().padLeft(2, '0')}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        onPressed: _pickFirstDueDate,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _creditNotesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Credit notes (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
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
