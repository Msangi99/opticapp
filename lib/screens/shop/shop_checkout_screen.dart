import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'shop_address_form_screen.dart';
import 'shop_payment_screen.dart';
import 'shop_scaffold.dart';

class ShopCheckoutScreen extends StatefulWidget {
  const ShopCheckoutScreen({
    super.key,
    this.apiPrefix = 'customer',
    this.mode = ShopPortalMode.customer,
  });

  final String apiPrefix;
  final ShopPortalMode mode;

  @override
  State<ShopCheckoutScreen> createState() => _ShopCheckoutScreenState();
}

class _ShopCheckoutScreenState extends State<ShopCheckoutScreen> {
  late final ShopApi _api = ShopApi(apiPrefix: widget.apiPrefix);
  Map<String, dynamic>? _preview;
  int? _addressId;
  String _paymentMethod = 'selcom';
  final _phoneController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await _api.getCheckoutPreview();
      final addresses = preview['addresses'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _addressId = addresses.isNotEmpty ? addresses.first['id'] as int? : null;
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

  Future<void> _placeOrder() async {
    if (_addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a delivery address')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await _api.placeOrder(
        addressId: _addressId!,
        paymentMethod: _paymentMethod,
        paymentPhone: _paymentMethod == 'selcom' ? _phoneController.text.trim() : null,
      );
      if (!mounted) return;
      if (_paymentMethod == 'selcom') {
        final order = (result['data'] as Map<String, dynamic>?)?['order'] as Map<String, dynamic>?;
        final orderId = order?['id'] as int?;
        if (orderId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ShopPaymentScreen(orderId: orderId, apiPrefix: widget.apiPrefix, mode: widget.mode),
            ),
          );
          return;
        }
      }
      Navigator.popUntil(context, (r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Order placed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = _preview?['addresses'] as List<dynamic>? ?? [];

    return ShopScaffold(
      title: 'Checkout',
      mode: widget.mode,
      showDrawer: false,
      body: _loading
          ? const AdminPageLoading()
          : _error != null
              ? AdminPageError(message: _error!)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Delivery address', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (addresses.isEmpty)
                        OutlinedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShopAddressFormScreen(apiPrefix: widget.apiPrefix, mode: widget.mode),
                              ),
                            );
                            _load();
                          },
                          child: const Text('Add address'),
                        )
                      else
                        ...addresses.map((a) {
                          final id = a['id'] as int;
                          return RadioListTile<int>(
                            value: id,
                            groupValue: _addressId,
                            onChanged: (v) => setState(() => _addressId = v),
                            title: Text('${a['address']}, ${a['city']}'),
                            subtitle: Text(a['country']?.toString() ?? ''),
                          );
                        }),
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopAddressFormScreen(apiPrefix: widget.apiPrefix, mode: widget.mode),
                            ),
                          );
                          _load();
                        },
                        child: const Text('Add new address'),
                      ),
                      const Divider(height: 32),
                      Text('Payment', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      RadioListTile<String>(
                        value: 'selcom',
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                        title: const Text('Mobile money (Selcom)'),
                      ),
                      RadioListTile<String>(
                        value: 'cod',
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                        title: const Text('Cash on delivery'),
                      ),
                      if (_paymentMethod == 'selcom') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Payment phone', border: OutlineInputBorder()),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text('Total: ${formatTzs((_preview?['total'] as num?) ?? 0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _submitting ? null : _placeOrder,
                        style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange, padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Text(_submitting ? 'Processing…' : 'Place order'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
