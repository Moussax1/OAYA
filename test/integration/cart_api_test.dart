import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oaya_flutter/services/supabase_service.dart';
import 'package:oaya_flutter/services/cart_service.dart';
import 'package:oaya_flutter/services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() {
  String? testProductId;
  String? testUserId;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: 'assets/.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    SupabaseService.initialize();

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

    // Get a product to add to the cart
    final products = await ProductService.getProducts();
    if (products.isNotEmpty) {
      testProductId = products.first['id'];
    }
  });

  tearDownAll(() async {
    // Clean up cart
    if (testUserId != null) {
      await Supabase.instance.client
          .from('cart_items')
          .delete()
          .eq('user_id', testUserId!);
    }
    await Supabase.instance.client.auth.signOut();
  });

  group('Cart API Integration Tests', () {
    test('Add item to cart, update quantity, and remove', () async {
      if (testUserId == null || testProductId == null) {
        markTestSkipped('Test user or product not available');
        return;
      }

      // 1. Add to cart
      await CartService.addItem(testUserId!, testProductId!, 1);

      // 2. Verify item appears
      var cartItems = await CartService.getCartItems(testUserId!);
      expect(cartItems.isNotEmpty, true);
      final addedItem = cartItems.firstWhere((item) => item['product_id'] == testProductId);
      expect(addedItem['quantity'], 1);

      // 3. Update quantity
      await CartService.updateQuantity(addedItem['id'], 3);
      cartItems = await CartService.getCartItems(testUserId!);
      final updatedItem = cartItems.firstWhere((item) => item['id'] == addedItem['id']);
      expect(updatedItem['quantity'], 3);

      // 4. Remove item
      await CartService.removeItem(addedItem['id']);
      cartItems = await CartService.getCartItems(testUserId!);
      final exists = cartItems.any((item) => item['id'] == addedItem['id']);
      expect(exists, false);
    });
  });
}
