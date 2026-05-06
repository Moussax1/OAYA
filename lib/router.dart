import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants/theme.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/checkout/address_screen.dart';
import 'screens/checkout/payment_screen.dart';
import 'screens/checkout/success_screen.dart';
import 'screens/order_confirmation_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _ScaffoldWithNav(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, s) => const HomeScreen()),
        GoRoute(path: '/search', builder: (_, s) => const SearchScreen()),
        GoRoute(path: '/cart', builder: (_, s) => const CartScreen()),
        GoRoute(path: '/wishlist', builder: (_, s) => const WishlistScreen()),
        GoRoute(path: '/profile', builder: (_, s) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/product/:id', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),
    GoRoute(path: '/login', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => const LoginScreen()),
    GoRoute(path: '/register', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => const RegisterScreen()),
    GoRoute(path: '/checkout/address', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => const AddressScreen()),
    GoRoute(path: '/checkout/payment', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => const PaymentScreen()),
    GoRoute(path: '/checkout/success', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => const SuccessScreen()),
    GoRoute(path: '/order/confirmation/:id', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => OrderConfirmationScreen(orderId: state.pathParameters['id']!)),
    GoRoute(path: '/orders', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => const OrderHistoryScreen()),
    GoRoute(path: '/admin/users', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => const AdminUsersScreen()),
    GoRoute(path: '/forgot-password', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => const ForgotPasswordScreen()),
    GoRoute(path: '/reset-password', parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => const ResetPasswordScreen()),
  ],
);

void setupRouterAuthListener() {
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      appRouter.go('/reset-password');
    }
  });
}

class _ScaffoldWithNav extends ConsumerWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  static const _tabs = ['/', '/search', '/cart', '/wishlist', '/profile'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _tabs.indexOf(location);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: FeatherIcons.home, label: 'Accueil', active: currentIndex == 0, onTap: () => context.go('/')),
                _NavItem(icon: FeatherIcons.search, label: 'Recherche', active: currentIndex == 1, onTap: () => context.go('/search')),
                _NavItem(icon: FeatherIcons.shoppingBag, label: 'Panier', active: currentIndex == 2, badge: cart.totalItems, onTap: () => context.go('/cart')),
                _NavItem(icon: FeatherIcons.heart, label: 'Favoris', active: currentIndex == 3, onTap: () => context.go('/wishlist')),
                _NavItem(icon: FeatherIcons.user, label: 'Profil', active: currentIndex == 4, onTap: () => context.go('/profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.active, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(icon, size: 22, color: active ? AppColors.accent : AppColors.textMuted),
              if (badge > 0) Positioned(top: -5, right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(badge > 9 ? '9+' : '$badge',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary))),
                )),
            ]),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: active ? AppColors.accent : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
