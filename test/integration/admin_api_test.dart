import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:oaya_flutter/services/admin_service.dart';
import 'package:oaya_flutter/services/order_service.dart';
import 'package:oaya_flutter/services/supabase_service.dart';

void main() {
  String? adminUserId;
  String? targetUserId;
  String? targetOrderId;
  bool adminAvailable = false;
  bool supabaseInitialized = false;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    await dotenv.load(fileName: 'assets/.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    final adminEmail = dotenv.env['ADMIN_TEST_EMAIL'];
    final adminPassword = dotenv.env['ADMIN_TEST_PASSWORD'];

    if (url == null || anonKey == null || adminEmail == null || adminPassword == null) {
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    supabaseInitialized = true;
    SupabaseService.initialize();

    final auth = Supabase.instance.client.auth;
    final response = await auth.signInWithPassword(email: adminEmail, password: adminPassword);
    adminUserId = response.user?.id;
    adminAvailable = adminUserId != null;

    if (!adminAvailable) return;

    targetUserId = dotenv.env['ADMIN_TEST_TARGET_USER_ID'];
    targetOrderId = dotenv.env['ADMIN_TEST_TARGET_ORDER_ID'];
  });

  tearDownAll(() async {
    if (!supabaseInitialized) {
      return;
    }
    if (Supabase.instance.client.auth.currentSession != null) {
      await Supabase.instance.client.auth.signOut();
    }
  });

  group('Admin API integration tests', () {
    test('current admin session is recognized by the service', () async {
      if (!adminAvailable) {
        markTestSkipped('Set ADMIN_TEST_EMAIL and ADMIN_TEST_PASSWORD to run admin integration tests');
        return;
      }

      expect(await AdminService.isCurrentUserAdmin(), isTrue);
    });

    test('can promote and demote a target user', () async {
      if (!adminAvailable || targetUserId == null) {
        markTestSkipped('Set ADMIN_TEST_TARGET_USER_ID to run role mutation integration test');
        return;
      }

      final client = Supabase.instance.client;
      final original = await client.from('profiles').select('role').eq('id', targetUserId!).maybeSingle();
      final originalRole = original?['role']?.toString() ?? AdminService.userRole;

      await AdminService.promoteUser(targetUserId!);
      final promoted = await client.from('profiles').select('role').eq('id', targetUserId!).maybeSingle();
      expect(promoted?['role'], AdminService.adminRole);

      await AdminService.updateUserRole(targetUserId!, originalRole);
      final restored = await client.from('profiles').select('role').eq('id', targetUserId!).maybeSingle();
      expect(restored?['role'], originalRole);
    });

    test('can update a target order status', () async {
      if (!adminAvailable || targetOrderId == null) {
        markTestSkipped('Set ADMIN_TEST_TARGET_ORDER_ID to run order status integration test');
        return;
      }

      final client = Supabase.instance.client;
      final original = await client.from('orders').select('status').eq('id', targetOrderId!).maybeSingle();
      final originalStatus = original?['status']?.toString() ?? 'pending';

      await OrderService.updateOrderStatus(targetOrderId!, 'paid');
      final updated = await client.from('orders').select('status').eq('id', targetOrderId!).maybeSingle();
      expect(updated?['status'], 'paid');

      await OrderService.updateOrderStatus(targetOrderId!, originalStatus);
      final restored = await client.from('orders').select('status').eq('id', targetOrderId!).maybeSingle();
      expect(restored?['status'], originalStatus);
    });
  });
}
