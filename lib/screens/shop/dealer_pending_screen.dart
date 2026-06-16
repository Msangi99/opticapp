import 'package:flutter/material.dart';

import '../../api/auth_api.dart';
import 'shop_scaffold.dart';

class DealerPendingScreen extends StatelessWidget {
  const DealerPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopScaffold(
      title: 'Registration pending',
      showDrawer: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 72, color: kShopBrandOrange),
              const SizedBox(height: 24),
              Text(
                'Dealer approval pending',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your dealer registration has been submitted. An administrator must approve your account before you can access the shop.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () async {
                  await performLogout();
                },
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
