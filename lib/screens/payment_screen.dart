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
      'subtitle': 'GCash · GoTyme · Stripe',
      'icon': Icons.qr_code_scanner_outlined,
    },
  ];

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    try {
      final items = widget.cartItems
          .map((i) => {
                'menu_item_id': i.menuItem.id,
                'name': i.menuItem.name,
                'unit_price': i.menuItem.price,
                'quantity': i.quantity,
                'special_request': i.specialRequest,
              })
          .toList();

      // ── FIX: pass customerName, orderType, tableNumber to placeOrder ──
      final result = await ApiService.placeOrder(
        items: items,
        customerName: widget.customerName,
        orderType: widget.orderType,
        tableNumber: widget.tableNumber,
      );

      // Use the table number from widget first, fall back to session
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

  void _showQrModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrPaymentModal(total: widget.total),
    );
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
                    border:
                        Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(children: [
                    _totalRow('Subtotal',
                        '₱${subtotal.toStringAsFixed(0)}',
                        dimValue: true),
                    const SizedBox(height: 8),
                    _totalRow(
                        'Tax (10%)', '₱${tax.toStringAsFixed(0)}',
                        dimValue: true),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _totalRow('Total',
                        '₱${widget.total.toStringAsFixed(0)}',
                        highlight: true),
                  ]),
                ),

                if (_paymentMethod == 'qr') ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showQrModal,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.4),
                            width: 1.2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              color: AppTheme.primary, size: 20),
                          SizedBox(width: 8),
                          Text('View QR Codes',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
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
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: highlight
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: highlight ? 16 : 14,
                  fontWeight: highlight
                      ? FontWeight.w700
                      : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  color: highlight
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontSize: highlight ? 17 : 14,
                  fontWeight: highlight
                      ? FontWeight.w800
                      : FontWeight.w400)),
        ]);
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
            bottom: BorderSide(color: AppTheme.border, width: 0.5)),
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
    final isQr = method['value'] == 'qr';
    return GestureDetector(
      onTap: () {
        setState(() => _paymentMethod = method['value'] as String);
        if (isQr) _showQrModal();
      },
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
            width: 46,
            height: 46,
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
          if (isSelected && !isQr)
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check,
                  color: Color(0xFF0A0A0A), size: 13),
            ),
          if (isQr)
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 20),
        ]),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border:
            Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
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
                    width: 20,
                    height: 20,
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

// ─── QR Payment Modal ────────────────────────────────────────────────────────

class _QrPaymentModal extends StatefulWidget {
  final double total;
  const _QrPaymentModal({required this.total});

  @override
  State<_QrPaymentModal> createState() => _QrPaymentModalState();
}

class _QrPaymentModalState extends State<_QrPaymentModal> {
  int _selectedIndex = 0;

  final _providers = [
    const _QrProvider(
      name: 'GCash',
      color: Color(0xFF007DFE),
      icon: Icons.account_balance_wallet_outlined,
      qrAsset: 'assets/qr/gcash_qr.png',
      instructions: 'Open GCash → QR → Scan to pay',
    ),
    const _QrProvider(
      name: 'GoTyme',
      color: Color(0xFF00B87A),
      icon: Icons.savings_outlined,
      qrAsset: 'assets/qr/gotyme_qr.png',
      instructions: 'Open GoTyme Bank → Pay → Scan QR',
    ),
    const _QrProvider(
      name: 'Stripe',
      color: Color(0xFF6772E5),
      icon: Icons.credit_score_outlined,
      qrAsset: 'assets/qr/stripe_qr.png',
      instructions: 'Scan with your camera or banking app',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = _providers[_selectedIndex];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Scan to Pay',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('₱${widget.total.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Row(
            children: List.generate(_providers.length, (i) {
              final p = _providers[i];
              final isActive = _selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                        right: i < _providers.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? p.color.withOpacity(0.15)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? p.color
                            : const Color(0xFF2A2A2A),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Icon(p.icon,
                          color: isActive
                              ? p.color
                              : const Color(0xFF555555),
                          size: 20),
                      const SizedBox(height: 4),
                      Text(p.name,
                          style: TextStyle(
                              color: isActive
                                  ? p.color
                                  : const Color(0xFF555555),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildQrCard(provider),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  color: provider.color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(provider.instructions,
                    style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        height: 1.4)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(_QrProvider provider) {
    return Container(
      key: ValueKey(provider.name),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: provider.color.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: provider.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(provider.icon, color: provider.color, size: 18),
          ),
          const SizedBox(width: 8),
          Text(provider.name,
              style: TextStyle(
                  color: provider.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: provider.color.withOpacity(0.2), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              provider.qrAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        color: provider.color, size: 80),
                    const SizedBox(height: 8),
                    Text('Add QR to\nassets/qr/',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: provider.color.withOpacity(0.6),
                            fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _QrProvider {
  final String name;
  final Color color;
  final IconData icon;
  final String qrAsset;
  final String instructions;

  const _QrProvider({
    required this.name,
    required this.color,
    required this.icon,
    required this.qrAsset,
    required this.instructions,
  });
}