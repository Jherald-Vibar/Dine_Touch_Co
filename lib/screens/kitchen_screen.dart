import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

const String _restaurantId = '00000000-0000-0000-0000-000000000001';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});
  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  final Map<String, List<Map<String, dynamic>>> _itemsCache = {};

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadItemsFor(String orderId) async {
    if (_itemsCache.containsKey(orderId)) return;
    final items = await SupabaseService.fetchOrderItems(orderId);
    if (mounted) setState(() => _itemsCache[orderId] = items);
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await SupabaseService.updateOrderStatus(orderId, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: SupabaseService.watchActiveOrders(_restaurantId),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            for (final o in orders) {
              _loadItemsFor(o['id'] as String);
            }
            final active = orders.where((o) => o['status'] != 'ready').toList();
            final ready = orders.where((o) => o['status'] == 'ready').toList();

            return Column(children: [
              _buildHeader(active.length, ready.length),
              Expanded(
                child: orders.isEmpty
                    ? _buildEmpty(snapshot.connectionState)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (active.isNotEmpty) ...[
                                _sectionLabel('Active (${active.length})'),
                                const SizedBox(height: 10),
                                _buildGrid(active),
                              ],
                              if (ready.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _sectionLabel('Ready to serve (${ready.length})'),
                                const SizedBox(height: 10),
                                _buildGrid(ready, compact: true),
                              ],
                            ]),
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int active, int ready) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final t = '$h:$m';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10)),
          child: const Center(
              child: Text('🍳', style: TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        const Text('Kitchen Display',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3)),
        const Spacer(),
        _Pill(label: 'Active', value: '$active', color: AppTheme.primary),
        const SizedBox(width: 8),
        _Pill(label: 'Ready', value: '$ready', color: AppTheme.success),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Text(t,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textHint,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700),
      );

  Widget _buildGrid(List<Map<String, dynamic>> orders, {bool compact = false}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 4 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: compact ? 1.6 : 0.85,
      ),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        final items = _itemsCache[o['id']] ?? [];
        return _OrderCard(
          order: o,
          items: items,
          onStatusChange: _updateStatus,
          compact: compact,
        );
      },
    );
  }

  Widget _buildEmpty(ConnectionState state) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(state == ConnectionState.waiting ? '⏳' : '👨‍🍳',
            style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(
          state == ConnectionState.waiting ? 'Connecting...' : 'No active orders',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text('New orders appear here automatically',
            style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
      ]),
    );
  }
}

// ── Order Card ───────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> items;
  final Future<void> Function(String, String) onStatusChange;
  final bool compact;

  const _OrderCard({
    required this.order,
    required this.items,
    required this.onStatusChange,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final createdAt =
        DateTime.tryParse(order['created_at'] as String? ?? '') ?? DateTime.now();
    final elapsed = DateTime.now().difference(createdAt);
    final isUrgent = elapsed.inMinutes >= 10 && status != 'ready';
    final tableNumber = order['table_number'];

    Color borderColor;
    Color accentColor;
    switch (status) {
      case 'pending':
        borderColor = AppTheme.primary;
        accentColor = AppTheme.primary;
      case 'preparing':
        borderColor = AppTheme.warning;
        accentColor = AppTheme.warning;
      case 'ready':
        borderColor = AppTheme.success;
        accentColor = AppTheme.success;
      default:
        borderColor = AppTheme.border;
        accentColor = AppTheme.textHint;
    }
    if (isUrgent) borderColor = Colors.red;

    if (compact) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Table $tableNumber',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
          ]),
          const SizedBox(height: 4),
          Text('${items.length} items',
              style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
          const SizedBox(height: 6),
          _ActionButton(
              status: status,
              orderId: order['id'] as String,
              onStatusChange: onStatusChange),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.10),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              (order['id'] as String).substring(0, 8).toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 10,
                  fontFamily: 'monospace'),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('Table $tableNumber',
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),

        // Items list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: items.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.map((item) {
                      final note = item['special_request'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Center(
                                    child: Text('${item['quantity']}',
                                        style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'] as String,
                                          style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                      if (note.isNotEmpty)
                                        Text('📝 $note',
                                            style: const TextStyle(
                                                color: AppTheme.warning,
                                                fontSize: 10)),
                                    ]),
                              ),
                            ]),
                      );
                    }).toList(),
                  ),
          ),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Column(children: [
            Row(children: [
              Icon(Icons.timer_outlined,
                  size: 12,
                  color: isUrgent ? Colors.red : AppTheme.textHint),
              const SizedBox(width: 4),
              Text(_fmt(elapsed),
                  style: TextStyle(
                      fontSize: 11,
                      color: isUrgent ? Colors.red : AppTheme.textHint)),
            ]),
            const SizedBox(height: 6),
            _ActionButton(
                status: status,
                orderId: order['id'] as String,
                onStatusChange: onStatusChange),
          ]),
        ),
      ]),
    );
  }

  String _fmt(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }
}

class _ActionButton extends StatelessWidget {
  final String status;
  final String orderId;
  final Future<void> Function(String, String) onStatusChange;

  const _ActionButton({
    required this.status,
    required this.orderId,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    String nextStatus;

    switch (status) {
      case 'pending':
        label = 'Start Cooking';
        color = AppTheme.warning;
        nextStatus = 'preparing';
      case 'preparing':
        label = 'Mark Ready ✓';
        color = AppTheme.success;
        nextStatus = 'ready';
      case 'ready':
        label = 'Mark Served';
        color = AppTheme.textHint;
        nextStatus = 'served';
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => onStatusChange(orderId, nextStatus),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700))),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Pill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(width: 5),
        Text(label,
            style:
                TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
      ]),
    );
  }
}