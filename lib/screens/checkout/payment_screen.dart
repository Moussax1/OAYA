import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../constants/theme.dart';
import '../../providers/providers.dart';
import '../../services/order_service.dart';
import '../../services/stripe_service.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/currency.dart';
import '../../widgets/progress_stepper.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _method = 'cod';
  bool _loading = false;
  String _error = '';

  Future<void> _handleCOD() async {
    final cart = ref.read(cartProvider);
    final auth = ref.read(authProvider);
    if (auth.user == null) return;
    try {
      setState(() { _loading = true; _error = ''; });
      final shipping = cart.totalPrice > 100 ? 0.0 : 9.99;
      final items = cart.items.map((item) {
        final product = item['product'] as Map<String, dynamic>;
        return {'product': product, 'quantity': item['quantity']};
      }).toList();
      final order = await OrderService.createOrder(items: items, shipping: shipping, total: cart.totalPrice + shipping, userId: auth.user!.id);
      await ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(ordersProvider);
      // Create notification
      await NotificationService.createNotification(userId: auth.user!.id, title: 'Commande confirmée', body: 'Votre commande #${order['id'].toString().substring(0, 8)} a été reçue.');
      if (mounted) {
        await NotificationService.showResultDialog(context, title: 'Paiement réussi', message: 'Votre commande a été confirmée !', isSuccess: true);
        context.go('/order/confirmation/${order['id']}');
      }
    } catch (e) {
      if (mounted) {
        await NotificationService.showResultDialog(context, title: 'Erreur', message: e.toString(), isSuccess: false);
        setState(() { _error = e.toString(); _loading = false; });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleStripe() async {
    final auth = ref.read(authProvider);
    if (auth.user == null) return;
    try {
      setState(() { _loading = true; _error = ''; });
      final cartSnap = ref.read(cartProvider);
      final shipping = cartSnap.totalPrice > 100 ? 0.0 : 9.99;
      final total = cartSnap.totalPrice + shipping;
      final items = cartSnap.items.map((item) {
        final product = item['product'] as Map<String, dynamic>;
        return {'product': product, 'quantity': item['quantity']};
      }).toList();

      final paymentData = await StripeService.createPaymentIntent(amount: total, currency: 'eur');

      final order = await OrderService.createOrder(
        items: items, shipping: shipping, total: total,
        userId: auth.user!.id,
        paymentMethod: 'stripe',
        stripePaymentId: paymentData['paymentIntentId'] as String?,
      );

      await StripeService.presentPaymentSheet(
        context: context, clientSecret: paymentData['clientSecret'] as String,
        customerName: auth.user!.userMetadata?['full_name'],
        customerEmail: auth.user!.email,
      );

      await ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(ordersProvider);
      await NotificationService.createNotification(
        userId: auth.user!.id, title: 'Paiement réussi',
        body: 'Commande #${order['id'].toString().substring(0, 8)} payée par carte.',
      );
      // Fire-and-forget: email must not block the success screen
      _sendOrderEmail(order['id'].toString(), auth.user!.email ?? '');
      if (mounted) {
        await NotificationService.showResultDialog(
          context, title: 'Paiement réussi',
          message: 'Votre paiement a été accepté !', isSuccess: true,
        );
        context.go('/order/confirmation/${order['id']}');
      }
    } on StripeException {
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        await NotificationService.showResultDialog(
          context, title: 'Paiement échoué',
          message: msg, isSuccess: false,
        );
        setState(() { _error = msg; _loading = false; });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOrderEmail(String orderId, String email) async {
    try {
      await SupabaseService.client.functions.invoke('send-order-email', body: {'order_id': orderId, 'user_email': email});
    } catch (e, st) {
      debugPrint('[PaymentScreen] sendOrderEmail error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final shipping = cart.totalPrice > 100 ? 0.0 : 9.99;
    final finalTotal = cart.totalPrice + shipping;

    return Scaffold(backgroundColor: AppColors.background, body: SafeArea(child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: () => context.pop(),
            icon: const Icon(FeatherIcons.arrowLeft, size: 22),
          ),
          Text('Paiement', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
          const SizedBox(width: 30),
        ]),
      ),
      const ProgressStepper(currentStep: 2),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.xl), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mode de paiement', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Choisissez comment vous souhaitez payer', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        if (_error.isNotEmpty) Container(
          margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFFECACA))),
          child: Row(children: [const Icon(FeatherIcons.alertCircle, size: 16, color: AppColors.error), const SizedBox(width: 8),
            Expanded(child: Text(_error, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.error)))])),
        _paymentOption('cod', FeatherIcons.truck, 'Paiement à la livraison', 'Payer en espèces ou carte à réception'),
        const SizedBox(height: 12),
        _paymentOption('stripe', FeatherIcons.creditCard, 'Carte Bancaire', 'Visa, Mastercard — Paiement sécurisé Stripe', trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFF635BFF), borderRadius: BorderRadius.circular(6)),
          child: Text('Stripe', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))),
        if (_method == 'stripe') Container(
          margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFEFCE8), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.accentLight)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(FeatherIcons.info, size: 13, color: AppColors.accent), const SizedBox(width: 8),
            Expanded(child: RichText(text: TextSpan(style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5), children: [
              const TextSpan(text: 'En mode test : carte '),
              TextSpan(text: '4242 4242 4242 4242', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' · exp. 12/26 · CVC 123'),
            ])))])),
        const SizedBox(height: AppSpacing.xl),
        Text('Récapitulatif', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadow.card),
          child: Column(children: [
            _summaryRow('Articles (${cart.totalItems})', formatCurrency(cart.totalPrice)),
            const SizedBox(height: 12),
            _summaryRow('Livraison', shipping == 0 ? 'Gratuite' : formatCurrency(shipping), valueColor: shipping == 0 ? AppColors.success : null),
            Container(height: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 12)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total à payer', style: GoogleFonts.inter(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
              Text(formatCurrency(finalTotal), style: GoogleFonts.inter(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
          ])),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(FeatherIcons.lock, size: 13, color: AppColors.textMuted), const SizedBox(width: 6),
          Expanded(child: Text('Paiement sécurisé SSL', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted))),
        ]),
      ]))),
      Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(color: AppColors.surface, border: const Border(top: BorderSide(color: AppColors.border)), boxShadow: AppShadow.sheet),
        child: Semantics(
          button: true,
          enabled: !_loading,
          label: _method == 'stripe' ? 'Payer par carte' : 'Confirmer la commande',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: _loading ? null : () { _method == 'stripe' ? _handleStripe() : _handleCOD(); },
              child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: _loading ? 0.7 : 1), borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Center(child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_method == 'stripe' ? FeatherIcons.creditCard : FeatherIcons.checkCircle, size: 18, color: Colors.white), const SizedBox(width: 10),
                        Text(_method == 'stripe' ? 'Payer par carte' : 'Confirmer la commande',
                            style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]))),
            ),
          ),
        ),
      ),
    ])));
  }

  Widget _paymentOption(String value, IconData icon, String title, String sub, {Widget? trailing}) {
    final active = _method == value;
    return Semantics(
      button: true,
      selected: active,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => setState(() => _method = value),
          child: Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: active ? const Color(0xFFFEFCE8) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: active ? AppColors.accent : AppColors.border, width: 1.5)),
            child: Row(children: [
              Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: active ? AppColors.accent : AppColors.textMuted, width: 2)),
                child: active ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle))) : null),
              const SizedBox(width: 16),
              Icon(icon, size: 24, color: active ? AppColors.primary : AppColors.textMuted), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w600, color: active ? AppColors.primary : AppColors.textSecondary)),
                Text(sub, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ])),
              if (trailing != null) trailing,
            ])),
        ),
      ),
    );
  }

  Widget _summaryRow(String l, String v, {Color? valueColor}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(l, style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
    Text(v, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
  ]);
}
