import 'package:flutter/material.dart';
import '../../api/users_api.dart';
import '../../theme/app_theme.dart';
import 'admin_scaffold.dart';

class DealersScreen extends StatefulWidget {
  const DealersScreen({super.key});

  @override
  State<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends State<DealersScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getDealers();
      if (!mounted) return;
      setState(() { _list = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Dealers',
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Loading…', style: TextStyle(color: Color(0xFF6B7280)))]));
    if (_error != null) return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: Padding(padding: const EdgeInsets.all(20), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)), child: Text(_error!, style: errorStyle()))));
    if (_list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.store_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)), const SizedBox(height: 16), Text('No dealers yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))]));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (context, index) {
          final u = _list[index];
          final name = u['name'] as String? ?? '–';
          final email = u['email'] as String? ?? '–';
          final business = u['business_name'] as String?;
          final status = u['status'] as String? ?? 'pending';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: sectionCardDecoration(context),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.teal.withValues(alpha: 0.2), child: Text((name.isNotEmpty ? name[0] : '?').toUpperCase(), style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), Text(email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)), if (business != null && business.isNotEmpty) Text(business, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: (status == 'active' ? Colors.green : Colors.amber).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text((status).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: status == 'active' ? Colors.green.shade700 : Colors.amber.shade700))),
              ],
            ),
          );
        },
      ),
    );
  }
}
