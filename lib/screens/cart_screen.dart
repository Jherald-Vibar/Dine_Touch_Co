import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import 'tracker_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Your Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cart.isEmpty
          ? _buildEmpty(context)
          : Column(
              children: [
                Expanded(child: _buildItemList(context, cart)),
                _buildSummary(context, cart),
              ],
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Your order is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Go back and add some items', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context, CartProvider cart) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = cart.items[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(_emoji(item.menuItem.category), style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.menuItem.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      if (item.specialRequest.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('📝 ${item.specialRequest}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                        ),
                      const SizedBox(height: 4),
                      Text('₱${item.menuItem.price.toStringAsFixed(0)} each',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₱${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _SmallBtn(icon: Icons.remove, onTap: () => cart.decrementQuantity(item.menuItem.id)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                        _SmallBtn(icon: Icons.add, onTap: () => cart.incrementQuantity(item.menuItem.id), filled: true),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cart) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Items', style: TextStyle(color: AppTheme.textSecondary)),
            Text('${cart.itemCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary)),
            Text('₱${cart.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('₱${cart.total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _placeOrder(context, cart),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Place Order  →', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _placeOrder(BuildContext context, CartProvider cart) {
    // Create order object
    final order = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      tableNumber: cart.tableNumber,
      items: List.from(cart.items),
      total: cart.total,
    );

    // In production: POST to your API here
    // ApiService.createOrder(order);

    cart.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TrackerScreen(order: order)),
    );
  }

  String _emoji(String category) {
    switch (category) {
      case 'Mains': return '🍲';
      case 'Rice & Sides': return '🍚';
      case 'Drinks': return '🥤';
      case 'Desserts': return '🍮';
      default: return '🍽';
    }
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _SmallBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: filled ? AppTheme.primary : AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 14, color: filled ? Colors.white : AppTheme.primary),
      ),
    );
  }
}
