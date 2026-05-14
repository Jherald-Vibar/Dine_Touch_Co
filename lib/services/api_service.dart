import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    return p.getString('restaurant_id') ??
        '00000000-0000-0000-0000-000000000001';
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
    String? customerName,
    String? orderType,
    int? tableNumber,
    String? paymentMethod,
    double? amountTendered,
    String? discountType,
    double? discountAmount,
  }) async {
    final restaurantId = await getRestaurantId();

    // Use the passed tableNumber first, fall back to session
    final resolvedTableNumber = tableNumber ?? await getTableNumber();

    // Get table_id from restaurant_tables
    final tableRows = await _supabase
        .from('restaurant_tables')
        .select('id')
        .eq('restaurant_id', restaurantId)
        .eq('table_number', resolvedTableNumber);

    final tableId = (tableRows as List).isNotEmpty
        ? tableRows.first['id']
        : null;

    // Compute total before discount
    final rawTotal = items.fold<double>(
      0.0,
      (sum, i) => sum + (i['unit_price'] as num) * (i['quantity'] as num),
    );

    // Apply discount to get final total
    final total =
        (rawTotal - (discountAmount ?? 0.0)).clamp(0.0, double.infinity);

    // Encode payment + discount details into notes
    String resolvedNotes = notes ?? '';
    final paymentData = <String, dynamic>{
      if (amountTendered != null) 'amount_tendered': amountTendered,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (discountType != null) 'discount_type': discountType,
      if (discountAmount != null && discountAmount > 0)
        'discount_amount': discountAmount,
    };
    if (paymentData.isNotEmpty) {
      resolvedNotes = resolvedNotes.isEmpty
          ? jsonEncode(paymentData)
          : '$resolvedNotes | ${jsonEncode(paymentData)}';
    }

    // Create order
    final orderRows = await _supabase
        .from('orders')
        .insert({
          'restaurant_id': restaurantId,
          'table_id': tableId,
          'table_number': resolvedTableNumber,
          'customer_name': customerName ?? '',
          'order_type': orderType ?? 'dine_in',
          'notes': resolvedNotes, // ✅ discount info encoded here
          'subtotal': rawTotal,
          'total_amount': total,  // ✅ correct discounted final total
          'payment_method': paymentMethod,
          // ✅ no discount_type column insert — stored in notes instead
        })
        .select();

    final order = (orderRows as List).first as Map<String, dynamic>;

    // Insert order items
    final orderItems = items
        .map((i) => {
              'order_id': order['id'],
              'menu_item_id': i['menu_item_id'],
              'name': i['name'],
              'unit_price': i['unit_price'],
              'quantity': i['quantity'],
              'special_request': i['special_request'] ?? '',
            })
        .toList();

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