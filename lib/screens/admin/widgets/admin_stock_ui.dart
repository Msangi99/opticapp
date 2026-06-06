import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'admin_users_ui.dart';

/// Summary panel matching web `x-admin-page-dashboard`.
class AdminStockSummaryPanel extends StatelessWidget {
  const AdminStockSummaryPanel({
    super.key,
    required this.label,
    required this.stats,
    this.columns = 2,
  });

  final String label;
  final List<AdminStockStat> stats;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: kAdminTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: stats
                .map(
                  (s) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: s.highlight ? s.highlightColor ?? const Color(0xFFB45309) : kAdminBrandDark,
                        ),
                      ),
                      Text(
                        s.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: s.highlight ? const Color(0xFFB45309) : kAdminTextMuted,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class AdminStockStat {
  const AdminStockStat({
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;
}

String formatTzs(num? value) {
  if (value == null) return '0 TZS';
  return '${NumberFormat('#,##0').format(value)} TZS';
}

String formatCount(num? value) {
  if (value == null) return '0';
  return NumberFormat('#,##0').format(value);
}

/// Web-style stock page shell with eyebrow header and optional summary.
class AdminStockPageShell extends StatelessWidget {
  const AdminStockPageShell({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    this.summaryLabel,
    this.summaryStats,
    this.summaryColumns = 2,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? summaryLabel;
  final List<AdminStockStat>? summaryStats;
  final int summaryColumns;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminUsersPageHeader(
          eyebrow: eyebrow,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
        ),
        if (summaryLabel != null && summaryStats != null && summaryStats!.isNotEmpty) ...[
          const SizedBox(height: 12),
          AdminStockSummaryPanel(
            label: summaryLabel!,
            stats: summaryStats!,
            columns: summaryColumns,
          ),
        ],
        const SizedBox(height: 12),
        Expanded(child: body),
      ],
    );
  }
}
