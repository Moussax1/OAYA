import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../services/notification_service.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final auth = ref.watch(authProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2;

    return SafeArea(child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Ma Liste Souhaitée', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (wishlist.isNotEmpty) Text('${wishlist.length} article${wishlist.length > 1 ? 's' : ''}',
              style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted)),
        ]),
      ),
      Expanded(child: wishlist.isEmpty ? _buildEmpty(context) : SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Wrap(spacing: 12, runSpacing: 12, children: wishlist.map((p) {
          return SizedBox(width: cardWidth, child: ProductCard(
            product: p, isWishlisted: true,
            onTap: () => context.push('/product/${p['id']}'),
            onToggleWishlist: () => ref.read(wishlistProvider.notifier).remove(p['id']),
            onAddToCart: () {
              if (!auth.isAuthenticated) { context.push('/login'); return; }
              ref.read(cartProvider.notifier).addItem(p['id'].toString());
              ref.read(wishlistProvider.notifier).remove(p['id']);
              NotificationService.showSnackBar(context, '${p['name']} ajouté au panier');
            },
          ));
        }).toList()),
      )),
    ]));
  }

  Widget _buildEmpty(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(AppSpacing.xxl),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Lottie.network('https://assets10.lottiefiles.com/packages/lf20_786puxsh.json', width: 180, height: 180,
          errorBuilder: (_, e, s) => const Icon(FeatherIcons.heart, size: 80, color: AppColors.textMuted)),
      const SizedBox(height: 16),
      Text('Aucun article sauvegardé', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xxl, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text('Appuyez sur ♥ sur n\'importe quel produit pour le sauvegarder ici.', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary, height: 1.6), textAlign: TextAlign.center),
      const SizedBox(height: 28),
      GestureDetector(onTap: () => context.go('/'),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Text('Explorer la boutique', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: Colors.white)))),
    ]),
  ));
}
