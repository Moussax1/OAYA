import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ProductService {
  ProductService._();

  static SupabaseClient get _client => SupabaseService.client;

  /// Fetch products with optional category filter and search query
  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    String? searchQuery,
  }) async {
    PostgrestFilterBuilder query = _client
        .from('products')
        .select();

    if (category != null && category != 'Tous') {
      query = query.eq('category', category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.ilike('name', '%${searchQuery.trim()}%');
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch a single product by ID
  static Future<Map<String, dynamic>?> getProduct(String id) async {
    final data = await _client
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data;
  }

  /// Fetch unique categories from products table
  static Future<List<String>> getCategories() async {
    final data = await _client.from('products').select('category');
    final categories = <String>{'Tous'};
    for (final row in data) {
      final cat = row['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        categories.add(cat);
      }
    }
    return categories.toList();
  }
}
