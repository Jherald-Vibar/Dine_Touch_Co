import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import 'order_type_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context),
          Expanded(
            child: cart.isEmpty ? _buildEmpty(context) : _buildItemList(cart),
          ),
          if (!cart.isEmpty) _buildSummary(context, cart),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        const Text('Your Order',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const Spacer(),
        Consumer<CartProvider>(
          builder: (_, cart, __) => cart.isEmpty
              ? const SizedBox()
              : GestureDetector(
                  onTap: () => cart.clear(),
                  child: const Text('Remove all',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, decoration: TextDecoration.underline)),
                ),
        ),
      ]),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🛒', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('Your order is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Go back and add some items',
            style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse Menu')),
      ]),
    );
  }

  Widget _buildItemList(CartProvider cart) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = cart.items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text(_emoji(item.menuItem.category),
                      style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.menuItem.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('₱${item.menuItem.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 8),
            Row(children: [
              _QtyBtn(icon: Icons.remove, onTap: () => cart.decrementQuantity(item.menuItem.id)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${item.quantity}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              _QtyBtn(icon: Icons.add, onTap: () => cart.incrementQuantity(item.menuItem.id), filled: true),
            ]),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₱${item.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => cart.removeItem(item.menuItem.id),
                child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textHint),
              ),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cart) {
    final subtotal = cart.total;
    final tax = subtotal * 0.10;
    final total = subtotal + tax;
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text('₱${subtotal.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Tax (10%)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text('₱${tax.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text('₱${total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.arrow_back, size: 16, color: AppTheme.textSecondary),
                SizedBox(width: 6),
                Text('Menu', style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => OrderTypeScreen(cartItems: cart.items.toList(), total: total))),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Next', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16),
              ]),
            ),
          ),
        ]),
      ]),
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

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _QtyBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
            color: filled ? AppTheme.primary : AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: filled ? Colors.white : AppTheme.primary),
      ),
    );
  }
}