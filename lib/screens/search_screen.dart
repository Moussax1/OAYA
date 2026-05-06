import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../services/product_service.dart';
import '../utils/currency.dart';

const _suggested = ['Montres', 'Sneakers blancs', 'Parfum', 'Bijoux', 'Veste', 'Sac cuir'];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _submitted = '';
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  void _search(String q) async {
    setState(() { _submitted = q; _loading = true; });
    try {
      final data = await ProductService.getProducts(searchQuery: q);
      if (mounted) setState(() { _results = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Text('Recherche', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      // Search bar
      Container(
        margin: const EdgeInsets.all(AppSpacing.base),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, width: 1.5), boxShadow: AppShadow.card),
        child: Row(children: [
          const Icon(FeatherIcons.search, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: _controller,
            decoration: InputDecoration.collapsed(hintText: 'Rechercher un produit...', hintStyle: GoogleFonts.inter(color: AppColors.textMuted)),
            style: GoogleFonts.inter(fontSize: AppFontSize.base, color: AppColors.textPrimary),
            onSubmitted: _search,
            textInputAction: TextInputAction.search,
          )),
          if (_controller.text.isNotEmpty) GestureDetector(
            onTap: () { _controller.clear(); setState(() { _submitted = ''; _results = []; }); },
            child: const Icon(FeatherIcons.x, size: 18, color: AppColors.textMuted)),
        ]),
      ),
      // Body
      Expanded(child: _submitted.isEmpty ? _buildSuggestions()
          : _loading ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _results.isEmpty ? _buildEmpty()
          : _buildResults()),
    ]));
  }

  Widget _buildSuggestions() => Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tendances', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: _suggested.map((tag) => GestureDetector(
        onTap: () { _controller.text = tag; _search(tag); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: AppColors.border)),
          child: Text(tag, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ),
      )).toList()),
    ]));

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(FeatherIcons.search, size: 48, color: AppColors.textMuted),
    const SizedBox(height: 8),
    Text('Aucun résultat', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
    Text('pour « $_submitted »', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted)),
  ]));

  Widget _buildResults() => ListView.separated(
    padding: const EdgeInsets.all(AppSpacing.base),
    itemCount: _results.length + 1,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (ctx, i) {
      if (i == 0) return Text('${_results.length} résultat(s) pour « $_submitted »',
          style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted));
      final p = _results[i - 1];
      final img = p['image_url'] as String?;
      return GestureDetector(
        onTap: () => context.push('/product/${p['id']}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadow.card),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(width: 72, height: 72,
                child: img != null ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover) : Container(color: AppColors.border, child: const Center(child: Icon(FeatherIcons.image, size: 24, color: AppColors.textMuted))))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((p['category'] as String?)?.toUpperCase() ?? '', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.accent, letterSpacing: 1)),
              Text(p['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(formatCurrency(p['price']), style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ])),
            const Icon(FeatherIcons.chevronRight, size: 18, color: AppColors.textMuted),
          ]),
        ),
      );
    },
  );
}
