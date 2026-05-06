import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'supabase_service.dart';

class NotificationService {
  NotificationService._();
  static SupabaseClient get _client => SupabaseService.client;

  /// Fetch user notifications
  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get unread count
  static Future<int> getUnreadCount(String userId) async {
    final data = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('read', false);
    return data.length;
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  /// Create in-app notification
  static Future<void> createNotification({
    required String userId,
    required String title,
    String? body,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
    });
  }

  /// Save FCM token to profile
  static Future<void> saveFcmToken(String userId, String token) async {
    await _client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
  }

  /// Show in-app SnackBar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  /// Show AlertDialog
  static Future<void> showResultDialog(BuildContext context, {required String title, required String message, bool isSuccess = true}) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(title),
        ]),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  /// Initialize FCM
  static Future<void> initFCM() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await messaging.getToken();
      if (token != null) {
        final user = _client.auth.currentUser;
        if (user != null) {
          await saveFcmToken(user.id, token);
        }
      }
    }
  }

  /// Setup FCM handlers for background and foreground messages
  static Future<void> setupFCMHandlers(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${message.notification!.title}: ${message.notification!.body}'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      context.go('/orders');
    });
  }
}
