import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';


class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(userReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(FeatherIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Mes avis', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
      ),
      body: reviews.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(FeatherIcons.star, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Aucun avis pour le moment', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Évaluez les produits que vous avez achetés', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.base),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              final product = r['product'] as Map<String, dynamic>?;
              final rating = r['rating'] as int? ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadow.card),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: product?['image_url'] != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Image.network(product!['image_url'], fit: BoxFit.cover))
                        : const Center(child: Icon(FeatherIcons.image, size: 20, color: AppColors.textMuted)),
                  ),
                  title: Text(product?['name'] ?? 'Produit', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 4),
                    Row(children: List.generate(5, (i) => Icon(i < rating ? FeatherIcons.star : FeatherIcons.star, size: 14, color: i < rating ? const Color(0xFFF59E0B) : AppColors.textMuted))),
                    if (r['comment'] != null && (r['comment'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r['comment'], style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
                    ],
                  ]),
                  trailing: TextButton(
                    onPressed: () => context.push('/product/${product?['id']}'),
                    child: Text('Voir', style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
