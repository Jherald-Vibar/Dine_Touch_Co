import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  int _tableNumber = 1;

  List<CartItem> get items => List.unmodifiable(_items);
  int get tableNumber => _tableNumber;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  void setTableNumber(int n) {
    _tableNumber = n;
    notifyListeners();
  }

  void addItem(MenuItem menuItem) {
    final existing = _items.where((i) => i.menuItem.id == menuItem.id);
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.removeWhere((i) => i.menuItem.id == menuItemId);
    notifyListeners();
  }

  void incrementQuantity(String menuItemId) {
    final item = _items.firstWhere((i) => i.menuItem.id == menuItemId);
    item.quantity++;
    notifyListeners();
  }

  void decrementQuantity(String menuItemId) {
    final item = _items.firstWhere((i) => i.menuItem.id == menuItemId);
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.removeWhere((i) => i.menuItem.id == menuItemId);
    }
    notifyListeners();
  }

  void setSpecialRequest(String menuItemId, String request) {
    final item = _items.firstWhere((i) => i.menuItem.id == menuItemId);
    item.specialRequest = request;
    notifyListeners();
  }

  int quantityOf(String menuItemId) {
    final matching = _items.where((i) => i.menuItem.id == menuItemId);
    return matching.isEmpty ? 0 : matching.first.quantity;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
