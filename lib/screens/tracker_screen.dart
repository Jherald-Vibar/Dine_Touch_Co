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

  final List<OrderStatus> _progression = [
    OrderStatus.received,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.served,
  ];

  final _steps = [
    {'label': 'Order Received', 'icon': Icons.access_time_outlined},
    {'label': 'Preparing', 'icon': Icons.soup_kitchen_outlined},
    {'label': 'Ready!', 'icon': Icons.notifications_outlined},
    {'label': 'Completed', 'icon': Icons.check_circle_outline},
  ];

  @override
  void initState() {
    super.initState();
    _status = OrderStatus.received;
    _startSimulation();
  }

  void _startSimulation() {
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
    final shortId = widget.order.id.substring(0, 8).toUpperCase();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            color: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text('ORD-$shortId',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1),
                textAlign: TextAlign.center),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _buildStatusCard(),
                const SizedBox(height: 20),
                _buildStepsList(),
                const SizedBox(height: 20),
                _buildOrderSummary(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const MenuScreen()), (r) => false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add, size: 16, color: AppTheme.textSecondary),
                      SizedBox(width: 6),
                      Text('Place Another Order', style: TextStyle(color: AppTheme.textSecondary)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatusCard() {
    String title, subtitle;
    Color bgColor;
    IconData iconData;

    switch (_status) {
      case OrderStatus.received:
        title = 'Pending'; subtitle = 'Estimated Time: 20-25 min';
        bgColor = AppTheme.primaryLight; iconData = Icons.receipt_long_outlined;
      case OrderStatus.preparing:
        title = 'Preparing'; subtitle = 'Estimated Time: 10-15 min';
        bgColor = AppTheme.warningLight; iconData = Icons.soup_kitchen_outlined;
      case OrderStatus.ready:
        title = 'Ready!'; subtitle = 'Your food is on its way';
        bgColor = AppTheme.successLight; iconData = Icons.check_circle_outline;
      case OrderStatus.served:
        title = 'Completed'; subtitle = 'Enjoy your meal!';
        bgColor = AppTheme.successLight; iconData = Icons.check_circle_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
          child: Icon(iconData, size: 36, color: AppTheme.primary),
        ),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ]),
    );
  }

  Widget _buildStepsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: _steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isDone = _step > i;
          final isActive = _step == i;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.success : isActive ? AppTheme.primary : AppTheme.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(step['icon'] as IconData,
                    size: 18,
                    color: isDone || isActive ? Colors.white : AppTheme.textHint),
              ),
              const SizedBox(width: 14),
              Text(step['label'] as String,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isDone || isActive ? AppTheme.textPrimary : AppTheme.textHint)),
              const Spacer(),
              if (isActive)
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                ),
              if (isDone)
                const Icon(Icons.check, size: 16, color: AppTheme.success),
            ]),
          );
        }).toList(),
      ),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Order Summary',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...widget.order.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${item.quantity}× ${item.menuItem.name}',
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
      ]),
    );
  }
}