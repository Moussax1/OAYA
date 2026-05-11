import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class WishlistService {
  WishlistService._();
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<Map<String, dynamic>>> getWishlist(String userId) async {
    final data = await _client
        .from('wishlist_items')
        .select('*, product:products(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> addItem(String userId, String productId) async {
    final existing = await _client
        .from('wishlist_items')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    if (existing != null) return;
    await _client.from('wishlist_items').insert({
      'user_id': userId,
      'product_id': productId,
    });
  }

  static Future<void> removeItem(String userId, String productId) async {
    await _client
        .from('wishlist_items')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  static Future<bool> isWishlisted(String userId, String productId) async {
    final data = await _client
        .from('wishlist_items')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    return data != null;
  }

  static Future<Set<String>> getWishlistedIds(String userId) async {
    final data = await _client
        .from('wishlist_items')
        .select('product_id')
        .eq('user_id', userId);
    return data.map<String>((e) => e['product_id'] as String).toSet();
  }
}
