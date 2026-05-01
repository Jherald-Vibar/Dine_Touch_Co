import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'menu_screen.dart';

class ReceiptScreen extends StatefulWidget {
  final Order order;
  final String orderType;
  final String paymentMethod;
  final String customerName;

  const ReceiptScreen({
    super.key,
    required this.order,
    required this.orderType,
    required this.paymentMethod,
    required this.customerName,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isPrinting = false;

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.read<CartProvider>().clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (route) => false,
    );
  }

  void _placeAnotherOrder() {
    context.read<CartProvider>().clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortId = widget.order.id.substring(0, 8).toUpperCase();
    final now = DateTime.now();
    final dateStr = '${_month(now.month)} ${now.day}, ${now.year} · ${_time(now)}';
    final trackingUrl = 'https://yourapp.com/track/${widget.order.id}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.success.withOpacity(0.4), width: 1.5),
                      ),
                      child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text('Order Placed!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.success)),
                    const SizedBox(height: 4),
                    const Text('Thank You!',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),

                    // Receipt card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border, width: 0.5),
                      ),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(7)),
                              child: const Center(child: Text('DT', style: TextStyle(color: Color(0xFF0A0A0A), fontSize: 10, fontWeight: FontWeight.w900))),
                            ),
                            const SizedBox(width: 10),
                            const Text('Dine Touch',
                                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
                            const Spacer(),
                            Text(dateStr, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(children: [
                            Text('ORD-$shortId',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            const Text('Order Reference',
                                style: TextStyle(fontSize: 11, color: AppTheme.textHint, letterSpacing: 0.5)),
                            const SizedBox(height: 16),
                            if (widget.customerName.isNotEmpty) ...[
                              Text(widget.customerName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                              const SizedBox(height: 14),
                            ],
                            Row(children: [
                              Expanded(child: _InfoBox(label: 'Type', value: widget.orderType == 'dine_in' ? 'Dine In' : 'Take Out')),
                              const SizedBox(width: 12),
                              Expanded(child: _InfoBox(label: 'Payment', value: _paymentLabel(widget.paymentMethod))),
                            ]),
                            const SizedBox(height: 18),
                            ...widget.order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Row(children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(6)),
                                    child: Center(child: Text('${item.quantity}',
                                        style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w800))),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(item.menuItem.name, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                                ]),
                                Text('₱${item.subtotal.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              ]),
                            )),
                            const Divider(height: 20),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                              Text('₱${widget.order.total.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                            ]),
                          ]),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // QR card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border, width: 0.5),
                      ),
                      child: Column(children: [
                        const Text('Track Your Order',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        const SizedBox(height: 6),
                        const Text('Scan to see live order status on your phone',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
                            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.12), blurRadius: 20)],
                          ),
                          child: QrImageView(
                            data: trackingUrl,
                            version: QrVersions.auto,
                            size: 160,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A1A1A)),
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1A1A)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                          ),
                          child: Text(trackingUrl,
                              style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontFamily: 'monospace')),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),
                    const Text('Thank you for dining with us! 🙏',
                        style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _printReceipt,
                    icon: _isPrinting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0A0A)))
                        : const Icon(Icons.print_outlined, size: 18),
                    label: Text(_isPrinting ? 'Printing…' : 'Print Receipt',
                        style: const TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: const Color(0xFF0A0A0A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isPrinting ? null : _placeAnotherOrder,
                    icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                    label: const Text('Place Another Order', style: TextStyle(fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash': return 'Cash';
      case 'card': return 'Card';
      case 'qr':   return 'Online/QR';
      default:     return method;
    }
  }

  String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  String _time(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ]),
    );
  }
}