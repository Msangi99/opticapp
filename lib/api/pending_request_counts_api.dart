import 'dart:convert';

import 'client.dart';

class PendingRequestCounts {
  const PendingRequestCounts({
    required this.pendingTransferRequests,
    required this.pendingReturnRequests,
  });

  final int pendingTransferRequests;
  final int pendingReturnRequests;

  factory PendingRequestCounts.empty() => const PendingRequestCounts(
        pendingTransferRequests: 0,
        pendingReturnRequests: 0,
      );

  factory PendingRequestCounts.fromJson(Map<String, dynamic> json) {
    return PendingRequestCounts(
      pendingTransferRequests:
          (json['pending_transfer_requests'] as num?)?.toInt() ?? 0,
      pendingReturnRequests:
          (json['pending_return_requests'] as num?)?.toInt() ?? 0,
    );
  }
}

Future<PendingRequestCounts> fetchPendingRequestCounts() async {
  final res = await apiGet('/pending-request-counts');
  final decoded = jsonDecode(res.body);
  if (res.statusCode != 200) {
    return PendingRequestCounts.empty();
  }
  final data = decoded['data'];
  if (data is Map) {
    return PendingRequestCounts.fromJson(Map<String, dynamic>.from(data));
  }
  return PendingRequestCounts.empty();
}
