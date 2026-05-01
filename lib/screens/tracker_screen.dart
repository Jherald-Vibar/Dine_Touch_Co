import 'package:flutter/material.dart';
import 'dart:async';
import '../models/order.dart';
import '../theme/app_theme.dart';
import 'menu_screen.dart';

class TrackerScreen extends StatefulWidget {
  final Order order;
  const TrackerScreen({super.key, required this.order});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  late OrderStatus _status;
  Timer? _simulationTimer;
  int _step = 0;

  // Simulates order progression — replace with real Socket.io in production
  final List<OrderStatus> _progression = [
    OrderStatus.received,
    OrderStatus.preparing,
    OrderStatus.ready,
  ];

  @override
  void initState() {
    super.initState();
    _status = OrderStatus.received;
    _startSimulation();
  }

  void _startSimulation() {
    // In production: listen to socket.on('order_status_update', ...)
    // For now, simulate status changes every 8 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_step < _progression.length - 1) {
        setState(() {
          _step++;
          _status = _progression[_step];
        });
      } else {
        _simulationTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              _buildStatusIcon(),
              const SizedBox(height: 24),
              _buildStatusText(),
              const SizedBox(height: 40),
              _buildProgressSteps(),
              const SizedBox(height: 40),
              _buildOrderSummary(),
              const Spacer(),
              if (_status == OrderStatus.ready) _buildReadyActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    String emoji;
    Color bg;
    switch (_status) {
      case OrderStatus.received:
        emoji = '📋'; bg = AppTheme.primaryLight;
      case OrderStatus.preparing:
        emoji = '👨‍🍳'; bg = AppTheme.warningLight;
      case OrderStatus.ready:
        emoji = '✅'; bg = AppTheme.successLight;
      case OrderStatus.served:
        emoji = '🍽'; bg = AppTheme.successLight;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 100, height: 100,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
    );
  }

  Widget _buildStatusText() {
    String title, subtitle;
    switch (_status) {
      case OrderStatus.received:
        title = 'Order Received!';
        subtitle = 'Your order has been sent to the kitchen.';
      case OrderStatus.preparing:
        title = 'Being Prepared';
        subtitle = 'Our chef is cooking your order right now.';
      case OrderStatus.ready:
        title = 'Ready to Serve! 🎉';
        subtitle = 'Your food is on the way to your table.';
      case OrderStatus.served:
        title = 'Enjoy your meal!';
        subtitle = 'Thank you for dining with Dine Touch.';
    }

    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {'label': 'Order Received', 'status': OrderStatus.received},
      {'label': 'Being Prepared', 'status': OrderStatus.preparing},
      {'label': 'Ready to Serve', 'status': OrderStatus.ready},
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final stepStatus = step['status'] as OrderStatus;
        final isDone = _step > i;
        final isActive = _step == i;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.success
                            : isActive
                                ? AppTheme.primary
                                : AppTheme.border,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Text('${i + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : AppTheme.textHint,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                )),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive || isDone ? AppTheme.textPrimary : AppTheme.textHint,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Container(
                  width: 32, height: 2,
                  color: isDone ? AppTheme.success : AppTheme.border,
                  margin: const EdgeInsets.only(bottom: 22),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.order.id, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'monospace')),
            Text('Table ${widget.order.tableNumber}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          ]),
          const SizedBox(height: 12),
          ...widget.order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${item.quantity}x ${item.menuItem.name}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                  Text('₱${item.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ]),
              )),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text('₱${widget.order.total.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildReadyActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MenuScreen()),
              (route) => false,
            ),
            child: const Text('Order More Items'),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
