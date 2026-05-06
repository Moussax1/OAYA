import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../services/product_service.dart';
import '../services/notification_service.dart';
import '../utils/currency.dart';
import '../widgets/skeleton_box.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  bool _loading = true;
  bool _addedToCart = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final p = await ProductService.getProduct(widget.productId);
      if (mounted) setState(() { _product = p; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton(context);
    if (_product == null) return _buildError(context);

    final auth = ref.watch(authProvider);
    final product = _product!;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageUrl = product['image_url'] as String?;
    final price = double.tryParse(product['price'].toString()) ?? 0;
    final originalPrice = double.tryParse((product['original_price'] ?? '0').toString()) ?? 0;
    final hasDiscount = originalPrice > 0 && originalPrice > price;
    final discount = hasDiscount ? ((1 - price / originalPrice) * 100).round() : 0;
    final wishlisted = ref.read(wishlistProvider.notifier).isWishlisted(product['id']);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        SingleChildScrollView(child: Column(children: [
          Stack(children: [
            SizedBox(width: screenWidth, height: screenWidth * 1.1,
              child: imageUrl != null ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover) : Container(color: AppColors.border, child: const Center(child: Icon(FeatherIcons.image, size: 60, color: AppColors.textMuted)))),
            Positioned(top: 0, left: 0, right: 0, child: Container(
              height: 100,
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x59000000), Colors.transparent])),
              padding: EdgeInsets.fromLTRB(AppSpacing.base, MediaQuery.of(context).padding.top + 12, AppSpacing.base, 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                GestureDetector(onTap: () => context.pop(),
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                    child: const Icon(FeatherIcons.arrowLeft, size: 20, color: Colors.white))),
                GestureDetector(onTap: () => ref.read(wishlistProvider.notifier).toggle(product),
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                    child: Icon(FeatherIcons.heart, size: 20, color: wishlisted ? AppColors.sale : Colors.white))),
              ]),
            )),
            if (hasDiscount) Positioned(bottom: 16, left: 16,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.sale, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Text('-$discount%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)))),
          ]),
          Padding(padding: const EdgeInsets.all(AppSpacing.base), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((product['category'] as String?)?.toUpperCase() ?? 'OAYA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent, letterSpacing: 2)),
            const SizedBox(height: 6),
            Text(product['name'] ?? '', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3)),
            const SizedBox(height: 12),
            Row(children: [
              Text(formatCurrency(price), style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
              if (hasDiscount) ...[const SizedBox(width: 10),
                Text(formatCurrency(originalPrice), style: GoogleFonts.inter(fontSize: 16, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Text('Économisez $discount%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success))),
              ],
            ]),
            Container(height: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: AppSpacing.base)),
            Text('Description', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(product['description'] ?? 'Découvrez ce produit exclusif de notre collection OAYA. Qualité premium, design moderne.',
                style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary, height: 1.7)),
            const SizedBox(height: 120),
          ])),
        ])),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(
          padding: EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(color: AppColors.surface, border: const Border(top: BorderSide(color: AppColors.border)), boxShadow: AppShadow.sheet),
          child: Row(children: [
            GestureDetector(onTap: () => ref.read(wishlistProvider.notifier).toggle(product),
              child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border, width: 1.5)),
                child: Icon(FeatherIcons.heart, size: 22, color: wishlisted ? AppColors.sale : AppColors.primary))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () {
                if (!auth.isAuthenticated) { context.push('/login'); return; }
                ref.read(cartProvider.notifier).addItem(product['id'].toString());
                NotificationService.showSnackBar(context, '${product['name']} ajouté au panier');
                setState(() => _addedToCart = true); Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _addedToCart = false); });
              },
              child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(color: _addedToCart ? AppColors.success : AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_addedToCart ? FeatherIcons.check : FeatherIcons.shoppingBag, size: 18, color: Colors.white), const SizedBox(width: 8),
                  Text(_addedToCart ? 'Ajouté !' : 'Ajouter au panier', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: Colors.white)),
                ])))),
            const SizedBox(width: 10),
            GestureDetector(onTap: () {
              if (!auth.isAuthenticated) { context.push('/login'); return; }
              ref.read(cartProvider.notifier).addItem(product['id'].toString()); context.go('/cart');
            },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18), decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Text('Acheter', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: AppColors.primary)))),
          ]),
        )),
      ]),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(backgroundColor: AppColors.background, body: Column(children: [
      SkeletonBox(width: w, height: w * 1.1), Padding(padding: const EdgeInsets.all(AppSpacing.base), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SkeletonBox(width: 100, height: 14), SizedBox(height: 12), SkeletonBox(width: 250, height: 26), SizedBox(height: 12), SkeletonBox(width: 80, height: 22), SizedBox(height: 16), SkeletonBox(height: 1), SizedBox(height: 16), SkeletonBox(height: 80),
      ])),
    ]));
  }

  Widget _buildError(BuildContext context) => Scaffold(backgroundColor: AppColors.background,
    body: SafeArea(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(FeatherIcons.alertCircle, size: 48, color: AppColors.textMuted), const SizedBox(height: 16),
      Text('Produit introuvable', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      GestureDetector(onTap: () => context.pop(),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Text('Retour', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: Colors.white)))),
    ]))));
}
