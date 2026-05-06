import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../utils/currency.dart';
import '../widgets/cart_item_tile.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final auth = ref.watch(authProvider);
    final shipping = cart.totalPrice > 100 ? 0.0 : 9.99;

    if (cart.isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    }

    return SafeArea(child: cart.items.isEmpty ? _buildEmpty(context) : _buildCart(context, ref, cart, auth, shipping));
  }

  Widget _buildEmpty(BuildContext context) => Column(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [Text('Mon Panier', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textPrimary))]),
    ),
    Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.xxl), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Lottie.network('https://assets5.lottiefiles.com/packages/lf20_V6Y9YV.json', width: 180, height: 180, errorBuilder: (_, e, s) => const Icon(FeatherIcons.shoppingBag, size: 80, color: AppColors.textMuted)),
      const SizedBox(height: 16),
      Text('Votre panier est vide', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xxl, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text('Explorez notre collection et ajoutez des articles.', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 28),
      GestureDetector(onTap: () => context.go('/'),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Text('Explorer la boutique', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: Colors.white)))),
    ])))),
  ]);

  Widget _buildCart(BuildContext context, WidgetRef ref, CartState cart, AuthState auth, double shipping) {
    return Stack(children: [
      Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Mon Panier', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            GestureDetector(onTap: () => ref.read(cartProvider.notifier).clearCart(), child: Text('Vider', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.error))),
          ]),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 220),
          itemCount: cart.items.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) return _shippingBanner(cart.totalPrice);
            final item = cart.items[i - 1];
            final product = item['product'] as Map<String, dynamic>? ?? {};
            final cartItem = {'product': product, 'quantity': item['quantity']};
            return Padding(padding: const EdgeInsets.only(bottom: 12),
              child: CartItemTile(item: cartItem,
                onIncrease: () => ref.read(cartProvider.notifier).updateQuantity(item['id'].toString(), (item['quantity'] as int) + 1),
                onDecrease: () => ref.read(cartProvider.notifier).updateQuantity(item['id'].toString(), (item['quantity'] as int) - 1),
                onRemove: () => ref.read(cartProvider.notifier).removeItem(item['id'].toString())));
          },
        )),
      ]),
      Positioned(bottom: 0, left: 0, right: 0, child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 28),
        decoration: BoxDecoration(color: AppColors.surface, border: const Border(top: BorderSide(color: AppColors.border)), boxShadow: AppShadow.sheet),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _summaryRow('Sous-total (${cart.totalItems} articles)', formatCurrency(cart.totalPrice)),
          const SizedBox(height: 8),
          _summaryRow('Livraison', cart.totalPrice >= 100 ? 'Gratuite' : formatCurrency(shipping), valueColor: cart.totalPrice >= 100 ? AppColors.success : null),
          Container(height: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 10)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: GoogleFonts.inter(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(formatCurrency(cart.totalPrice + shipping), style: GoogleFonts.inter(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () { if (!auth.isAuthenticated) { context.push('/login'); } else { context.push('/checkout/address'); } },
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(auth.isAuthenticated ? 'Passer la commande' : 'Connectez-vous pour commander',
                    style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(FeatherIcons.arrowRight, size: 18, color: Colors.white),
              ]),
            ),
          ),
        ]),
      )),
    ]);
  }

  Widget _shippingBanner(double total) {
    if (total >= 80 && total < 100) {
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFA7F3D0))),
        child: Row(children: [const Icon(FeatherIcons.truck, size: 14, color: AppColors.success), const SizedBox(width: 8),
          Expanded(child: Text('Ajoutez ${formatCurrency(100 - total)} de plus pour la livraison gratuite !', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.success)))]));
    }
    if (total >= 100) {
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFBBF7D0))),
        child: Row(children: [const Icon(FeatherIcons.checkCircle, size: 14, color: AppColors.success), const SizedBox(width: 8),
          Text('Livraison gratuite incluse !', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.success))]));
    }
    return const SizedBox.shrink();
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
      Text(value, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
    ]);
}
