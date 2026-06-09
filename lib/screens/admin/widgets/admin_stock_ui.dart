import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'admin_users_ui.dart';

/// Compact horizontal KPI strip — low height, clay panel, accent bars.
class AdminStockSummaryPanel extends StatelessWidget {
  const AdminStockSummaryPanel({
    super.key,
    required this.label,
    required this.stats,
    this.columns = 2,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final String label;
  final List<AdminStockStat> stats;
  /// Kept for API compatibility; layout is always a single compact row/scroll.
  final int columns;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.98),
            const Color(0xFFF8FAFC).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 11,
                    decoration: BoxDecoration(
                      color: kAdminBrandOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: kAdminTextMuted,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 44,
              child: stats.length <= 3
                  ? Row(
                      children: [
                        for (var i = 0; i < stats.length; i++) ...[
                          if (i > 0) _verticalRule(),
                          Expanded(child: _SummaryStatCell(stat: stats[i])),
                        ],
                      ],
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: stats.length,
                      separatorBuilder: (context, index) => _verticalRule(),
                      itemBuilder: (context, index) => _SummaryStatCell(
                        stat: stats[index],
                        minWidth: 88,
                      ),
                    ),
            ),
            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}

Widget _verticalRule() => Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
    );

class _SummaryStatCell extends StatelessWidget {
  const _SummaryStatCell({required this.stat, this.minWidth});

  final AdminStockStat stat;
  final double? minWidth;

  Color get _accent {
    if (stat.highlight) {
      return stat.highlightColor ?? const Color(0xFFFA8900);
    }
    return const Color(0xFFCBD5E1);
  }

  @override
  Widget build(BuildContext context) {
    final valueColor =
        stat.highlight ? (stat.highlightColor ?? const Color(0xFFB45309)) : kAdminBrandDark;

    final cell = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 2.5,
            height: 28,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1.05,
                    letterSpacing: -0.25,
                  ),
                ),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: stat.highlight
                        ? (stat.highlightColor ?? const Color(0xFFB45309)).withValues(alpha: 0.85)
                        : kAdminTextMuted,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (minWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth!),
        child: cell,
      );
    }
    return cell;
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
          const SizedBox(height: 6),
          AdminStockSummaryPanel(
            label: summaryLabel!,
            stats: summaryStats!,
            columns: summaryColumns,
          ),
        ],
        const SizedBox(height: 6),
        Expanded(child: body),
      ],
    );
  }
}
