import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import '../admin/widgets/admin_page_ui.dart';
import 'shop_address_form_screen.dart';
import 'shop_scaffold.dart';

class ShopAddressesScreen extends StatefulWidget {
  const ShopAddressesScreen({
    super.key,
    this.apiPrefix = 'customer',
    this.mode = ShopPortalMode.customer,
  });

  final String apiPrefix;
  final ShopPortalMode mode;

  @override
  State<ShopAddressesScreen> createState() => _ShopAddressesScreenState();
}

class _ShopAddressesScreenState extends State<ShopAddressesScreen> {
  late final ShopApi _api = ShopApi(apiPrefix: widget.apiPrefix);
  List<dynamic> _addresses = [];
  bool _loading = true;
  String? _error;

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
      final addresses = await _api.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
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

  Future<void> _delete(int id) async {
    await _api.deleteAddress(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Addresses',
      mode: widget.mode,
      showDrawer: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShopAddressFormScreen(apiPrefix: widget.apiPrefix, mode: widget.mode),
            ),
          );
          _load();
        },
        backgroundColor: kShopBrandOrange,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const AdminPageLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? AdminPageError(message: _error!)
                  : _addresses.isEmpty
                      ? const AdminPageEmpty(icon: Icons.location_on_outlined, title: 'No addresses yet')
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _addresses.length,
                          itemBuilder: (context, i) {
                            final a = _addresses[i] as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                title: Text(a['type']?.toString() ?? 'Address'),
                                subtitle: Text('${a['address']}, ${a['city']}, ${a['country']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(a['id'] as int),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ShopAddressFormScreen(
                                        apiPrefix: widget.apiPrefix,
                                        mode: widget.mode,
                                        existing: a,
                                      ),
                                    ),
                                  );
                                  _load();
                                },
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}
