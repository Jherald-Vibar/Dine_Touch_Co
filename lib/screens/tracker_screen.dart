import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class TrackerScreen extends StatelessWidget {
  final String orderId;
  final String shortId;

  const TrackerScreen({
    super.key,
    required this.orderId,
    required this.shortId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>?>(
              stream: SupabaseService.watchOrder(orderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                final order = snapshot.data;
                final status = order?['status'] as String? ?? 'pending';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const SizedBox(height: 12),
                    _buildStatusIcon(status),
                    const SizedBox(height: 16),
                    Text(
                      _statusTitle(status),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _statusColor(status)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _statusSubtitle(status),
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Order ref
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        'ORD-$shortId',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            letterSpacing: 1.5),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Timeline
                    _buildTimeline(status),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border:
            Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border, width: 0.5)),
            child: const Icon(Icons.arrow_back,
                color: AppTheme.textPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        const Text('Order Status',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildStatusIcon(String status) {
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 38),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final steps = [
      _Step('pending', 'Order Received',
          'Your order has been placed successfully.', Icons.receipt_outlined),
      _Step('preparing', 'Being Prepared',
          'The kitchen is working on your order.', Icons.soup_kitchen_outlined),
      _Step('ready', 'Ready to Serve',
          'Your order is ready! A server will bring it shortly.',
          Icons.check_circle_outline),
      _Step('served', 'Served',
          'Enjoy your meal! Thank you for dining with us.', Icons.dinner_dining),
    ];

    final currentIndex = _statusIndex(currentStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isDone = i <= currentIndex;
          final isCurrent = i == currentIndex;
          final isLast = i == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: dot + line
              Column(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.primary
                        : const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone
                          ? AppTheme.primary
                          : const Color(0xFF2A2A2A),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    isDone ? Icons.check : step.icon,
                    size: 15,
                    color: isDone
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xFF444444),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isDone && i < currentIndex
                        ? AppTheme.primary
                        : const Color(0xFF2A2A2A),
                  ),
              ]),

              const SizedBox(width: 16),

              // Right: text
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: isLast ? 0 : 28, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDone
                              ? AppTheme.primary
                              : const Color(0xFF444444),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 4),
                        Text(
                          step.subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  int _statusIndex(String status) {
    switch (status) {
      case 'pending': return 0;
      case 'preparing': return 1;
      case 'ready': return 2;
      case 'served': return 3;
      default: return 0;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFD4AF6A);
      case 'preparing': return const Color(0xFF3B82F6);
      case 'ready': return const Color(0xFF22C55E);
      case 'served': return const Color(0xFF22C55E);
      default: return AppTheme.primary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.receipt_outlined;
      case 'preparing': return Icons.soup_kitchen_outlined;
      case 'ready': return Icons.check_circle_outline;
      case 'served': return Icons.dinner_dining;
      default: return Icons.receipt_outlined;
    }
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'pending': return 'Order Received';
      case 'preparing': return 'Being Prepared';
      case 'ready': return 'Ready to Serve!';
      case 'served': return 'Served';
      default: return 'Order Received';
    }
  }

  String _statusSubtitle(String status) {
    switch (status) {
      case 'pending': return 'Waiting for the kitchen to start.';
      case 'preparing': return 'The kitchen is on it!';
      case 'ready': return 'A server will bring it to your table shortly.';
      case 'served': return 'Enjoy your meal!';
      default: return '';
    }
  }
}

class _Step {
  final String status;
  final String title;
  final String subtitle;
  final IconData icon;
  const _Step(this.status, this.title, this.subtitle, this.icon);
}