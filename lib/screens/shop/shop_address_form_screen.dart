import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import 'shop_scaffold.dart';

class ShopAddressFormScreen extends StatefulWidget {
  const ShopAddressFormScreen({
    super.key,
    this.apiPrefix = 'customer',
    this.mode = ShopPortalMode.customer,
    this.existing,
  });

  final String apiPrefix;
  final ShopPortalMode mode;
  final Map<String, dynamic>? existing;

  @override
  State<ShopAddressFormScreen> createState() => _ShopAddressFormScreenState();
}

class _ShopAddressFormScreenState extends State<ShopAddressFormScreen> {
  late final ShopApi _api = ShopApi(apiPrefix: widget.apiPrefix);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zip;
  late final TextEditingController _country;
  late final TextEditingController _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _address = TextEditingController(text: e?['address']?.toString() ?? '');
    _city = TextEditingController(text: e?['city']?.toString() ?? '');
    _state = TextEditingController(text: e?['state']?.toString() ?? '');
    _zip = TextEditingController(text: e?['zip']?.toString() ?? '');
    _country = TextEditingController(text: e?['country']?.toString() ?? 'Tanzania');
    _type = TextEditingController(text: e?['type']?.toString() ?? 'home');
  }

  @override
  void dispose() {
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _country.dispose();
    _type.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'zip': _zip.text.trim(),
        'country': _country.text.trim(),
        'type': _type.text.trim(),
      };
      await _api.saveAddress(body, id: widget.existing?['id'] as int?);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: widget.existing == null ? 'Add address' : 'Edit address',
      mode: widget.mode,
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _type, decoration: const InputDecoration(labelText: 'Type (home/work)'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Street address'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _state, decoration: const InputDecoration(labelText: 'State/Region')),
              const SizedBox(height: 12),
              TextFormField(controller: _zip, decoration: const InputDecoration(labelText: 'ZIP')),
              const SizedBox(height: 12),
              TextFormField(controller: _country, decoration: const InputDecoration(labelText: 'Country'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: kShopBrandOrange, minimumSize: const Size.fromHeight(48)),
                child: Text(_saving ? 'Saving…' : 'Save address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
