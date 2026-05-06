import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'constants/theme.dart';
import 'providers/providers.dart';
import 'services/supabase_service.dart';
import 'services/stripe_service.dart';
import 'services/notification_service.dart';
import 'router.dart';

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message if needed
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: 'assets/.env');

  // Initialize Supabase
  await SupabaseService.initialize();
  setupRouterAuthListener();

  // Initialize Stripe (not on web)
  if (!kIsWeb) {
    StripeService.initialize();
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Init skipped: $e');
  }

  // Lock orientation to portrait (mobile only)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: OayaApp()));
}

class OayaApp extends ConsumerStatefulWidget {
  const OayaApp({super.key});
  @override
  ConsumerState<OayaApp> createState() => _OayaAppState();
}

class _OayaAppState extends ConsumerState<OayaApp> {
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          debugPrint('[FCM] Token: $token');
          // Save token when user is available
          _saveFcmToken(token);
        }
      }
      // Foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        if (message.notification != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${message.notification!.title}: ${message.notification!.body}'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      });
    } catch (e) {
      debugPrint('[FCM] Setup skipped: $e');
    }
  }

  void _saveFcmToken(String token) {
    final auth = ref.read(authProvider);
    if (auth.user != null) {
      NotificationService.saveFcmToken(auth.user!.id, token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Sync cart when user changes
    final currentUserId = auth.user?.id;
    if (currentUserId != _lastUserId && !auth.isLoading) {
      _lastUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cartProvider.notifier).loadCart();
      });
    }

    if (auth.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ),
      );
    }

    return MaterialApp.router(
      title: 'OAYA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
