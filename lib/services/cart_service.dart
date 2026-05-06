import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CartService {
  CartService._();
  static SupabaseClient get _client => SupabaseService.client;

  /// Fetch all cart items for the current user (with product info)
  static Future<List<Map<String, dynamic>>> getCartItems(String userId) async {
    final data = await _client
        .from('cart_items')
        .select('*, product:products(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Add item to cart (upsert: if exists, increment quantity)
  static Future<void> addItem(String userId, String productId, [int qty = 1]) async {
    // Check if item already exists
    final existing = await _client
        .from('cart_items')
        .select('id, quantity')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('cart_items')
          .update({'quantity': (existing['quantity'] as int) + qty})
          .eq('id', existing['id']);
    } else {
      await _client.from('cart_items').insert({
        'user_id': userId,
        'product_id': productId,
        'quantity': qty,
      });
    }
  }

  /// Update quantity of a cart item
  static Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(itemId);
      return;
    }
    await _client.from('cart_items').update({'quantity': quantity}).eq('id', itemId);
  }

  /// Remove item from cart
  static Future<void> removeItem(String itemId) async {
    await _client.from('cart_items').delete().eq('id', itemId);
  }

  /// Clear all cart items for user
  static Future<void> clearCart(String userId) async {
    await _client.from('cart_items').delete().eq('user_id', userId);
  }

  /// Get cart item count
  static Future<int> getItemCount(String userId) async {
    final data = await _client
        .from('cart_items')
        .select('quantity')
        .eq('user_id', userId);
    int total = 0;
    for (final item in data) {
      total += (item['quantity'] as int);
    }
    return total;
  }
}
