import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';
import '../utils/currency.dart';

class CartItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = item['product'] as Map<String, dynamic>;
    final quantity = item['quantity'] as int;
    final imageUrl = product['image_url'] as String?;
    final price = double.tryParse(product['price'].toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 80, height: 80,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.border,
                      child: const Center(child: Icon(FeatherIcons.image, size: 24, color: AppColors.textMuted)),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((product['category'] as String?)?.toUpperCase() ?? 'OAYA',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.accent, letterSpacing: 1)),
                Text(product['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(formatCurrency(price * quantity),
                    style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 8),
                Row(children: [
                  _qtyBtn(FeatherIcons.minus, onDecrease),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$quantity', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  _qtyBtn(FeatherIcons.plus, onIncrease),
                ]),
              ],
            ),
          ),
          GestureDetector(onTap: onRemove, child: const Padding(padding: EdgeInsets.all(4), child: Icon(FeatherIcons.x, size: 18, color: AppColors.textMuted))),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
        child: Center(child: Icon(icon, size: 14, color: AppColors.primary)),
      ),
    );
  }
}
