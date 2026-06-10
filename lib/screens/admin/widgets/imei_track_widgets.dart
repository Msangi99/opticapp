import 'package:flutter/material.dart';

/// Expandable track/trace panel for one IMEI (mirrors web imei-full-info partial).
class ImeiTrackPanel extends StatelessWidget {
  const ImeiTrackPanel({super.key, required this.detail});

  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final track = detail['track'] as Map<String, dynamic>?;
    final sold = track?['sold'] == true || detail['status'] == 'sold';
    final soldAt = detail['sold_at']?.toString();
    final soldLabel = track?['sold_label']?.toString();
    final statusLabel = sold
        ? (soldLabel == 'installed'
            ? 'Installed'
            : soldLabel == 'distribution'
                ? 'Distribution'
                : 'Sold')
        : 'In stock';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  detail['imei_number']?.toString() ?? '–',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              ImeiStatusChip(
                label: statusLabel,
                color: sold ? const Color(0xFFE5E7EB) : const Color(0xFFD1FAE5),
                textColor: sold ? const Color(0xFF374151) : const Color(0xFF065F46),
              ),
              if (soldAt != null && soldAt.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(soldAt.length > 10 ? soldAt.substring(0, 10) : soldAt, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (track?['purchase_name'] != null)
            ImeiTrackRow(label: 'Purchase / source', value: _purchaseSource(track)),
          if (detail['stock_name'] != null)
            ImeiTrackRow(label: 'Stock', value: detail['stock_name']?.toString() ?? '–'),
          ..._hierarchyRows(track),
          if (!sold && !_hasAgentInChain(track))
            ImeiTrackRow(label: 'Assignment', value: _pendingAssignmentMessage(track)),
          if (sold) ImeiSoldTrackSection(track: track),
          const SizedBox(height: 8),
          Text(
            'Product list ID: ${detail['id'] ?? '–'}${detail['product_name'] != null ? ' · Model: ${detail['product_name']}' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _purchaseSource(Map<String, dynamic>? track) {
    if (track == null) return '–';
    final name = track['purchase_name']?.toString() ?? '–';
    final distributor = track['distributor_name']?.toString();
    if (distributor != null && distributor.isNotEmpty) {
      return '$name — Supplier: $distributor';
    }
    return name;
  }

  List<Widget> _hierarchyRows(Map<String, dynamic>? track) {
    final chain = track?['hierarchy_chain'];
    if (chain is! List || chain.isEmpty) {
      return [
        if (track?['sold'] != true)
          const ImeiTrackRow(
            label: 'Distribution chain',
            value: 'Not assigned to regional manager — available in warehouse',
          ),
      ];
    }

    return [
      const SizedBox(height: 4),
      ImeiHighlightBox(
        color: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFFE2E8F0),
        title: 'Distribution chain',
        children: [
          for (final step in chain)
            if (step is Map)
              ImeiTrackRow(
                label: step['label']?.toString() ?? step['role']?.toString() ?? 'Step',
                value: _formatPerson(step),
                highlight: step['role']?.toString() == 'agent',
              ),
        ],
      ),
    ];
  }

  bool _hasAgentInChain(Map<String, dynamic>? track) {
    final chain = track?['hierarchy_chain'];
    if (chain is! List) return track?['assigned_agent_name'] != null;
    return chain.any((step) => step is Map && step['role']?.toString() == 'agent');
  }

  String _pendingAssignmentMessage(Map<String, dynamic>? track) {
    final chain = track?['hierarchy_chain'];
    if (chain is List) {
      final hasTeamLeader = chain.any((step) => step is Map && step['role']?.toString() == 'team_leader');
      final hasRegionalManager = chain.any((step) => step is Map && step['role']?.toString() == 'regional_manager');
      if (hasTeamLeader) return 'With team leader — not yet assigned to an agent';
      if (hasRegionalManager) return 'With regional manager — not yet assigned to a team leader';
    }
    return 'Not assigned — available in warehouse';
  }

  String _formatPerson(Map step) {
    final name = step['name']?.toString() ?? '–';
    final email = step['email']?.toString();
    if (email != null && email.isNotEmpty) return '$name ($email)';
    return name;
  }
}

class ImeiSoldTrackSection extends StatelessWidget {
  const ImeiSoldTrackSection({super.key, this.track});

  final Map<String, dynamic>? track;

  @override
  Widget build(BuildContext context) {
    if (track == null) return const SizedBox.shrink();

    final saleType = track!['sale_type']?.toString();

    if (saleType == 'distribution') {
      return ImeiHighlightBox(
        color: const Color(0xFFECFDF5),
        borderColor: const Color(0xFFA7F3D0),
        title: 'Distribution sale (dealer)',
        children: [
          if (track!['dealer_name'] != null) ImeiTrackRow(label: 'Dealer', value: track!['dealer_name']?.toString() ?? '–'),
          if (track!['seller_name'] != null) ImeiTrackRow(label: 'Recorded by', value: track!['seller_name']?.toString() ?? '–'),
          if (track!['distribution_status'] != null)
            ImeiTrackRow(
              label: 'Status',
              value: '${track!['distribution_status']} — Paid ${track!['paid_amount'] ?? 0} / ${track!['total_selling_value'] ?? 0} TZS',
            ),
          if (track!['balance'] != null && (track!['balance'] as num?)?.toDouble() != 0)
            ImeiTrackRow(label: 'Balance', value: '${track!['balance']} TZS'),
        ],
      );
    }

    if (saleType == 'credit') {
      return ImeiHighlightBox(
        color: const Color(0xFFF5F3FF),
        borderColor: const Color(0xFFDDD6FE),
        title: 'Credit sale (agent)',
        children: [
          if (track!['customer_name'] != null) ImeiTrackRow(label: 'Customer', value: track!['customer_name']?.toString() ?? '–'),
          if (track!['agent_name'] != null) ImeiTrackRow(label: 'Agent', value: track!['agent_name']?.toString() ?? '–'),
          if (track!['payment_status'] != null)
            ImeiTrackRow(
              label: 'Credit status',
              value: '${track!['payment_status']} — Paid ${track!['paid_amount'] ?? 0} / ${track!['total_amount'] ?? 0} TZS',
            ),
          if (track!['payment_channel'] != null) ImeiTrackRow(label: 'Channel', value: track!['payment_channel']?.toString() ?? '–'),
        ],
      );
    }

    if (saleType == 'pending') {
      return ImeiHighlightBox(
        color: const Color(0xFFF0F9FF),
        borderColor: const Color(0xFFBAE6FD),
        title: 'Pending sale',
        children: [
          if (track!['customer_name'] != null) ImeiTrackRow(label: 'Customer', value: track!['customer_name']?.toString() ?? '–'),
          if (track!['seller_name'] != null) ImeiTrackRow(label: 'Seller', value: track!['seller_name']?.toString() ?? '–'),
          if (track!['selling_price'] != null) ImeiTrackRow(label: 'Sale amount', value: '${track!['selling_price']} TZS'),
        ],
      );
    }

    if (saleType == 'agent_sale') {
      return ImeiHighlightBox(
        color: const Color(0xFFFFF7ED),
        borderColor: const Color(0xFFFED7AA),
        title: 'Installed by agent',
        children: [
          if (track!['customer_name'] != null) ImeiTrackRow(label: 'Customer', value: track!['customer_name']?.toString() ?? '–'),
          if (track!['agent_name'] != null) ImeiTrackRow(label: 'Agent', value: track!['agent_name']?.toString() ?? '–'),
          if (track!['total_selling_value'] != null) ImeiTrackRow(label: 'Total value', value: '${track!['total_selling_value']} TZS'),
        ],
      );
    }

    if (saleType == 'unknown') {
      return const ImeiHighlightBox(
        color: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
        title: 'Sold',
        children: [ImeiTrackRow(label: 'Details', value: 'No linked credit, pending sale, or agent sale record')],
      );
    }

    return const SizedBox.shrink();
  }
}

class ImeiHighlightBox extends StatelessWidget {
  const ImeiHighlightBox({super.key, required this.color, required this.borderColor, required this.title, required this.children});

  final Color color;
  final Color borderColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class ImeiTrackRow extends StatelessWidget {
  const ImeiTrackRow({super.key, required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: highlight ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}

class ImeiStatusChip extends StatelessWidget {
  const ImeiStatusChip({super.key, required this.label, required this.color, required this.textColor});

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor, letterSpacing: 0.3)),
    );
  }
}
