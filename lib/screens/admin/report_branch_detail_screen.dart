import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/reports_api.dart';
import 'admin_scaffold.dart';

class ReportBranchDetailScreen extends StatefulWidget {
  const ReportBranchDetailScreen({super.key, required this.branchId});

  final int branchId;

  @override
  State<ReportBranchDetailScreen> createState() => _ReportBranchDetailScreenState();
}

class _ReportBranchDetailScreenState extends State<ReportBranchDetailScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await getReportBranchDetail(widget.branchId);
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _fmt(double v) => '${NumberFormat('#,##0').format(v)} TZS';

  @override
  Widget build(BuildContext context) {
    final branchName = _data['branch_name']?.toString() ?? 'Branch';
    final purchases = (_data['purchases'] is List) ? (_data['purchases'] as List) : const [];
    return AdminScaffold(
      title: branchName,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(padding: const EdgeInsets.all(16), child: Text(_error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final p = purchases[index] as Map<String, dynamic>;
                    final name = p['name']?.toString() ?? 'Purchase';
                    final total = (p['total_amount'] as num?)?.toDouble() ?? 0;
                    final date = p['date']?.toString() ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(date),
                          const SizedBox(height: 4),
                          Text(_fmt(total)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
