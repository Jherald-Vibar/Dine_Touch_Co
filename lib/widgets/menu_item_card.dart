import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(item.id);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Image / Emoji area ──
              SizedBox(
                height: 80,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildImage(),
                ),
              ),
              const SizedBox(height: 7),

              // Tags
              if (item.tags.isNotEmpty) ...[
                _Tag(item.tags.first),
                const SizedBox(height: 5),
              ],

              // Name
              Text(
                item.name,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // Description
              Text(
                item.description,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHint,
                    height: 1.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Expanded(child: SizedBox()),

              // Price + controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₱${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary),
                  ),
                  qty == 0
                      ? _AddButton(onTap: () => cart.addItem(item))
                      : _QtyControl(
                          qty: qty,
                          onIncrement: () => cart.incrementQuantity(item.id),
                          onDecrement: () => cart.decrementQuantity(item.id),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    debugPrint('MenuItemCard imageUrl = "${item.imageUrl}"');

    // Empty — show emoji
    if (item.imageUrl.isEmpty) {
      return _emojiPlaceholder();
    }

    // Remote URL
    if (item.imageUrl.startsWith('http')) {
      return Image.network(
        item.imageUrl,
        width: double.infinity,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, error, __) {
          debugPrint('Network image error: $error');
          return _emojiPlaceholder();
        },
      );
    }

    // Local asset
    return Image.asset(
      item.imageUrl,
      width: double.infinity,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, error, __) {
        debugPrint('Asset image error: $error');
        return _emojiPlaceholder();
      },
    );
  }

  Widget _emojiPlaceholder() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        border: Border.all(
            color: AppTheme.primary.withOpacity(0.15), width: 1),
      ),
      child: Center(
        child: Text(
          _foodEmoji(item.category),
          style: const TextStyle(fontSize: 34),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final cart = context.read<CartProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(item: item, cart: cart),
    );
  }

  String _foodEmoji(String category) {
    switch (category) {
      case 'Mains':
        return '🍲';
      case 'Rice & Sides':
        return '🍚';
      case 'Drinks':
        return '🥤';
      case 'Desserts':
        return '🍮';
      default:
        return '🍽';
    }
  }
}

// ── Tag ───────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);
  @override
  Widget build(BuildContext context) {
    final isHot = label == 'spicy';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isHot
            ? AppTheme.warning.withOpacity(0.12)
            : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: isHot
                ? AppTheme.warning.withOpacity(0.3)
                : AppTheme.primary.withOpacity(0.2)),
      ),
      child: Text(
        isHot ? '🌶 spicy' : '⭐ $label',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isHot ? AppTheme.warning : AppTheme.primary),
      ),
    );
  }
}

// ── Add Button ────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.add, color: Color(0xFF0A0A0A), size: 16),
        ),
      );
}

// ── Qty Control ───────────────────────────────────────────────
class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onIncrement, onDecrement;
  const _QtyControl(
      {required this.qty,
      required this.onIncrement,
      required this.onDecrement});
  @override
  Widget build(BuildContext context) => Row(children: [
        _CircleBtn(icon: Icons.remove, onTap: onDecrement, filled: false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('$qty',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
        ),
        _CircleBtn(icon: Icons.add, onTap: onIncrement, filled: true),
      ]);
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _CircleBtn(
      {required this.icon, required this.onTap, required this.filled});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
              color: filled ? AppTheme.primary : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(7),
              border: filled
                  ? null
                  : Border.all(color: AppTheme.primary.withOpacity(0.3))),
          child: Icon(icon,
              size: 13,
              color: filled ? const Color(0xFF0A0A0A) : AppTheme.primary),
        ),
      );
}

// ── Item Detail Bottom Sheet ──────────────────────────────────
class _ItemDetailSheet extends StatefulWidget {
  final MenuItem item;
  final CartProvider cart;
  const _ItemDetailSheet({required this.item, required this.cart});
  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // ── Detail image ──
          SizedBox(
            height: 150,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildDetailImage(),
            ),
          ),
          const SizedBox(height: 16),

          // Name + price
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(widget.item.name,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ),
                Text('₱${widget.item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
              ]),
          const SizedBox(height: 8),

          // Description
          Text(widget.item.description,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5)),
          const SizedBox(height: 16),

          // Special request
          TextField(
            controller: _controller,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Special request (e.g. less spicy, no onions)',
              hintStyle: const TextStyle(
                  fontSize: 13, color: AppTheme.textHint),
              filled: true,
              fillColor: const Color(0xFF161616),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppTheme.border, width: 0.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppTheme.border, width: 0.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppTheme.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Add to order button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.cart.addItem(widget.item);
                if (_controller.text.isNotEmpty) {
                  widget.cart.setSpecialRequest(
                      widget.item.id, _controller.text);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${widget.item.name} added to order'),
                  backgroundColor: AppTheme.success,
                  duration: const Duration(seconds: 1),
                ));
              },
              child: const Text('Add to Order'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDetailImage() {
    final imageUrl = widget.item.imageUrl;

    if (imageUrl.isEmpty) return _detailEmojiPlaceholder();

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _detailEmojiPlaceholder(),
      );
    }

    return Image.asset(
      imageUrl,
      width: double.infinity,
      height: 150,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _detailEmojiPlaceholder(),
    );
  }

  Widget _detailEmojiPlaceholder() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(_foodEmoji(widget.item.category),
            style: const TextStyle(fontSize: 68)),
      ),
    );
  }

  String _foodEmoji(String category) {
    switch (category) {
      case 'Mains':
        return '🍲';
      case 'Rice & Sides':
        return '🍚';
      case 'Drinks':
        return '🥤';
      case 'Desserts':
        return '🍮';
      default:
        return '🍽';
    }
  }
}