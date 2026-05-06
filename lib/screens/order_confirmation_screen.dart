import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../services/order_service.dart';
import '../utils/currency.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderConfirmationScreen({super.key, required this.orderId});
  @override
  ConsumerState<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final orders = await OrderService.getOrders();
      final match = orders.where((o) => o['id'] == widget.orderId);
      if (match.isNotEmpty) { _order = match.first; }
      if (mounted) setState(() => _loading = false);
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    if (_order == null) return Scaffold(body: SafeArea(child: Center(child: Text('Commande introuvable'))));

    final items = _order!['order_items'] as List? ?? [];
    final date = DateTime.tryParse(_order!['created_at'] ?? '');
    final dateStr = date != null ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}' : '';

    return Scaffold(backgroundColor: AppColors.background, body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(width: 80, height: 80, decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
          child: const Center(child: Icon(FeatherIcons.checkCircle, size: 40, color: AppColors.success))),
        const SizedBox(height: 20),
        Text('Commande Confirmée !', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Merci pour votre achat', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        // Receipt card
        Container(
          width: double.infinity, padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadow.card),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('REÇU', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 2)),
            const SizedBox(height: 12),
            _row('N° Commande', '#${widget.orderId.substring(0, 8).toUpperCase()}'),
            _row('Date', dateStr),
            _row('Statut', _order!['status']?.toString().toUpperCase() ?? 'PENDING'),
            _row('Paiement', _order!['payment_method'] == 'stripe' ? 'Carte bancaire' : 'À la livraison'),
            Container(height: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 12)),
            Text('Articles', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ...items.map((item) {
              final product = item['product'] as Map<String, dynamic>? ?? {};
              return Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text('${product['name'] ?? 'Produit'} × ${item['quantity']}', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary))),
                  Text(formatCurrency(item['unit_price'] * item['quantity']), style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ]));
            }),
            Container(height: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 12)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: GoogleFonts.inter(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(formatCurrency(_order!['total_amount'] ?? _order!['total']), style: GoogleFonts.inter(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Row(children: [const Icon(FeatherIcons.clock, size: 14, color: Color(0xFF2563EB)), const SizedBox(width: 8),
            Expanded(child: Text('Livraison estimée : 3 à 5 jours ouvrés.', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: Color(0xFF2563EB))))])),
        const SizedBox(height: 28),
        GestureDetector(onTap: () => context.go('/orders'),
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Center(child: Text('Voir mes commandes', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: Colors.white))))),
        const SizedBox(height: 12),
        GestureDetector(onTap: () => context.go('/'),
          child: Center(child: Text("Retour à l'accueil", style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w600, color: AppColors.textSecondary)))),
      ]),
    )));
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
      Text(value, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]));
}
