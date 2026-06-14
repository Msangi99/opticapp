import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notifications_provider.dart';
import '../providers/pending_request_counts_provider.dart';

/// Refreshes bell + drawer badges when the app returns to the foreground.
class PortalBadgeLifecycleRefresher extends StatefulWidget {
  const PortalBadgeLifecycleRefresher({super.key, required this.child});

  final Widget child;

  @override
  State<PortalBadgeLifecycleRefresher> createState() =>
      _PortalBadgeLifecycleRefresherState();
}

class _PortalBadgeLifecycleRefresherState extends State<PortalBadgeLifecycleRefresher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context.read<NotificationsProvider>().refreshSilently();
    context.read<PendingRequestCountsProvider>().refreshSilently();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
