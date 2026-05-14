import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'receipt_screen.dart';

// ─── Discount Model ───────────────────────────────────────────────────────────

class DiscountInfo {
  final String type; // 'senior' | 'pwd' | 'promo' | 'percentage' | 'fixed'
  final String label;
  final double amount;
  final bool vatExempt;

  const DiscountInfo({
    required this.type,
    required this.label,
    required this.amount,
    this.vatExempt = false,
  });

  /// Senior Citizen – 20% off + VAT exempt (PH Law RA 9994)
  factory DiscountInfo.senior(double subtotal) {
    final discount = subtotal * 0.20;
    return DiscountInfo(
      type: 'senior',
      label: 'Senior Citizen (20%)',
      amount: discount,
      vatExempt: true,
    );
  }

  /// PWD – 20% off + VAT exempt (PH Law RA 9442)
  factory DiscountInfo.pwd(double subtotal) {
    final discount = subtotal * 0.20;
    return DiscountInfo(
      type: 'pwd',
      label: 'PWD Discount (20%)',
      amount: discount,
      vatExempt: true,
    );
  }

  /// Promo code – fixed amount
  factory DiscountInfo.promoFixed(String code, double amount) {
    return DiscountInfo(
      type: 'promo',
      label: 'Promo: $code',
      amount: amount,
    );
  }

  /// Promo code – percentage
  factory DiscountInfo.promoPercent(String code, double percent, double subtotal) {
    return DiscountInfo(
      type: 'promo',
      label: 'Promo: $code (${percent.toInt()}%)',
      amount: subtotal * (percent / 100),
    );
  }
}

// ─── Payment Screen ───────────────────────────────────────────────────────────

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
  DiscountInfo? _discount;

  final _amountController = TextEditingController();
  final _refController = TextEditingController();

  // ── Valid promo codes (replace with API call in production) ──────────────
  static const _promoCodes = <String, Map<String, dynamic>>{
    'SAVE50':  {'type': 'fixed',   'value': 50.0},
    'OFF10':   {'type': 'percent', 'value': 10.0},
    'WELCOME': {'type': 'percent', 'value': 15.0},
  };

  // ── Computed totals ───────────────────────────────────────────────────────

  double get _rawSubtotal => widget.total / 1.10;
  double get _rawVat => widget.total - _rawSubtotal;
  double get _discountAmount => _discount?.amount ?? 0.0;
  double get _finalTotal => (widget.total - _discountAmount).clamp(0, double.infinity);
  double get _displaySubtotal =>
      (_discount?.vatExempt ?? false) ? _finalTotal : _finalTotal / 1.10;
  double get _displayVat =>
      (_discount?.vatExempt ?? false) ? 0.0 : _finalTotal - _displaySubtotal;

  // ── Payment methods ───────────────────────────────────────────────────────

  final _methods = [
    {
      'value': 'cash',
      'label': 'Cash',
      'subtitle': 'Pay at the counter',
      'icon': Icons.payments_outlined,
    },
    {
      'value': 'card',
      'label': 'Credit / Debit Card',
      'subtitle': 'Enter card details',
      'icon': Icons.credit_card,
    },
    {
      'value': 'qr',
      'label': 'GCash / E-wallet',
      'subtitle': 'GCash · Maya',
      'icon': Icons.account_balance_wallet_outlined,
    },
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Discount logic
  // ─────────────────────────────────────────────────────────────────────────

  void _showDiscountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiscountSheet(
        rawTotal: widget.total,
        promoCodes: _promoCodes,
        onApply: (discount) {
          setState(() => _discount = discount);
          Navigator.pop(context);
        },
        onRemove: () {
          setState(() => _discount = null);
          Navigator.pop(context);
        },
        current: _discount,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Order placement
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    final amountTendered = _paymentMethod == 'cash'
        ? double.tryParse(_amountController.text)
        : _finalTotal;

    if (_paymentMethod == 'cash' &&
        (amountTendered == null || amountTendered < _finalTotal)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Invalid amount tendered'),
        backgroundColor: Colors.red.shade800,
      ));
      return;
    }

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

      final result = await ApiService.placeOrder(
        items: items,
        customerName: widget.customerName,
        orderType: widget.orderType,
        tableNumber: widget.tableNumber,
        paymentMethod: _paymentMethod,
        amountTendered: amountTendered,
        discountType: _discount?.type,
        discountAmount: _discountAmount,
      );

      final tableNumber =
          widget.tableNumber ?? await ApiService.getTableNumber();

      final order = Order(
        id: result['order']['id'] as String,
        tableNumber: tableNumber,
        items: widget.cartItems,
        total: _finalTotal,
        paymentMethod: _paymentMethod,
        amountTendered: amountTendered,
        discountInfo: _discount,
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
          ),
        );
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

  // ─────────────────────────────────────────────────────────────────────────
  // QR / Card modals
  // ─────────────────────────────────────────────────────────────────────────

  void _showQrModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrPaymentModal(total: _finalTotal),
    );
    _placeOrder();
  }

  void _showCardDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            const SizedBox(height: 20),
            const Text('Enter Card Details',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _buildTextField('Card Number', TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildTextField('Expiry (MM/YY)', TextInputType.datetime)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('CVV', TextInputType.number)),
              ],
            ),
            const SizedBox(height: 20),
            _primaryButton('Next', () {
              Navigator.pop(context);
              _showOtpModal();
            }),
          ],
        ),
      ),
    );
  }

  void _showOtpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            const SizedBox(height: 20),
            const Text('Enter OTP',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('A simulated OTP has been sent to your phone.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            _buildTextField('OTP', TextInputType.number),
            const SizedBox(height: 20),
            _primaryButton('Verify & Done', () {
              Navigator.pop(context);
              _placeOrder();
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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

                // ── Discount button ──────────────────────────────────────
                GestureDetector(
                  onTap: _showDiscountSheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _discount != null
                          ? AppTheme.success.withOpacity(0.08)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _discount != null
                            ? AppTheme.success.withOpacity(0.5)
                            : AppTheme.border,
                        width: _discount != null ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _discount != null
                              ? AppTheme.success.withOpacity(0.15)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _discount != null
                              ? Icons.discount_rounded
                              : Icons.local_offer_outlined,
                          color: _discount != null
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _discount != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_discount!.label,
                                      style: const TextStyle(
                                          color: AppTheme.success,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                      '-₱${_discount!.amount.toStringAsFixed(0)} applied',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12)),
                                ],
                              )
                            : const Text('Apply Discount / Promo',
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                      ),
                      Icon(
                        _discount != null
                            ? Icons.edit_outlined
                            : Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Order total card ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(children: [
                    _totalRow('Subtotal',
                        '₱${_rawSubtotal.toStringAsFixed(0)}',
                        dimValue: true),
                    const SizedBox(height: 8),
                    _totalRow('Tax (10%)',
                        '₱${_rawVat.toStringAsFixed(0)}',
                        dimValue: true),

                    if (_discount != null) ...[
                      const SizedBox(height: 8),
                      _totalRow(
                        _discount!.label,
                        '-₱${_discountAmount.toStringAsFixed(0)}',
                        isDiscount: true,
                      ),
                      if (_discount!.vatExempt) ...[
                        const SizedBox(height: 4),
                        _totalRow('VAT Exemption',
                            '-₱${_displayVat == 0 ? _rawVat.toStringAsFixed(0) : "0"}',
                            isDiscount: true),
                      ],
                    ],

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _totalRow('Total',
                        '₱${_finalTotal.toStringAsFixed(0)}',
                        highlight: true),

                    if (_discount?.vatExempt ?? false) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_outlined,
                                color: AppTheme.success, size: 13),
                            SizedBox(width: 5),
                            Text('VAT Exempt – ID verification required',
                                style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ]),
                ),

                const SizedBox(height: 16),

                // ── Cash / QR fields ──────────────────────────────────────
                if (_paymentMethod == 'cash') ...[
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Amount Tendered',
                      labelStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      prefixText: '₱',
                      prefixStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (double.tryParse(_amountController.text) != null &&
                      double.parse(_amountController.text) >= _finalTotal)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Change',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14)),
                          Text(
                            '₱${(double.parse(_amountController.text) - _finalTotal).toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppTheme.success,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                ] else if (_paymentMethod == 'qr') ...[
                  TextField(
                    controller: _refController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Reference Number',
                      labelStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _totalRow(
    String label,
    String value, {
    bool highlight = false,
    bool dimValue = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isDiscount
                    ? AppTheme.success
                    : highlight
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                fontSize: highlight ? 16 : 14,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w400)),
        Text(value,
            style: TextStyle(
                color: isDiscount
                    ? AppTheme.success
                    : highlight
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                fontSize: highlight ? 17 : 14,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w400)),
      ],
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
                border:
                    Border.all(color: AppTheme.border, width: 0.5)),
            child: const Icon(Icons.arrow_back,
                color: AppTheme.textPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        const Text('Payment',
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
        if (method['value'] == 'card') _showCardDetailsModal();
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF0A0A0A)))
                : Text(
                    'Place Order · ₱${_finalTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  Widget _buildDragHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildTextField(String label, TextInputType type) => TextField(
        style: const TextStyle(color: Colors.white),
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _primaryButton(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          child: Text(label),
        ),
      );
}

// ─── Discount Bottom Sheet ────────────────────────────────────────────────────

class _DiscountSheet extends StatefulWidget {
  final double rawTotal;
  final Map<String, Map<String, dynamic>> promoCodes;
  final ValueChanged<DiscountInfo> onApply;
  final VoidCallback onRemove;
  final DiscountInfo? current;

  const _DiscountSheet({
    required this.rawTotal,
    required this.promoCodes,
    required this.onApply,
    required this.onRemove,
    this.current,
  });

  @override
  State<_DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<_DiscountSheet> {
  // ── Hardcoded staff PINs ─────────────────────────────────────────────────
  // Change these values to your desired PINs
  static const _seniorPinBase = 'SENRDSCNTDN-T-CO';
  static const _pwdPinBase = 'PWDDSCNTDN-T-CO';

  static String get _seniorPin => '$_seniorPinBase${DateTime.now().day}';
  static String get _pwdPin => '$_pwdPinBase${DateTime.now().day}';

  final _promoController = TextEditingController();
  final _pinController = TextEditingController();

  String? _promoError;
  String? _pinError;
  String? _selectedType; // 'senior' | 'pwd' | 'promo'

  @override
  void initState() {
    super.initState();
    _selectedType = widget.current?.type;
  }

  @override
  void dispose() {
    _promoController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ── PIN verification ─────────────────────────────────────────────────────

  void _verifyPin() {
    final entered = _pinController.text.trim();
    final correct = _selectedType == 'senior' ? _seniorPin : _pwdPin;

    if (entered != correct) {
      setState(() => _pinError = 'Incorrect PIN. Please ask staff.');
      _pinController.clear();
      return;
    }

    final discount = _selectedType == 'senior'
        ? DiscountInfo.senior(widget.rawTotal)
        : DiscountInfo.pwd(widget.rawTotal);

    widget.onApply(discount);
  }

  // ── Promo verification ────────────────────────────────────────────────────

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    final promo = widget.promoCodes[code];
    if (promo == null) {
      setState(() => _promoError = 'Invalid promo code');
      return;
    }

    DiscountInfo discount;
    if (promo['type'] == 'fixed') {
      discount = DiscountInfo.promoFixed(code, promo['value'] as double);
    } else {
      discount = DiscountInfo.promoPercent(
          code, promo['value'] as double, widget.rawTotal);
    }
    widget.onApply(discount);
  }

  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDiscountOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = isSelected ? null : type;
          _pinError = null;
          _promoError = null;
          _pinController.clear();
          _promoController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.10)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF2A2A2A),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.15)
                  : const Color(0xFF222222),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isSelected ? color : const Color(0xFF555555),
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: isSelected ? color : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: Color(0xFF666666), fontSize: 12)),
            ]),
          ),
          if (isSelected)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.black, size: 13),
            ),
        ]),
      ),
    );
  }

  // ── PIN input widget ─────────────────────────────────────────────────────

  Widget _buildPinEntry(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.lock_outline_rounded,
                    color: accentColor, size: 15),
                const SizedBox(width: 6),
                Text(
                  'Ask staff for the PIN to apply this discount',
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 50,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        letterSpacing: 10,
                        fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      hintStyle: TextStyle(
                          color: const Color(0xFF444444),
                          fontSize: 24,
                          letterSpacing: 10),
                      errorText: _pinError,
                      errorStyle: const TextStyle(fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: accentColor),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    onChanged: (_) => setState(() => _pinError = null),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Verify',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Apply Discount',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            if (widget.current != null)
              GestureDetector(
                onTap: widget.onRemove,
                child: const Text('Remove',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
          ]),

          const SizedBox(height: 4),
          const Text(
            'Select a discount type or enter a promo code.',
            style: TextStyle(color: Color(0xFF666666), fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── Senior Citizen ─────────────────────────────────────────
          _buildDiscountOption(
            type: 'senior',
            title: 'Senior Citizen',
            subtitle: '20% off + VAT exempt (RA 9994) · Staff PIN required',
            icon: Icons.elderly_rounded,
            color: const Color(0xFFFFB74D),
          ),
          if (_selectedType == 'senior')
            _buildPinEntry(const Color(0xFFFFB74D)),

          const SizedBox(height: 10),

          // ── PWD ────────────────────────────────────────────────────
          _buildDiscountOption(
            type: 'pwd',
            title: 'PWD (Person with Disability)',
            subtitle: '20% off + VAT exempt (RA 9442) · Staff PIN required',
            icon: Icons.accessible_rounded,
            color: const Color(0xFF64B5F6),
          ),
          if (_selectedType == 'pwd')
            _buildPinEntry(const Color(0xFF64B5F6)),

          const SizedBox(height: 10),

          // ── Promo Code ─────────────────────────────────────────────
          _buildDiscountOption(
            type: 'promo',
            title: 'Promo Code',
            subtitle: 'Enter a valid discount code',
            icon: Icons.confirmation_number_outlined,
            color: AppTheme.primary,
          ),
          if (_selectedType == 'promo') ...[
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. SAVE50',
                    hintStyle: const TextStyle(
                        color: Color(0xFF444444), letterSpacing: 1),
                    errorText: _promoError,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF2A2A2A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                  onChanged: (_) => setState(() => _promoError = null),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _applyPromo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply'),
              ),
            ]),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── QR Payment Modal ─────────────────────────────────────────────────────────

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
      name: 'Maya',
      color: Color(0xFF00B87A),
      icon: Icons.account_balance_wallet_outlined,
      qrAsset: 'assets/qr/maya_qr.png',
      instructions: 'Open Maya → Scan QR',
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
                        color: isActive ? p.color : const Color(0xFF2A2A2A),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Icon(p.icon,
                          color: isActive ? p.color : const Color(0xFF555555),
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
            child: Icon(provider.icon, color: provider.color, size: 18),
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