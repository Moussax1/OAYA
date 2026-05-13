import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oaya_flutter/services/supabase_service.dart';
import 'package:oaya_flutter/services/order_service.dart';
import 'package:oaya_flutter/services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() {
  String? testUserId;
  Map<String, dynamic>? testProduct;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: 'assets/.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    await SupabaseService.initialize();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      );
      testUserId = response.user?.id;
    } catch (e) {
      final response = await Supabase.instance.client.auth.signUp(
        email: 'test@example.com',
        password: 'password123',
      );
      testUserId = response.user?.id;
    }

    final products = await ProductService.getProducts();
    if (products.isNotEmpty) {
      testProduct = products.first;
    }
  });

  tearDownAll(() async {
    if (testUserId != null) {
      await Supabase.instance.client
          .from('orders')
          .delete()
          .eq('user_id', testUserId!);
    }
    await Supabase.instance.client.auth.signOut();
  });

  group('Order API Integration Tests', () {
    test('Create order and fetch orders', () async {
      if (testUserId == null || testProduct == null) {
        markTestSkipped('Test user or product not available');
        return;
      }

      final items = [
        {'product': testProduct, 'quantity': 2}
      ];
      final shipping = 9.99;
      final price = double.tryParse(testProduct!['price'].toString()) ?? 0.0;
      final total = (price * 2) + shipping;

      // 1. Create order
      final orderData = await OrderService.createOrder(
        items: items,
        shipping: shipping,
        total: total,
        userId: testUserId!,
      );

      expect(orderData['id'], isNotNull);
      expect(orderData['status'], 'pending');

      // 2. Fetch orders and verify
      final orders = await OrderService.getOrders();
      final createdOrder = orders.firstWhere((o) => o['id'] == orderData['id']);
      
      expect(createdOrder, isNotNull);
      expect(double.parse(createdOrder['total_amount'].toString()), total);
    });
  });
}
