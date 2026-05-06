import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';

// ─── AUTH ──────────────────────────────────────────────────────────────────────

class AuthState {
  final Session? session;
  final Map<String, dynamic>? profile;
  final bool isLoading;
  AuthState({this.session, this.profile, this.isLoading = true});

  User? get user => session?.user;
  bool get isAuthenticated => session?.user != null;
  bool get isAdmin => profile?['role'] == 'admin';
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  SupabaseClient get _client => SupabaseService.client;

  Future<void> _init() async {
    final session = _client.auth.currentSession;
    Map<String, dynamic>? profile;
    if (session?.user != null) {
      profile = await _fetchProfile(session!.user.id);
    }
    state = AuthState(session: session, profile: profile, isLoading: false);

    _client.auth.onAuthStateChange.listen((data) async {
      Map<String, dynamic>? p;
      if (data.session?.user != null) {
        p = await _fetchProfile(data.session!.user.id);
      }
      state = AuthState(session: data.session, profile: p, isLoading: false);
    });
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      return await _client.from('profiles').select().eq('id', userId).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    final res = await _client.auth.signUp(email: email, password: password, data: {'full_name': fullName});
    return res;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email, redirectTo: 'io.supabase.oaya://login-callback/');
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = AuthState(isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// ─── CART (Supabase-backed) ────────────────────────────────────────────────────

class CartState {
  final List<Map<String, dynamic>> items;
  final bool isLoading;
  CartState({this.items = const [], this.isLoading = false});

  int get totalItems => items.fold(0, (s, i) => s + (i['quantity'] as int));
  double get totalPrice {
    double total = 0;
    for (final item in items) {
      final product = item['product'] as Map<String, dynamic>?;
      if (product != null) {
        final price = double.tryParse(product['price'].toString()) ?? 0;
        total += price * (item['quantity'] as int);
      }
    }
    return total;
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;
  CartNotifier(this.ref) : super(CartState());

  String? get _userId => ref.read(authProvider).user?.id;

  Future<void> loadCart() async {
    if (_userId == null) { state = CartState(); return; }
    state = CartState(items: state.items, isLoading: true);
    try {
      final items = await CartService.getCartItems(_userId!);
      state = CartState(items: items);
    } catch (_) {
      state = CartState();
    }
  }

  Future<void> addItem(String productId, [int qty = 1]) async {
    if (_userId == null) return;
    await CartService.addItem(_userId!, productId, qty);
    await loadCart();
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    await CartService.updateQuantity(itemId, quantity);
    await loadCart();
  }

  Future<void> removeItem(String itemId) async {
    await CartService.removeItem(itemId);
    await loadCart();
  }

  Future<void> clearCart() async {
    if (_userId == null) return;
    await CartService.clearCart(_userId!);
    state = CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

// ─── WISHLIST (local, kept simple) ─────────────────────────────────────────────

class WishlistNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  WishlistNotifier() : super([]);

  void add(Map<String, dynamic> product) {
    if (state.any((p) => p['id'] == product['id'])) return;
    state = [...state, product];
  }

  void remove(dynamic productId) {
    state = state.where((p) => p['id'] != productId).toList();
  }

  void toggle(Map<String, dynamic> product) {
    if (state.any((p) => p['id'] == product['id'])) {
      remove(product['id']);
    } else {
      add(product);
    }
  }

  bool isWishlisted(dynamic productId) => state.any((p) => p['id'] == productId);
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, List<Map<String, dynamic>>>((ref) => WishlistNotifier());

// ─── ORDERS ────────────────────────────────────────────────────────────────────

final ordersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];
  return await OrderService.getOrders();
});

// ─── PRODUCTS ──────────────────────────────────────────────────────────────────

final productsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, category) async {
  return await ProductService.getProducts(category: category);
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  return await ProductService.getCategories();
});

// ─── NOTIFICATIONS ─────────────────────────────────────────────────────────────

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return 0;
  return await NotificationService.getUnreadCount(auth.user!.id);
});

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];
  return await NotificationService.getNotifications(auth.user!.id);
});
