import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../services/product_service.dart';
import '../services/notification_service.dart';
import '../widgets/hero_banner.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_box.dart';
import 'package:go_router/go_router.dart';

const _iconMap = <String, IconData>{
  'Tous': FeatherIcons.grid,
  'Vêtements': FeatherIcons.tag,
  'Accessoires': FeatherIcons.watch,
  'Montres': FeatherIcons.clock,
  'Bijoux': FeatherIcons.star,
  'Parfums': FeatherIcons.droplet,
  'Sneakers': FeatherIcons.anchor,
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _activeCategory = 'Tous';
  List<String> _categories = [];
  List<Map<String, dynamic>> _products = [];
  bool _catsLoading = true;
  bool _prodsLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ProductService.getCategories();
      if (mounted) setState(() { _categories = cats; _catsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _catsLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() { _prodsLoading = true; _error = null; });
    try {
      final prods = await ProductService.getProducts(category: _activeCategory);
      if (mounted) setState(() { _products = prods; _prodsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _prodsLoading = false; });
    }
  }

  void _selectCategory(String cat) {
    setState(() => _activeCategory = cat);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final cart = ref.watch(cartProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 12) / 2;

    return SafeArea(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            GestureDetector(onTap: () => context.push('/search'), child: const Icon(FeatherIcons.search, size: 22, color: AppColors.primary)),
            const Spacer(),
            Text('OAYA', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 6)),
            const Spacer(),
            if (auth.isAuthenticated)
              GestureDetector(onTap: () => ref.read(authProvider.notifier).signOut(), child: const Icon(FeatherIcons.logOut, size: 22, color: AppColors.primary))
            else
              GestureDetector(onTap: () => context.push('/login'), child: const Icon(FeatherIcons.user, size: 22, color: AppColors.primary)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => context.go('/cart'),
              child: Stack(children: [
                const Icon(FeatherIcons.shoppingBag, size: 22, color: AppColors.primary),
                if (cart.totalItems > 0)
                  Positioned(top: -5, right: -6, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(cart.totalItems > 9 ? '9+' : '${cart.totalItems}',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  )),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
                child: HeroBanner(onDiscoverTap: () => context.push('/search'))),
              Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xl, AppSpacing.base, AppSpacing.md),
                child: Text('Catégories', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
              SizedBox(height: 36, child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemCount: _catsLoading ? 4 : _categories.length,
                itemBuilder: (_, i) {
                  if (_catsLoading) return const SkeletonBox(width: 90, height: 36, borderRadius: 20);
                  final cat = _categories[i];
                  return CategoryChip(label: cat, icon: _iconMap[cat] ?? FeatherIcons.tag, active: _activeCategory == cat, onTap: () => _selectCategory(cat));
                },
              )),
              Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.xl, AppSpacing.base, AppSpacing.md),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_activeCategory == 'Tous' ? 'Tous les produits' : _activeCategory,
                      style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('${_products.length} articles', style: GoogleFonts.inter(fontSize: AppFontSize.xs, color: AppColors.textMuted)),
                ])),
              if (_error != null) _buildError()
              else if (_prodsLoading) _buildSkeletonGrid(cardWidth)
              else if (_products.isEmpty) _buildEmpty()
              else Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                child: Wrap(spacing: 12, runSpacing: 12, children: _products.map((p) {
                  return SizedBox(width: cardWidth, child: ProductCard(
                    product: p,
                    isWishlisted: ref.read(wishlistProvider.notifier).isWishlisted(p['id']),
                    onTap: () => context.push('/product/${p['id']}'),
                    onToggleWishlist: () => ref.read(wishlistProvider.notifier).toggle(p),
                    onAddToCart: () {
                      if (auth.isAuthenticated) {
                        ref.read(cartProvider.notifier).addItem(p['id'].toString());
                        NotificationService.showSnackBar(context, '${p['name']} ajouté au panier');
                      } else {
                        context.push('/login');
                      }
                    },
                  ));
                }).toList())),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildError() => Padding(padding: const EdgeInsets.all(AppSpacing.xl),
    child: Center(child: Column(children: [
      const Icon(FeatherIcons.wifiOff, size: 40, color: AppColors.textMuted), const SizedBox(height: 8),
      Text('Erreur', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      Text(_error ?? 'Vérifiez votre connexion', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted), textAlign: TextAlign.center),
    ])));

  Widget _buildEmpty() => Padding(padding: const EdgeInsets.only(top: 60),
    child: Center(child: Column(children: [
      const Icon(FeatherIcons.inbox, size: 48, color: AppColors.textMuted), const SizedBox(height: 8),
      Text('Aucun produit', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      Text('Essayez une autre catégorie', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted)),
    ])));

  Widget _buildSkeletonGrid(double w) => Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
    child: Wrap(spacing: 12, runSpacing: 12, children: List.generate(4, (_) => SizedBox(width: w, child: const ProductCardSkeleton()))));
}
