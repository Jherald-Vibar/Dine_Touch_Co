import 'package:supabase_flutter/supabase_flutter.dart';

// ─── YOUR SUPABASE CREDENTIALS ───────────────────────────────
// Replace YOUR_ANON_KEY with the anon/public key from
// Supabase → Settings → API
const String _supabaseUrl = 'https://xcvnyxcmhnqjfjgxttes.supabase.co';
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhjdm55eGNtaG5xamZqZ3h0dGVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NzUwOTAsImV4cCI6MjA5MzE1MTA5MH0.DERNrR8498HFb09z1p9jU4K6ZcPgcBWpDy_tPa8c4Vg';
// ─────────────────────────────────────────────────────────────

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Call this once inside main() before runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  /// Kiosk: watch a single order's status in real time.
  /// TrackerScreen subscribes to this stream.
  static Stream<Map<String, dynamic>?> watchOrder(String orderId) {
    return client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) => rows.isNotEmpty ? rows.first : null);
  }

  /// Kitchen: watch all active orders for a restaurant.
  /// KitchenScreen subscribes to this stream.
  static Stream<List<Map<String, dynamic>>> watchActiveOrders(
      String restaurantId) {
    return client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: true)
        .map((rows) => rows
            .where((o) =>
                ['pending', 'preparing', 'ready'].contains(o['status']))
            .toList());
  }

  /// Kitchen: fetch all items for a specific order.
  static Future<List<Map<String, dynamic>>> fetchOrderItems(
      String orderId) async {
    final res = await client
        .from('order_items')
        .select()
        .eq('order_id', orderId);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Kitchen: update an order's status
  /// (e.g. 'pending' → 'preparing' → 'ready' → 'served')
  static Future<void> updateOrderStatus(
      String orderId, String newStatus) async {
    await client
        .from('orders')
        .update({'status': newStatus}).eq('id', orderId);
  }
}