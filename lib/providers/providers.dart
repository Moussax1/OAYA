import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';
import '../services/address_service.dart';
import '../services/wishlist_service.dart';
import '../services/review_service.dart';
import '../services/payment_method_service.dart';

// ─── AUTH ──────────────────────────────────────────────────────────────────────

class AuthState {
  final Session? session;
  final Map<String, dynamic>? profile;
  final bool isLoading;
  AuthState({this.session, this.profile, this.isLoading = true});

  User? get user => session?.user;
  bool get isAuthenticated => session?.user != null;
  bool get isAdmin {
    final role = profile?['role'] as String?;
    return role == 'admin' || role == 'owner';
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  AuthNotifier(this.ref) : super(AuthState()) {
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
      final hadSession = state.session?.user != null;
      Map<String, dynamic>? p;
      if (data.session?.user != null) {
        p = await _fetchProfile(data.session!.user.id);
      }
      state = AuthState(session: data.session, profile: p, isLoading: false);
      if (!hadSession && data.session?.user != null) {
        try {
          await ref.read(cartProvider.notifier).mergeLocalCartFromState();
          ref.invalidate(wishlistProvider);
          ref.invalidate(addressesProvider);
        } catch (_) {}
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      return await _client.from('profiles').select().eq('id', userId).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    try {
      final result = await _client.rpc('is_admin');
      return result == true;
    } catch (_) {
      return state.profile?['role'] == 'admin' || state.profile?['role'] == 'owner';
    }
  }

  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    final res = await _client.auth.signUp(email: email, password: password, data: {'full_name': fullName});
    try {
      await ref.read(cartProvider.notifier).mergeLocalCartFromState();
      await ref.read(cartProvider.notifier).loadCart();
    } catch (_) {}
    return res;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    try {
      await ref.read(cartProvider.notifier).mergeLocalCartFromState();
      await ref.read(cartProvider.notifier).loadCart();
    } catch (_) {}
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email, redirectTo: 'io.supabase.oaya://login-callback/');
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = AuthState(isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

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
    if (_userId == null) {
      try {
        final product = await ProductService.getProduct(productId);
        if (product == null) return;
        var found = false;
        final updated = <Map<String, dynamic>>[];
        for (final it in state.items) {
          final currentProductId = (it['product'] as Map<String, dynamic>?)?['id']?.toString() ?? it['product_id']?.toString();
          if (currentProductId == productId) {
            found = true;
            updated.add({...it, 'quantity': (it['quantity'] as int) + qty});
          } else {
            updated.add(it);
          }
        }
        if (!found) {
          updated.add({'product': product, 'quantity': qty});
        }
        state = CartState(items: updated);
      } catch (_) {}
      return;
    }
    await CartService.addItem(_userId!, productId, qty);
    await loadCart();
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_userId == null) {
      final updated = state.items.map((it) {
        final id = it['id'] ?? it['product']?['id'];
        if (id == itemId) {
          return {...it, 'quantity': quantity};
        }
        return it;
      }).toList();
      state = CartState(items: updated);
      return;
    }
    await CartService.updateQuantity(itemId, quantity);
    await loadCart();
  }

  Future<void> removeItem(String itemId) async {
    if (_userId == null) {
      state = CartState(items: state.items.where((it) {
        final id = it['id'] ?? it['product']?['id'];
        return id != itemId;
      }).toList());
      return;
    }
    await CartService.removeItem(itemId);
    await loadCart();
  }

  Future<void> clearCart() async {
    if (_userId == null) {
      state = CartState();
      return;
    }
    await CartService.clearCart(_userId!);
    state = CartState();
  }

  Future<void> mergeLocalCartFromState() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      for (final it in state.items) {
        final product = it['product'] as Map<String, dynamic>?;
        final productId = product != null ? product['id'] : it['product_id'];
        final qty = it['quantity'] as int? ?? 1;
        if (productId != null) {
          await CartService.addItem(userId, productId.toString(), qty);
        }
      }
      await loadCart();
    } catch (_) {}
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

// ─── WISHLIST (Supabase-backed with guest fallback) ────────────────────────────

class WishlistNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;
  WishlistNotifier(this.ref) : super([]);

  String? get _userId => ref.read(authProvider).user?.id;

  Future<void> loadWishlist() async {
    final uid = _userId;
    if (uid == null) { state = [..._guestList]; return; }
    try {
      state = await WishlistService.getWishlist(uid);
    } catch (_) {
      state = [];
    }
  }

  Future<void> add(Map<String, dynamic> product) async {
    final uid = _userId;
    if (uid == null) {
      if (_guestList.any((p) => p['id'] == product['id'])) return;
      _guestList.add(product);
      state = [..._guestList];
      return;
    }
    if (state.any((p) => p['product']?['id'] == product['id'] || p['product_id'] == product['id'])) return;
    try {
      await WishlistService.addItem(uid, product['id'].toString());
      await loadWishlist();
    } catch (_) {}
  }

  Future<void> remove(dynamic productId) async {
    final uid = _userId;
    if (uid == null) {
      _guestList.removeWhere((p) => p['id'] == productId || p['product_id'] == productId);
      state = [..._guestList];
      return;
    }
    try {
      await WishlistService.removeItem(uid, productId.toString());
      await loadWishlist();
    } catch (_) {}
  }

  Future<void> toggle(Map<String, dynamic> product) async {
    final uid = _userId;
    if (uid == null) {
      if (_guestList.any((p) => p['id'] == product['id'])) {
        _guestList.removeWhere((p) => p['id'] == product['id']);
      } else {
        _guestList.add(product);
      }
      state = [..._guestList];
      return;
    }
    final already = state.any((p) =>
        p['product']?['id'] == product['id'] || p['product_id'] == product['id']);
    if (already) {
      await remove(product['id']);
    } else {
      await add(product);
    }
  }

  bool isWishlisted(dynamic productId) {
    final uid = _userId;
    if (uid == null) {
      return _guestList.any((p) => p['id'] == productId || p['product_id'] == productId);
    }
    return state.any((p) =>
        p['product']?['id'] == productId || p['product_id'] == productId);
  }

  final List<Map<String, dynamic>> _guestList = [];
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, List<Map<String, dynamic>>>((ref) => WishlistNotifier(ref));

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

// ─── ADDRESSES ─────────────────────────────────────────────────────────────────

final addressesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];
  return await AddressService.getAddresses(auth.user!.id);
});

final defaultAddressProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return null;
  return await AddressService.getDefaultAddress(auth.user!.id);
});

// ─── REVIEWS ───────────────────────────────────────────────────────────────────

final reviewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, productId) async {
  return await ReviewService.getReviews(productId);
});

final averageRatingProvider = FutureProvider.family<double, String>((ref, productId) async {
  return await ReviewService.getAverageRating(productId);
});

final reviewCountProvider = FutureProvider.family<int, String>((ref, productId) async {
  return await ReviewService.getReviewCount(productId);
});

final userReviewProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, productId) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return null;
  return await ReviewService.getUserReview(auth.user!.id, productId);
});

final userReviewsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];
  return await ReviewService.getUserReviews(auth.user!.id);
});

// ─── PAYMENT METHODS ───────────────────────────────────────────────────────────

final paymentMethodsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];
  return await PaymentMethodService.getPaymentMethods(auth.user!.id);
});
