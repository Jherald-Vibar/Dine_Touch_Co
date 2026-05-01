import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'receipt_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double total;
  final String orderType;
  final String customerName;
  final int? tableNumber;
  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.total,
    required this.orderType,
    required this.customerName,
    this.tableNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _paymentMethod = 'cash';
  bool _isPlacing = false;

  final _methods = [
    {
      'value': 'cash',
      'label': 'Cash',
      'subtitle': 'Pay at the counter',
      'icon': Icons.payments_outlined,
    },
    {
      'value': 'card',
      'label': 'Card / Swipe',
      'subtitle': 'Swipe / Tap terminal',
      'icon': Icons.credit_card,
    },
    {
      'value': 'qr',
      'label': 'Online / QR',
      'subtitle': 'QR Code payment',
      'icon': Icons.qr_code_scanner_outlined,
    },
  ];

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    try {
      final items = widget.cartItems.map((i) => {
            'menu_item_id': i.menuItem.id,
            'name': i.menuItem.name,
            'unit_price': i.menuItem.price,
            'quantity': i.quantity,
            'special_request': i.specialRequest,
          }).toList();

      final result = await ApiService.placeOrder(items: items);
      final tableNumber =
          widget.tableNumber ?? await ApiService.getTableNumber();

      final order = Order(
        id: result['order']['id'] as String,
        tableNumber: tableNumber,
        items: widget.cartItems,
        total: widget.total,
      );

      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptScreen(
                order: order,
                orderType: widget.orderType,
                paymentMethod: _paymentMethod,
                customerName: widget.customerName,
              ),
            ));
      }
    } catch (e) {
      setState(() => _isPlacing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not place order: $e'),
          backgroundColor: Colors.red.shade800,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.total / 1.10;
    final tax = widget.total - subtotal;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ..._methods.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPaymentOption(m),
                    )),
                const SizedBox(height: 8),

                // Order total card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(children: [
                    _totalRow('Subtotal',
                        '₱${subtotal.toStringAsFixed(0)}',
                        dimValue: true),
                    const SizedBox(height: 8),
                    _totalRow('Tax (10%)',
                        '₱${tax.toStringAsFixed(0)}',
                        dimValue: true),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _totalRow('Total',
                        '₱${widget.total.toStringAsFixed(0)}',
                        highlight: true),
                  ]),
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ]),
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool highlight = false, bool dimValue = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              color: highlight
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
              fontSize: highlight ? 16 : 14,
              fontWeight:
                  highlight ? FontWeight.w700 : FontWeight.w400)),
      Text(value,
          style: TextStyle(
              color: highlight ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: highlight ? 17 : 14,
              fontWeight:
                  highlight ? FontWeight.w800 : FontWeight.w400)),
    ]);
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border, width: 0.5)),
            child: const Icon(Icons.arrow_back,
                color: AppTheme.textPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        const Text('Payment Method',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildPaymentOption(Map<String, dynamic> method) {
    final isSelected = _paymentMethod == method['value'];
    return GestureDetector(
      onTap: () =>
          setState(() => _paymentMethod = method['value'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: isSelected ? 1.5 : 0.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(method['icon'] as IconData,
                color: isSelected
                    ? const Color(0xFF0A0A0A)
                    : AppTheme.textSecondary,
                size: 20),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(method['label'] as String,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(method['subtitle'] as String,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ]),
          const Spacer(),
          if (isSelected)
            Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check,
                  color: Color(0xFF0A0A0A), size: 13),
            ),
        ]),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 15),
                  SizedBox(width: 6),
                  Text('Back'),
                ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isPlacing ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isPlacing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF0A0A0A)))
                : Text(
                    'Place Order · ₱${widget.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}