import 'package:flutter/material.dart';
import 'dart:async';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// KITCHEN DISPLAY SYSTEM (KDS)
// In production: connect Socket.io to receive real orders.
// For now, simulated orders are added every 15 seconds.
// ─────────────────────────────────────────────────────────────

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final List<_KitchenOrder> _orders = [];
  Timer? _simulationTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  int _orderCounter = 1;

  @override
  void initState() {
    super.initState();
    _addSimulatedOrder(); // start with one order

    // Simulate new orders coming in
    _simulationTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _addSimulatedOrder();
    });

    // Clock update
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  void _addSimulatedOrder() {
    final demos = [
      [
        {'name': 'Chicken Adobo', 'qty': 2, 'cat': 'Mains'},
        {'name': 'Garlic Fried Rice', 'qty': 2, 'cat': 'Rice & Sides'},
        {'name': 'Calamansi Juice', 'qty': 2, 'cat': 'Drinks'},
      ],
      [
        {'name': 'Pork Sisig', 'qty': 1, 'cat': 'Mains', 'note': 'Extra spicy'},
        {'name': 'Steamed Rice', 'qty': 2, 'cat': 'Rice & Sides'},
        {'name': 'Iced Tea', 'qty': 1, 'cat': 'Drinks'},
      ],
      [
        {'name': 'Beef Kare-Kare', 'qty': 1, 'cat': 'Mains'},
        {'name': 'Lumpia Shanghai', 'qty': 1, 'cat': 'Rice & Sides'},
        {'name': 'Leche Flan', 'qty': 2, 'cat': 'Desserts'},
      ],
    ];

    final tableNum = (_orderCounter % 10) + 1;
    final demo = demos[(_orderCounter - 1) % demos.length];

    setState(() {
      _orders.insert(0, _KitchenOrder(
        id: 'ORD-${1000 + _orderCounter}',
        tableNumber: tableNum,
        items: demo.map((d) => _KitchenItem(
          name: d['name'] as String,
          quantity: d['qty'] as int,
          category: d['cat'] as String,
          note: d['note'] as String? ?? '',
        )).toList(),
        receivedAt: DateTime.now(),
        status: KdsStatus.new_,
      ));
      _orderCounter++;
    });
  }

  void _updateStatus(String orderId, KdsStatus newStatus) {
    setState(() {
      final order = _orders.firstWhere((o) => o.id == orderId);
      order.status = newStatus;
      if (newStatus == KdsStatus.done) {
        // Move done orders to the end
        _orders.remove(order);
        _orders.add(order);
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _orders.where((o) => o.status != KdsStatus.done).toList();
    final done = _orders.where((o) => o.status == KdsStatus.done).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildKdsHeader(active.length, done.length),
            Expanded(
              child: _orders.isEmpty
                  ? _buildEmpty()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (active.isNotEmpty) ...[
                            _sectionLabel('Active Orders (${active.length})'),
                            const SizedBox(height: 10),
                            _buildOrderGrid(active),
                          ],
                          if (done.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _sectionLabel('Completed'),
                            const SizedBox(height: 10),
                            _buildOrderGrid(done, compact: true),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKdsHeader(int active, int done) {
    final timeStr = '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('🍳', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          const Text('Kitchen Display', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          _StatPill(label: 'Active', value: '$active', color: AppTheme.primary),
          const SizedBox(width: 8),
          _StatPill(label: 'Done', value: '$done', color: AppTheme.success),
          const SizedBox(width: 16),
          Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 16, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 11, color: Colors.white38, letterSpacing: 1.2, fontWeight: FontWeight.w600));
  }

  Widget _buildOrderGrid(List<_KitchenOrder> orders, {bool compact = false}) {
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
      itemBuilder: (_, i) => _OrderCard(
        order: orders[i],
        onStatusChange: _updateStatus,
        compact: compact,
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('👨‍🍳', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('No orders yet', style: TextStyle(color: Colors.white38, fontSize: 18)),
          SizedBox(height: 8),
          Text('New orders will appear here automatically', style: TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _KitchenOrder order;
  final void Function(String, KdsStatus) onStatusChange;
  final bool compact;

  const _OrderCard({required this.order, required this.onStatusChange, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(order.receivedAt);
    final isUrgent = elapsed.inMinutes >= 10 && order.status != KdsStatus.done;

    Color borderColor;
    Color headerColor;
    switch (order.status) {
      case KdsStatus.new_: borderColor = AppTheme.primary; headerColor = AppTheme.primary;
      case KdsStatus.cooking: borderColor = AppTheme.warning; headerColor = AppTheme.warning;
      case KdsStatus.done: borderColor = AppTheme.success; headerColor = AppTheme.success;
    }

    if (isUrgent) borderColor = Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: compact ? _buildCompact(headerColor) : _buildFull(headerColor, elapsed, isUrgent),
    );
  }

  Widget _buildFull(Color headerColor, Duration elapsed, bool isUrgent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: headerColor.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.id, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: headerColor.withOpacity(0.25), borderRadius: BorderRadius.circular(6)),
                child: Text('Table ${order.tableNumber}',
                    style: TextStyle(color: headerColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),

        // Items
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)),
                            child: Center(child: Text('${item.quantity}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                if (item.note.isNotEmpty)
                                  Text('📝 ${item.note}', style: const TextStyle(color: Colors.orange, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),

        // Footer — timer + action
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 12, color: isUrgent ? Colors.red : Colors.white38),
                  const SizedBox(width: 4),
                  Text(_formatElapsed(elapsed),
                      style: TextStyle(fontSize: 11, color: isUrgent ? Colors.red : Colors.white38)),
                ],
              ),
              const SizedBox(height: 6),
              _buildActionButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(Color headerColor) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Table ${order.tableNumber}',
                style: TextStyle(color: headerColor, fontSize: 13, fontWeight: FontWeight.w700)),
            const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
          ]),
          const SizedBox(height: 4),
          Text(order.id, style: const TextStyle(color: Colors.white30, fontSize: 10, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text('${order.items.length} items', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    switch (order.status) {
      case KdsStatus.new_:
        return _KdsButton(
          label: 'Start Cooking',
          color: AppTheme.warning,
          onTap: () => onStatusChange(order.id, KdsStatus.cooking),
        );
      case KdsStatus.cooking:
        return _KdsButton(
          label: 'Mark Ready ✓',
          color: AppTheme.success,
          onTap: () => onStatusChange(order.id, KdsStatus.done),
        );
      case KdsStatus.done:
        return const SizedBox.shrink();
    }
  }

  String _formatElapsed(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }
}

class _KdsButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _KdsButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withOpacity(0.5))),
        child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
      ]),
    );
  }
}

// ── Models ──────────────────────────────────────────────────

enum KdsStatus { new_, cooking, done }

class _KitchenOrder {
  final String id;
  final int tableNumber;
  final List<_KitchenItem> items;
  final DateTime receivedAt;
  KdsStatus status;

  _KitchenOrder({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.receivedAt,
    required this.status,
  });
}

class _KitchenItem {
  final String name;
  final int quantity;
  final String category;
  final String note;
  const _KitchenItem({required this.name, required this.quantity, required this.category, this.note = ''});
}
