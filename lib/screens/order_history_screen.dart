import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../widgets/order_card.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(backgroundColor: AppColors.background, body: SafeArea(child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(onTap: () => context.go('/profile'), child: const Padding(padding: EdgeInsets.all(4), child: Icon(FeatherIcons.arrowLeft, size: 22))),
          Text('Mes Commandes', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
          GestureDetector(onTap: () => ref.invalidate(ordersProvider), child: const Icon(FeatherIcons.refreshCw, size: 20)),
        ]),
      ),
      Expanded(child: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(FeatherIcons.alertTriangle, size: 48, color: AppColors.error), const SizedBox(height: 12),
          Text('Erreur de chargement', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
        ])),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(FeatherIcons.package, size: 48, color: AppColors.textMuted), const SizedBox(height: 12),
              Text('Aucune commande', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('Vos commandes apparaîtront ici', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted)),
              const SizedBox(height: 24),
              GestureDetector(onTap: () => context.go('/'),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Text('Explorer la boutique', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: Colors.white)))),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.base),
            itemCount: orders.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => context.push('/order/confirmation/${orders[i]['id']}'),
              child: OrderCard(order: orders[i]),
            ),
          );
        },
      )),
    ])));
  }
}
