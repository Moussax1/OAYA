import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../services/payment_method_service.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(paymentMethodsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(FeatherIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Moyens de paiement', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
      ),
      body: methods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(FeatherIcons.creditCard, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Aucun moyen de paiement', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Ajoutez une carte pour payer plus rapidement', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.base),
            itemCount: list.length + 1,
            itemBuilder: (_, i) {
              if (i == list.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Ajoutez une carte lors de votre prochain paiement Stripe'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    icon: const Icon(FeatherIcons.plus, size: 16),
                    label: Text('Ajouter une carte', style: GoogleFonts.inter()),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent),
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  )),
                );
              }
              final m = list[i];
              final isDefault = m['is_default'] == true;
              final isCard = m['type'] == 'stripe';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: isDefault ? AppColors.accent : AppColors.border), boxShadow: AppShadow.card),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Center(child: Icon(isCard ? FeatherIcons.creditCard : FeatherIcons.truck, size: 22, color: AppColors.primary))),
                  title: Text(isCard ? 'Carte ${m['brand'] ?? 'Bancaire'} **** ${m['last_four'] ?? ''}' : 'Paiement à la livraison', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Row(children: [
                    if (isDefault) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.full)), child: Text('Par défaut', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent))), const SizedBox(width: 8)],
                    Text(isCard ? 'Stripe' : 'COD', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                  ]),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Supprimer'), content: const Text('Supprimer ce moyen de paiement ?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red)))]));
                        if (confirm == true) {
                          await PaymentMethodService.deletePaymentMethod(m['id']);
                          ref.invalidate(paymentMethodsProvider);
                        }
                      } else if (v == 'default') {
                        final auth = ref.read(authProvider);
                        if (auth.user != null) {
                          await PaymentMethodService.setDefault(m['id'], auth.user!.id);
                          ref.invalidate(paymentMethodsProvider);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      if (!isDefault) const PopupMenuItem(value: 'default', child: Row(children: [Icon(FeatherIcons.check, size: 16), SizedBox(width: 8), Text('Définir par défaut')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(FeatherIcons.trash2, size: 16, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
                    ],
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
