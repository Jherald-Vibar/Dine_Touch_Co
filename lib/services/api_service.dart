import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _supabase = Supabase.instance.client;

class ApiService {
  // ── Session ─────────────────────────────────────────────────
  static Future<void> saveSession({
    required String restaurantId,
    required int tableNumber,
    required String restaurantName,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('restaurant_id', restaurantId);
    await p.setInt('table_number', tableNumber);
    await p.setString('restaurant_name', restaurantName);
  }

  static Future<String> getRestaurantId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('restaurant_id') ?? '00000000-0000-0000-0000-000000000001';
  }

  static Future<int> getTableNumber() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt('table_number') ?? 1;
  }

  // ── Menu ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchMenu(String restaurantId) async {
    final categories = await _supabase
        .from('categories')
        .select()
        .eq('restaurant_id', restaurantId)
        .eq('is_active', true)
        .order('sort_order');

    final items = await _supabase
        .from('menu_items')
        .select('*, categories(name)')
        .eq('restaurant_id', restaurantId)
        .eq('is_available', true)
        .order('sort_order');

    // Flatten joined category name into each item
    final flatItems = (items as List).map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      map['category'] = (map['categories'] as Map?)?['name'] ?? '';
      map.remove('categories');
      return map;
    }).toList();

    return {'categories': categories, 'items': flatItems};
  }

  // ── Orders ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final restaurantId = await getRestaurantId();
    final tableNumber = await getTableNumber();

    // Get table_id
    final tableRows = await _supabase
        .from('restaurant_tables')
        .select('id')
        .eq('restaurant_id', restaurantId)
        .eq('table_number', tableNumber);

    final tableId = (tableRows as List).isNotEmpty
        ? tableRows.first['id']
        : null;

    // Compute total
    final total = items.fold<double>(
      0.0,
      (sum, i) => sum + (i['unit_price'] as num) * (i['quantity'] as num),
    );

    // Create order
    final orderRows = await _supabase
        .from('orders')
        .insert({
          'restaurant_id': restaurantId,
          'table_id': tableId,
          'table_number': tableNumber,
          'notes': notes ?? '',
          'subtotal': total,
          'total_amount': total,
        })
        .select();

    final order = (orderRows as List).first as Map<String, dynamic>;

    // Insert order items
    final orderItems = items.map((i) => {
      'order_id': order['id'],
      'menu_item_id': i['menu_item_id'],
      'name': i['name'],
      'unit_price': i['unit_price'],
      'quantity': i['quantity'],
      'special_request': i['special_request'] ?? '',
    }).toList();

    await _supabase.from('order_items').insert(orderItems);

    return {'order': order};
  }

  // ── Feedback ────────────────────────────────────────────────
  static Future<void> submitFeedback({
    required String restaurantId,
    required String orderId,
    required int tableNumber,
    required int rating,
    String? comment,
  }) async {
    await _supabase.from('feedback').insert({
      'order_id': orderId,
      'restaurant_id': restaurantId,
      'table_number': tableNumber,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  // ── AI Chat ─────────────────────────────────────────────────
  static Future<String> sendChatMessage({
    required String message,
    required List<Map<String, dynamic>> history,
  }) async {
    return "Hi! I'm your menu assistant. Ask me about our dishes!";
  }
}