import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notifications_provider.dart';
import '../providers/pending_request_counts_provider.dart';

/// Refresh bell + drawer pending badges before opening the menu.
void refreshPortalBadges(BuildContext context) {
  context.read<NotificationsProvider>().refreshSilently();
  context.read<PendingRequestCountsProvider>().refreshSilently();
}
