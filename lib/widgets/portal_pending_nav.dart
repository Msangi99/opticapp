import 'package:flutter/material.dart';

import '../api/pending_request_counts_api.dart';
import 'portal_drawer.dart';

/// Shared inventory nav items with pending-request badges (matches web portal).
abstract final class PortalPendingNav {
  static List<PortalNavItem> agentInventoryItems(PendingRequestCounts counts) => [
        PortalNavItem(
          icon: Icons.inbox_rounded,
          label: 'Transfer requests',
          route: '/agent/transfers',
          badgeCount: counts.pendingTransferRequests > 0
              ? counts.pendingTransferRequests
              : null,
        ),
        const PortalNavItem(
          icon: Icons.undo_rounded,
          label: 'Return devices',
          route: '/agent/return-devices',
        ),
        PortalNavItem(
          icon: Icons.assignment_return_rounded,
          label: 'Return requests',
          route: '/agent/return-requests',
          badgeCount: counts.pendingReturnRequests > 0
              ? counts.pendingReturnRequests
              : null,
        ),
      ];

  static List<PortalNavItem> teamLeaderInventoryItems(PendingRequestCounts counts) => [
        PortalNavItem(
          icon: Icons.qr_code_2_rounded,
          label: 'IMEI register',
          route: '/team-leader/imei-register',
        ),
        PortalNavItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Transfer requests',
          route: '/team-leader/transfers',
          badgeCount: counts.pendingTransferRequests > 0
              ? counts.pendingTransferRequests
              : null,
        ),
        const PortalNavItem(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Assign to agent',
          route: '/team-leader/assign-agent',
        ),
        const PortalNavItem(
          icon: Icons.undo_rounded,
          label: 'Return to regional manager',
          route: '/team-leader/return-devices',
        ),
        PortalNavItem(
          icon: Icons.assignment_return_rounded,
          label: 'Return requests',
          route: '/team-leader/return-requests',
          badgeCount: counts.pendingReturnRequests > 0
              ? counts.pendingReturnRequests
              : null,
        ),
      ];

  static List<PortalNavItem> regionalManagerInventoryItems(
    PendingRequestCounts counts,
  ) =>
      [
        const PortalNavItem(
          icon: Icons.qr_code_2_rounded,
          label: 'IMEI register',
          route: '/regional-manager/imei-register',
        ),
        PortalNavItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Transfer requests',
          route: '/regional-manager/transfers',
          badgeCount: counts.pendingTransferRequests > 0
              ? counts.pendingTransferRequests
              : null,
        ),
        const PortalNavItem(
          icon: Icons.group_add_rounded,
          label: 'Assign to team leader',
          route: '/regional-manager/assign-team-leader',
        ),
        const PortalNavItem(
          icon: Icons.undo_rounded,
          label: 'Return to admin',
          route: '/regional-manager/return-devices',
        ),
        PortalNavItem(
          icon: Icons.assignment_return_rounded,
          label: 'Return requests',
          route: '/regional-manager/return-requests',
          badgeCount: counts.pendingReturnRequests > 0
              ? counts.pendingReturnRequests
              : null,
        ),
      ];

  static List<PortalNavItem> adminStockItems(PendingRequestCounts counts) => [
        const PortalNavItem(
          icon: Icons.inventory_2_rounded,
          label: 'Stocks',
          route: '/admin/stocks',
        ),
        const PortalNavItem(
          icon: Icons.qr_code_2_rounded,
          label: 'IMEI search',
          route: '/admin/imei-search',
        ),
        const PortalNavItem(
          icon: Icons.store_mall_directory_rounded,
          label: 'Branches',
          route: '/admin/branches',
        ),
        const PortalNavItem(
          icon: Icons.receipt_long_rounded,
          label: 'Purchases',
          route: '/admin/purchases',
        ),
        const PortalNavItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Passthrough Sales',
          route: '/admin/passthrough',
        ),
        const PortalNavItem(
          icon: Icons.local_shipping_rounded,
          label: 'Distribution Sales',
          route: '/admin/stock/distribution',
        ),
        const PortalNavItem(
          icon: Icons.person_pin_circle_rounded,
          label: 'Agent Cash Sales',
          route: '/admin/stock/agent-sales',
        ),
        const PortalNavItem(
          icon: Icons.credit_card_rounded,
          label: 'Agent Credit Sales',
          route: '/admin/agent-credits',
        ),
        PortalNavItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Agent transfers',
          route: '/admin/stock/agent-transfers',
          badgeCount: counts.pendingTransferRequests > 0
              ? counts.pendingTransferRequests
              : null,
        ),
        PortalNavItem(
          icon: Icons.assignment_return_rounded,
          label: 'Device returns',
          route: '/admin/stock/device-returns',
          badgeCount: counts.pendingReturnRequests > 0
              ? counts.pendingReturnRequests
              : null,
        ),
        const PortalNavItem(
          icon: Icons.alt_route_rounded,
          label: 'Branch transfer',
          route: '/admin/stock/branch-transfer',
        ),
      ];
}
