import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../api/agent_catalog_api.dart';
import '../../api/agent_dashboard_api.dart';
import '../../api/product_list_api.dart';
import '../../theme/app_theme.dart';
import 'agent_scaffold.dart';

/// Approximate height of 1 cm in logical pixels (device-independent).
const double _scannerStripHeight = 40.0;

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> with SingleTickerProviderStateMixin {
  static int? _parseIntId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Map<String, dynamic>? _device;
  List<Map<String, dynamic>> _availableProducts = [];
  final Set<int> _soldInSessionIds = {};
  int? _selectedProductId;
  String? _error;
  final _customerController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _selling = false;
  bool _loadingProducts = false;
  late TabController _tabController;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  DateTime? _lastScanTime;
  static const _scanCooldown = Duration(seconds: 2);

  // Lead tab (customer need)
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _needProducts = [];
  int? _needCategoryId;
  int? _needProductId;
  bool _loadingCatalog = false;
  bool _submittingNeed = false;
  final _leadCustomerNameController = TextEditingController();
  final _leadCustomerPhoneController = TextEditingController();
  List<Map<String, dynamic>> _branches = [];
  int? _leadBranchId;
  bool _loadingBranches = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _priceController.addListener(() => setState(() {}));
    _loadAvailableProducts();
    _loadCategoriesForNeed();
    _loadBranchesForLead();
  }

  Future<void> _loadBranchesForLead() async {
    setState(() => _loadingBranches = true);
    try {
      final list = await getAgentBranches();
      if (!mounted) return;
      setState(() {
        _branches = list;
        _loadingBranches = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _branches = [];
        _loadingBranches = false;
      });
    }
  }

  Future<void> _loadCategoriesForNeed() async {
    setState(() => _loadingCatalog = true);
    try {
      final list = await getAgentCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = [];
        _loadingCatalog = false;
      });
    }
  }

  Future<void> _onNeedCategoryChanged(int? id) async {
    setState(() {
      _needCategoryId = id;
      _needProductId = null;
      _needProducts = [];
    });
    if (id == null) return;
    try {
      final list = await getAgentProductsInCategory(id);
      if (!mounted) return;
      setState(() => _needProducts = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _needProducts = []);
    }
  }

  Future<void> _submitNeed() async {
    final cid = _needCategoryId;
    final pid = _needProductId;
    if (cid == null || pid == null) {
      setState(() => _error = 'Select category and model.');
      return;
    }
    final name = _leadCustomerNameController.text.trim();
    final phone = _leadCustomerPhoneController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter customer name.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = 'Enter customer phone.');
      return;
    }
    if (_branches.isNotEmpty && _leadBranchId == null) {
      setState(() => _error = 'Select a branch.');
      return;
    }
    setState(() {
      _error = null;
      _submittingNeed = true;
    });
    try {
      await submitAgentCustomerNeed(
        categoryId: cid,
        productId: pid,
        customerName: name,
        customerPhone: phone,
        branchId: _leadBranchId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lead submitted.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: successColor,
        ),
      );
      setState(() {
        _needProductId = null;
        _leadBranchId = null;
        _leadCustomerNameController.clear();
        _leadCustomerPhoneController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submittingNeed = false);
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
        setState(() {
          _selectedProductId = null;
          _error = 'Selected product is no longer available.';
        });
      }
    } catch (e) {
      setState(() {
        _selectedProductId = null;
        _error = 'Selected product is no longer available.';
      });
    }
  }

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

  static const int _quantity = 1;

  double? get _totalAmount {
    final price = _unitPrice;
    if (price == null || price < 0) return null;
    return price * _quantity;
  }

  Future<void> _sell({required bool credit}) async {
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
    final pid = _device!['id'];
    final productListId = pid is int ? pid : (pid is num ? pid.toInt() : int.tryParse(pid.toString()));
    if (productListId == null) {
      setState(() => _error = 'Invalid product.');
      return;
    }
    setState(() {
      _error = null;
      _selling = true;
    });
    try {
      if (credit) {
        await sellDeviceCredit(
          productListId: productListId,
          customerName: customer,
          sellingPrice: unitPrice,
          customerPhone: _customerPhoneController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Watu sale recorded.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: successColor,
          ),
        );
      } else {
        await sellDevice(
          productListId: productListId,
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
      _soldInSessionIds.add(productListId);
      setState(() {
        _availableProducts.removeWhere((product) => product['id'] == _device!['id']);
        _selectedProductId = null;
        _device = null;
        _customerController.clear();
        _customerPhoneController.clear();
        _descriptionController.clear();
        _priceController.clear();
      });
      await _loadAvailableProducts();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _selling = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerController.dispose();
    _customerPhoneController.dispose();
    _leadCustomerNameController.dispose();
    _leadCustomerPhoneController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalAmount;
    final theme = Theme.of(context);
    final tabViewHeight = (MediaQuery.sizeOf(context).height * 0.42).clamp(280.0, 520.0);

    return AgentScaffold(
      title: 'Record Sale',
      showDrawer: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select product or scan IMEI',
                    style: sectionLabelStyle(context),
                  ),
                  const SizedBox(height: 16),
                  if (!_loadingProducts && _availableProducts.isEmpty) ...[
                    Text(
                      'No devices assigned to you yet. Ask an admin to assign IMEIs from Assign products to agent.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                        labelText: 'Select product',
                        hintText: 'Choose a product',
                        prefixIcon: Icon(Icons.phone_android_rounded, size: 22),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('-- Select product --'),
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
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        const Expanded(child: Divider()),
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
                      child: Row(
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
                    ),
                    const SizedBox(height: 16),
                  ],
                  Material(
                    color: theme.colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      tabs: const [
                        Tab(text: 'Sell'),
                        Tab(text: 'Watu'),
                        Tab(text: 'Lead'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: tabViewHeight,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          child: _buildSaleForm(
                            context: context,
                            theme: theme,
                            total: total,
                            credit: false,
                          ),
                        ),
                        SingleChildScrollView(
                          child: _buildSaleForm(
                            context: context,
                            theme: theme,
                            total: total,
                            credit: true,
                          ),
                        ),
                        SingleChildScrollView(
                          child: _buildNeededForm(context, theme),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleForm({
    required BuildContext context,
    required ThemeData theme,
    required double? total,
    required bool credit,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_device == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                credit
                    ? 'Select or scan a device above to use Watu.'
                    : 'Select or scan a device above to complete a sale.',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
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
          if (credit) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Customer phone',
                hintText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined, size: 22),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Notes about this Watu sale',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined, size: 22),
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
                  total != null ? total.toStringAsFixed(2) : '—',
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_device != null && !_selling) ? () => _sell(credit: credit) : null,
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
                : Text(credit ? 'Complete Watu sale' : 'Complete sale'),
          ),
        ],
      ),
    );
  }

  Widget _buildNeededForm(BuildContext context, ThemeData theme) {
    final leadReady = _needCategoryId != null &&
        _needProductId != null &&
        _leadCustomerNameController.text.trim().isNotEmpty &&
        _leadCustomerPhoneController.text.trim().isNotEmpty &&
        (_branches.isEmpty || _leadBranchId != null);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Submit a lead: who is asking, which branch they prefer, and what product they want.',
            style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _leadCustomerNameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Customer name',
              hintText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 22),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _leadCustomerPhoneController,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Customer phone',
              hintText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined, size: 22),
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingBranches)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_branches.isNotEmpty)
            DropdownButtonFormField<int?>(
              value: _leadBranchId,
              decoration: const InputDecoration(
                labelText: 'Branch',
                hintText: 'Where they shop / pick up',
                prefixIcon: Icon(Icons.store_mall_directory_outlined, size: 22),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('-- Select branch --'),
                ),
                ..._branches.map((b) {
                  final bid = _parseIntId(b['id']);
                  if (bid == null) return null;
                  return DropdownMenuItem<int?>(
                    value: bid,
                    child: Text(b['name']?.toString() ?? '—'),
                  );
                }).whereType<DropdownMenuItem<int?>>(),
              ],
              onChanged: (v) => setState(() => _leadBranchId = v),
            )
          else
            Text(
              'No branches in the system yet. Ask an admin to add branches; you can still submit category and model.',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
          const SizedBox(height: 16),
          if (_loadingCatalog)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            DropdownButtonFormField<int?>(
              value: _needCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined, size: 22),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('-- Select category --'),
                ),
                ..._categories
                    .map((c) {
                      final cid = _parseIntId(c['id']);
                      if (cid == null) return null;
                      return DropdownMenuItem<int?>(
                        value: cid,
                        child: Text(c['name']?.toString() ?? '—'),
                      );
                    })
                    .whereType<DropdownMenuItem<int?>>(),
              ],
              onChanged: (v) => _onNeedCategoryChanged(v),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            value: _needProductId,
            decoration: const InputDecoration(
              labelText: 'Model',
              prefixIcon: Icon(Icons.phone_android_outlined, size: 22),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('-- Select model --'),
              ),
              ..._needProducts
                  .map((p) {
                    final pid = _parseIntId(p['id']);
                    if (pid == null) return null;
                    return DropdownMenuItem<int?>(
                      value: pid,
                      child: Text(p['name']?.toString() ?? '—'),
                    );
                  })
                  .whereType<DropdownMenuItem<int?>>(),
            ],
            onChanged: _needCategoryId == null
                ? null
                : (v) {
                    setState(() => _needProductId = v);
                  },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (!_submittingNeed && leadReady) ? _submitNeed : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: _submittingNeed
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit lead'),
          ),
        ],
      ),
    );
  }
}
