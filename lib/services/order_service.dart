import 'supabase_service.dart';

class OrderService {
  OrderService._();

  /// Create order with line items, returns the created order
  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required double shipping,
    required double total,
    required String userId,
    String paymentMethod = 'cod',
    String? stripePaymentId,
  }) async {
    final client = SupabaseService.client;

    // Create order
    final orderData = await client.from('orders').insert({
      'user_id': userId,
      'total_amount': total,
      'shipping': shipping,
      'status': 'pending',
      'payment_method': paymentMethod,
      'stripe_payment_id': stripePaymentId,
    }).select().single();

    final orderId = orderData['id'];

    // Create order items
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

    return orderData;
  }

  /// Fetch user orders with items
  static Future<List<Map<String, dynamic>>> getOrders() async {
    final data = await SupabaseService.client
        .from('orders')
        .select('*, order_items(*, product:products(*))')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
