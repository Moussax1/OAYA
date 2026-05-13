import 'supabase_service.dart';
import 'admin_service.dart';

class OrderService {
  OrderService._();

  /// Create order with line items, returns the created order.
  /// Validates stock before creating and decrements inventory atomically.
  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required double shipping,
    required double total,
    required String userId,
    String paymentMethod = 'cod',
    String? stripePaymentId,
  }) async {
    final client = SupabaseService.client;

    // 1. Validate stock before proceeding
    for (final item in items) {
      final product = item['product'] as Map<String, dynamic>;
      final productId = product['id'];
      final qty = item['quantity'] as int;

      final current = await client
          .from('products')
          .select('name, stock')
          .eq('id', productId)
          .maybeSingle();

      if (current == null) {
        throw Exception('${product['name'] ?? 'Produit'} n\'existe plus.');
      }
      final available = current['stock'] as int? ?? 0;
      if (available < qty) {
        throw Exception(
          '${current['name'] ?? 'Produit'} n\'est plus disponible en quantité suffisante. '
          'Stock restant: $available',
        );
      }
    }

    // 2. Create order
    final orderData = await client.from('orders').insert({
      'user_id': userId,
      'total_amount': total,
      'shipping': shipping,
      'status': 'pending',
      'payment_method': paymentMethod,
      'stripe_payment_id': stripePaymentId,
    }).select().single();

    final orderId = orderData['id'];

    // 3. Create order items
    final orderItems = items.map((item) {
      final product = item['product'] as Map<String, dynamic>;
      return {
        'order_id': orderId,
        'product_id': product['id'],
        'quantity': item['quantity'],
        'unit_price': double.tryParse(product['price'].toString()) ?? 0,
      };
    }).toList();

    await client.from('order_items').insert(orderItems);

    // 4. Decrement stock for each item
    for (final item in items) {
      final product = item['product'] as Map<String, dynamic>;
      final qty = item['quantity'] as int;
      await client.rpc('decrement_stock', params: {
        'pid': product['id'],
        'qty': qty,
      });
    }

    return orderData;
  }

  /// Fetch user orders with items
  static Future<List<Map<String, dynamic>>> getOrders({String? userId}) async {
    var query = SupabaseService.client
        .from('orders')
        .select('*, order_items(*, product:products(*))');

    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch a single order by ID with items and products
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final data = await SupabaseService.client
        .from('orders')
        .select('*, order_items(*, product:products(*))')
        .eq('id', orderId)
        .maybeSingle();
    return data;
  }

  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    if (!await AdminService.isCurrentUserAdmin()) {
      throw Exception('Unauthorized');
    }
    final data = await SupabaseService.client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .select()
        .single();
    return Map<String, dynamic>.from(data);
  }
}
