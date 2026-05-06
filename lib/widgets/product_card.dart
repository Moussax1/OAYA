import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';
import '../utils/currency.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onToggleWishlist;
  final VoidCallback onAddToCart;
  final bool isWishlisted;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onToggleWishlist,
    required this.onAddToCart,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['image_url'] as String?;
    final price = double.tryParse(product['price'].toString()) ?? 0;
    final originalPrice =
        double.tryParse((product['original_price'] ?? '0').toString()) ?? 0;
    final hasDiscount = originalPrice > 0 && originalPrice > price;
    final discountPct = hasDiscount
        ? ((1 - price / originalPrice) * 100).round()
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadow.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 0.8,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.borderLight,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.borderLight,
                            child: const Center(
                              child: Icon(FeatherIcons.image,
                                  size: 28, color: AppColors.textMuted),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.borderLight,
                          child: const Center(
                            child: Icon(FeatherIcons.image,
                                size: 28, color: AppColors.textMuted),
                          ),
                        ),
                ),
                // Wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onToggleWishlist,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        FeatherIcons.heart,
                        size: 15,
                        color:
                            isWishlisted ? AppColors.sale : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sale,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '-$discountPct%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (product['category'] as String?)?.toUpperCase() ?? 'OAYA',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product['name'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatCurrency(price),
                        style: GoogleFonts.inter(
                          fontSize: AppFontSize.base,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          formatCurrency(originalPrice),
                          style: GoogleFonts.inter(
                            fontSize: AppFontSize.sm,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Quick add button
                  GestureDetector(
                    onTap: onAddToCart,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FeatherIcons.shoppingBag,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            'Ajouter',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
