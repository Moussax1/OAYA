import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants/theme.dart';
import 'providers/providers.dart';
import 'services/supabase_service.dart';
import 'services/stripe_service.dart';
import 'services/notification_service.dart';
import 'router.dart';

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

  // Initialize Notifications (FCM + Local)
  await NotificationService.initialize();

  // Set notification navigation callback
  NotificationService.onNavigateToOrder = (orderId) {
    if (orderId != null && orderId.isNotEmpty) {
      appRouter.go('/order/confirmation/$orderId');
    } else {
      appRouter.go('/orders');
    }
  };

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
    // Refresh FCM token after auth state settles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.user != null) {
        NotificationService.refreshToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Sync cart and wishlist when user changes
    final currentUserId = auth.user?.id;
    if (currentUserId != _lastUserId && !auth.isLoading) {
      _lastUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cartProvider.notifier).loadCart();
        if (currentUserId != null) {
          ref.read(wishlistProvider.notifier).loadWishlist();
          NotificationService.refreshToken();
        }
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
