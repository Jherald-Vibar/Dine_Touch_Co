import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;
  String specialRequest;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialRequest = '',
  });

  double get subtotal => menuItem.price * quantity;

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItem.id,
        'name': menuItem.name,
        'price': menuItem.price,
        'quantity': quantity,
        'subtotal': subtotal,
        'special_request': specialRequest,
      };
}

enum OrderStatus { received, preparing, ready, served }

class Order {
  final String id;
  final int tableNumber;
  final List<CartItem> items;
  final double total;
  OrderStatus status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.total,
    this.status = OrderStatus.received,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get statusLabel {
    switch (status) {
      case OrderStatus.received: return 'Order Received';
      case OrderStatus.preparing: return 'Being Prepared';
      case OrderStatus.ready: return 'Ready to Serve';
      case OrderStatus.served: return 'Served';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'table_number': tableNumber,
        'items': items.map((i) => i.toJson()).toList(),
        'total': total,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };
}
