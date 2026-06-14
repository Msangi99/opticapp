import 'package:flutter/foundation.dart';

import '../api/pending_request_counts_api.dart';

class PendingRequestCountsProvider extends ChangeNotifier {
  PendingRequestCounts counts = PendingRequestCounts.empty();
  bool loading = false;

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      counts = await fetchPendingRequestCounts();
    } catch (_) {
      counts = PendingRequestCounts.empty();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSilently() async {
    try {
      counts = await fetchPendingRequestCounts();
      notifyListeners();
    } catch (_) {}
  }
}
