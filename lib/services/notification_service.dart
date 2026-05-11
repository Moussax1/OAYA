import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'supabase_service.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
const String _channelId = 'oaya_notifications';
const String _channelName = 'Notifications OAYA';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await _localNotifications.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  final notification = message.notification;
  if (notification != null) {
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}

class NotificationService {
  NotificationService._();
  static SupabaseClient get _client => SupabaseService.client;

  /// Navigation callback set by the app to avoid circular dependency on router
  static void Function(String? orderId)? onNavigateToOrder;

  /// Full initialization: Firebase, FCM, local notifications, foreground/background handlers
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          final user = _client.auth.currentUser;
          if (user != null) {
            await saveFcmToken(user.id, token);
          }
        }
      }

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onFcmTap);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _onFcmTap(initialMessage);
      }
    } catch (e) {
      debugPrint('[NotificationService] Init skipped: $e');
    }
  }

  /// Refresh FCM token for the current user (called after login)
  static Future<void> refreshToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) {
        final user = _client.auth.currentUser;
        if (user != null) {
          await saveFcmToken(user.id, token);
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Token refresh skipped: $e');
    }
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromData(data);
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId, _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  static void _onFcmTap(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  static void _navigateFromData(Map<String, dynamic> data) {
    final orderId = data['order_id'];
    onNavigateToOrder?.call(orderId?.toString());
  }

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

  /// Mark all as read
  static Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
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
}
