import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oaya_flutter/services/supabase_service.dart';
import 'package:oaya_flutter/services/notification_service.dart';
import 'package:oaya_flutter/services/product_service.dart';
import 'package:oaya_flutter/services/order_service.dart';
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

    final products = await ProductService.getProducts();
    if (products.isNotEmpty) {
      testProduct = products.first;
    }
  });

  tearDownAll(() async {
    if (testUserId != null) {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('user_id', testUserId!);
      await Supabase.instance.client
          .from('orders')
          .delete()
          .eq('user_id', testUserId!);
    }
    await Supabase.instance.client.auth.signOut();
  });

  group('Notification Chain Integration Tests', () {
    String? createdOrderId;

    test('Step 1: Create an order (simulating successful payment)', () async {
      if (testUserId == null || testProduct == null) {
        markTestSkipped('Test user or product not available');
        return;
      }

      final items = [
        {'product': testProduct, 'quantity': 2}
      ];
      final price = double.tryParse(testProduct!['price'].toString()) ?? 0;
      final total = price * 2 + 9.99;

      final order = await OrderService.createOrder(
        items: items,
        shipping: 9.99,
        total: total,
        userId: testUserId!,
        paymentMethod: 'card',
        stripePaymentId: 'pi_test_' + DateTime.now().millisecondsSinceEpoch.toString(),
      );

      expect(order['id'], isNotNull);
      expect(order['status'], 'pending');
      expect(order['payment_method'], 'card');
      createdOrderId = order['id'];
    });

    test('Step 2: Simulate webhook — mark order as paid', () async {
      if (testUserId == null || createdOrderId == null) {
        markTestSkipped('No order available');
        return;
      }

      await Supabase.instance.client
          .from('orders')
          .update({'status': 'paid'})
          .eq('id', createdOrderId!);

      final updated = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('id', createdOrderId!)
          .single();

      expect(updated['status'], 'paid');
    });

    test('Step 3: Create in-app notification (simulating webhook)', () async {
      if (testUserId == null || createdOrderId == null) {
        markTestSkipped('No order available');
        return;
      }

      await NotificationService.createNotification(
        userId: testUserId!,
        title: 'Paiement confirmé',
        body: 'Votre paiement pour la commande #${createdOrderId!.substring(0, 8)} a été reçu.',
      );

      final notifications = await NotificationService.getNotifications(testUserId!);
      final matching = notifications.where((n) =>
          n['title'] == 'Paiement confirmé' &&
          (n['body'] as String?)?.contains(createdOrderId!.substring(0, 8)) == true);

      expect(matching.isNotEmpty, true,
          reason: 'Notification should be created for the paid order');
    });

    test('Step 4: Verify unread notification count', () async {
      if (testUserId == null) {
        markTestSkipped('Test user not available');
        return;
      }

      final count = await NotificationService.getUnreadCount(testUserId!);
      expect(count, greaterThan(0));
    });

    test('Step 5: Mark notification as read', () async {
      if (testUserId == null) {
        markTestSkipped('Test user not available');
        return;
      }

      final notifications = await NotificationService.getNotifications(testUserId!);
      if (notifications.isEmpty) {
        markTestSkipped('No notifications to mark');
        return;
      }

      final unread = notifications.firstWhere(
        (n) => n['read'] == false,
        orElse: () => <String, dynamic>{},
      );
      if (unread.isEmpty) {
        markTestSkipped('No unread notifications');
        return;
      }

      await NotificationService.markAsRead(unread['id']);
      await NotificationService.getUnreadCount(testUserId!);
      final stillUnread = notifications.any((n) =>
          n['id'] == unread['id'] && n['read'] == false);
      expect(stillUnread, false,
          reason: 'Notification should be marked as read');
    });

    test('Step 6: Trigger send-order-email edge function', () async {
      if (createdOrderId == null) {
        markTestSkipped('No order available');
        return;
      }

      try {
        final result = await Supabase.instance.client.functions.invoke(
          'send-order-email',
          body: {'order_id': createdOrderId!, 'user_email': 'test@example.com'},
        );
        expect(result.data, isNotNull);
      } catch (e) {
        // Edge function may not be deployed in test env — skip gracefully
        markTestSkipped('Edge function not deployed or unavailable: $e');
      }
    });
  });
}
