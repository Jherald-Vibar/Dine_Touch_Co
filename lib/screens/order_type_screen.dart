import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';

class OrderTypeScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double total;
  const OrderTypeScreen({super.key, required this.cartItems, required this.total});

  @override
  State<OrderTypeScreen> createState() => _OrderTypeScreenState();
}

class _OrderTypeScreenState extends State<OrderTypeScreen> {
  String _orderType = 'dine_in';
  String _name = '';
  int? _tableNumber;

  @override
  void initState() {
    super.initState();
    _loadTableNumber();
  }

  Future<void> _loadTableNumber() async {
    final saved = await ApiService.getTableNumber();
    setState(() => _tableNumber = saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                _buildOption(
                  icon: Icons.restaurant,
                  title: 'Dine In',
                  subtitle: 'Enjoy your meal at the restaurant',
                  value: 'dine_in',
                ),
                const SizedBox(height: 12),
                _buildOption(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Take Out',
                  subtitle: 'Order packaged and ready to go',
                  value: 'take_out',
                ),
                const SizedBox(height: 28),

                _fieldLabel('Your Name (optional)'),
                const SizedBox(height: 8),
                _buildTextField('e.g. John', onChanged: (v) => _name = v),

                if (_orderType == 'dine_in') ...[
                  const SizedBox(height: 20),
                  _fieldLabel('Table Number'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary, width: 1.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.table_restaurant_outlined,
                          color: AppTheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _tableNumber != null ? 'Table $_tableNumber' : 'Loading...',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
          _buildFooter(context),
        ]),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3),
      );

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
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
        const Text('Order Type',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _orderType == value;
    return GestureDetector(
      onTap: () => setState(() => _orderType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: isSelected ? 1.5 : 0.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(13)),
            child: Icon(icon,
                color: isSelected ? const Color(0xFF0A0A0A) : AppTheme.textSecondary,
                size: 22),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
          const Spacer(),
          if (isSelected)
            Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Color(0xFF0A0A0A), size: 13),
            ),
        ]),
      ),
    );
  }

  Widget _buildTextField(String hint,
      {TextInputType? keyboardType, required Function(String) onChanged}) {
    return TextField(
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textHint),
        filled: true,
        fillColor: const Color(0xFF161616),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border, width: 0.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    cartItems: widget.cartItems,
                    total: widget.total,
                    orderType: _orderType,
                    customerName: _name,
                    tableNumber: _tableNumber,
                  ),
                )),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Next', style: TextStyle(fontSize: 15)),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 15),
            ]),
          ),
        ),
      ]),
    );
  }
}