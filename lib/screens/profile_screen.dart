import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../services/order_service.dart';
import '../widgets/order_card.dart';

const _menuItems = [
  {'icon': FeatherIcons.mapPin, 'label': 'Mes adresses', 'sub': 'Gérer vos adresses de livraison', 'route': '/addresses'},
  {'icon': FeatherIcons.creditCard, 'label': 'Moyens de paiement', 'sub': 'Cartes et méthodes de paiement', 'route': '/payment-methods'},
  {'icon': FeatherIcons.star, 'label': 'Mes avis', 'sub': 'Produits que vous avez évalués', 'route': '/my-reviews'},
  {'icon': FeatherIcons.messageCircle, 'label': 'Support client', 'sub': 'Aide et assistance 24/7', 'route': '/support'},
  {'icon': FeatherIcons.settings, 'label': 'Paramètres', 'sub': 'Langue, confidentialité', 'route': '/settings'},
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _ordersLoading = true;

  @override
  void initState() { super.initState(); _loadOrders(); }

  Future<void> _loadOrders() async {
    try {
      final data = await OrderService.getOrders();
      if (mounted) setState(() { _orders = data; _ordersLoading = false; });
    } catch (_) { if (mounted) setState(() => _ordersLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final profile = auth.profile;
    final fullName = profile?['full_name'] as String?;
    final initialsRaw = fullName != null && fullName.trim().isNotEmpty
        ? fullName.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').join('').toUpperCase()
        : '';
    final initials = initialsRaw.isNotEmpty
        ? (initialsRaw.length > 2 ? initialsRaw.substring(0, 2) : initialsRaw)
        : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : '?');
    final displayName = profile?['full_name'] ?? user?.email?.split('@')[0] ?? 'Invité';

    return SafeArea(child: SingleChildScrollView(child: Column(children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.fromLTRB(AppSpacing.base, 16, AppSpacing.base, 36),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primarySoft])),
        child: Column(children: [
          Text('OAYA', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 6)),
          const SizedBox(height: 20),
          if (user != null) ...[
            Container(width: 84, height: 84, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 3)),
              child: Center(child: Text(initials, style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)))),
            const SizedBox(height: 12),
            Text(displayName, style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(user.email ?? '', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: Colors.white60)),
            if (auth.isAdmin) Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.full)),
              child: Text('ADMIN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1))),
          ] else ...[
            Container(width: 84, height: 84, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Center(child: Icon(FeatherIcons.user, size: 40, color: Colors.white70))),
            const SizedBox(height: 12),
            Text('Bonjour !', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Connectez-vous pour accéder à votre compte', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: Colors.white60), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(onTap: () => context.push('/login'),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11), decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Text('Se connecter', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: AppColors.primary)))),
              const SizedBox(width: 12),
              GestureDetector(onTap: () => context.push('/register'),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.white30)),
                  child: Text("S'inscrire", style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: Colors.white)))),
            ]),
          ],
        ]),
      ),
      // Orders
      if (user != null) Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xl, AppSpacing.base, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Mes commandes', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            GestureDetector(onTap: () => context.push('/orders'),
              child: Text('Voir tout', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.accent))),
          ]),
          const SizedBox(height: 12),
          if (_ordersLoading) Center(child: Text('Chargement...', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted)))
          else if (_orders.isEmpty) Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [const Icon(FeatherIcons.package, size: 32, color: AppColors.textMuted), const SizedBox(height: 8),
              Text("Aucune commande pour l'instant", style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted))])))
          else ...(_orders.take(3).map((o) => GestureDetector(onTap: () => context.push('/order/confirmation/${o['id']}'), child: OrderCard(order: o)))),
        ])),
      // Admin
      if (auth.isAdmin) Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xl, AppSpacing.base, 0),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.accent), boxShadow: AppShadow.card),
        child: Column(
          children: [
            ListTile(
              leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: const Center(child: Icon(FeatherIcons.users, size: 19, color: Color(0xFFB45309)))),
              title: Text('Gestion des Utilisateurs', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('Voir et gérer tous les comptes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              trailing: const Icon(FeatherIcons.chevronRight, size: 18, color: AppColors.textMuted),
              onTap: () => context.push('/admin/users'),
            ),
            const Divider(height: 1, color: AppColors.border),
            ListTile(
              leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: const Center(child: Icon(FeatherIcons.shoppingBag, size: 19, color: AppColors.primary))),
              title: Text('Gestion des Produits', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('Créer, modifier et supprimer les produits', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              trailing: const Icon(FeatherIcons.chevronRight, size: 18, color: AppColors.textMuted),
              onTap: () => context.push('/admin/products'),
            ),
            const Divider(height: 1, color: AppColors.border),
            ListTile(
              leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: const Center(child: Icon(FeatherIcons.package, size: 19, color: Color(0xFF15803D)))),
              title: Text('Gestion des Commandes', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('Mettre à jour le statut des commandes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              trailing: const Icon(FeatherIcons.chevronRight, size: 18, color: AppColors.textMuted),
              onTap: () => context.push('/admin/orders'),
            ),
          ],
        ),
      ),
      // Menu
      Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xl, AppSpacing.base, 0),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadow.card),
        child: Column(children: [
          // Notifications (with unread badge, wrapped in Consumer)
          Consumer(builder: (context, ref, _) {
            final unreadAsync = ref.watch(unreadNotificationCountProvider);
            final unread = unreadAsync.asData?.value ?? 0;
            return Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: ListTile(
                leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Center(child: const Icon(FeatherIcons.bell, size: 19, color: AppColors.primary))),
                title: Text('Notifications', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                subtitle: Text('Alertes et promotions', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                trailing: unread > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.full)),
                        child: Text('$unread', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      )
                    : const Icon(FeatherIcons.chevronRight, size: 18, color: AppColors.textMuted),
                onTap: () => context.push('/notification-inbox'),
              ),
            );
          }),
          // Other menu items
          ..._menuItems.map((item) => Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: ListTile(
              leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Center(child: Icon(item['icon'] as IconData, size: 19, color: AppColors.primary))),
              title: Text(item['label'] as String, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text(item['sub'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              trailing: const Icon(FeatherIcons.chevronRight, size: 18, color: AppColors.textMuted),
              onTap: () => context.push(item['route'] as String),
            ),
          )).toList(),
        ]),
      ),
      // Sign out
      if (user != null) GestureDetector(onTap: () => ref.read(authProvider.notifier).signOut(),
        child: Container(
          margin: const EdgeInsets.fromLTRB(AppSpacing.base, 16, AppSpacing.base, 0), padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: const Color(0xFFFECACA), width: 1.5), color: const Color(0xFFFEF2F2)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(FeatherIcons.logOut, size: 18, color: AppColors.error), const SizedBox(width: 8),
            Text('Se déconnecter', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.error)),
          ]),
        )),
      const SizedBox(height: 20),
      Text('OAYA v1.0.0', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
      const SizedBox(height: 40),
    ])));
  }
}
