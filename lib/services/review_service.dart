import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ReviewService {
  ReviewService._();
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<Map<String, dynamic>>> getReviews(String productId) async {
    final data = await _client
        .from('reviews')
        .select('*, profile:profiles(full_name, avatar_url)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> addReview({
    required String userId,
    required String productId,
    required int rating,
    String? comment,
  }) async {
    final data = await _client.from('reviews').insert({
      'user_id': userId,
      'product_id': productId,
      'rating': rating,
      'comment': comment,
    }).select().single();
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>?> getUserReview(String userId, String productId) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    if (data != null) return Map<String, dynamic>.from(data);
    return null;
  }

  static Future<double> getAverageRating(String productId) async {
    final data = await _client
        .from('reviews')
        .select('rating')
        .eq('product_id', productId);
    if (data.isEmpty) return 0.0;
    final sum = data.fold<int>(0, (s, e) => s + (e['rating'] as int));
    return sum / data.length;
  }

  static Future<int> getReviewCount(String productId) async {
    final data = await _client
        .from('reviews')
        .select('id')
        .eq('product_id', productId);
    return data.length;
  }

  static Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    final data = await _client
        .from('reviews')
        .select('*, product:products(name, image_url, price)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> deleteReview(String reviewId) async {
    await _client.from('reviews').delete().eq('id', reviewId);
  }
}
