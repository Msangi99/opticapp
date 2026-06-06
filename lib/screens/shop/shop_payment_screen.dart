import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/shop_api.dart';
import 'shop_scaffold.dart';

class ShopPaymentScreen extends StatefulWidget {
  const ShopPaymentScreen({
    super.key,
    required this.orderId,
    this.apiPrefix = 'customer',
    this.mode = ShopPortalMode.customer,
  });

  final int orderId;
  final String apiPrefix;
  final ShopPortalMode mode;

  @override
  State<ShopPaymentScreen> createState() => _ShopPaymentScreenState();
}

class _ShopPaymentScreenState extends State<ShopPaymentScreen> {
  late final ShopApi _api = ShopApi(apiPrefix: widget.apiPrefix);
  String _status = 'pending';
  String _message = 'Waiting for payment confirmation…';
  Timer? _timer;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_status != 'pending' || _polls > 120) return;
    _polls++;
    try {
      final res = await _api.pollPaymentStatus(widget.orderId);
      if (!mounted) return;
      setState(() {
        _status = res['status']?.toString() ?? 'pending';
        _message = res['message']?.toString() ?? _message;
      });
      if (_status == 'completed') {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.popUntil(context, (r) => r.isFirst);
        });
        return;
      }
      if (_status == 'pending') {
        _timer = Timer(const Duration(seconds: 3), _poll);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'error';
        _message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Payment',
      mode: widget.mode,
      showDrawer: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_status == 'pending') const CircularProgressIndicator(),
              if (_status == 'completed') const Icon(Icons.check_circle, color: Colors.green, size: 72),
              if (_status == 'failed' || _status == 'error' || _status == 'timeout')
                const Icon(Icons.error_outline, color: Colors.red, size: 72),
              const SizedBox(height: 24),
              Text(
                _status == 'completed'
                    ? 'Payment successful!'
                    : _status == 'pending'
                        ? 'Check your phone'
                        : 'Payment issue',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(_message, textAlign: TextAlign.center),
              if (_status != 'pending' && _status != 'completed') ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to checkout'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
