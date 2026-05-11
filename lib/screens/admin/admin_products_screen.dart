import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/theme.dart';
import '../../services/product_service.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ProductService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? product}) async {
    final nameController = TextEditingController(text: product?['name']?.toString() ?? '');
    final descriptionController = TextEditingController(text: product?['description']?.toString() ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final originalPriceController = TextEditingController(text: product?['original_price']?.toString() ?? '');
    final imageUrlController = TextEditingController(text: product?['image_url']?.toString() ?? '');
    final categoryController = TextEditingController(text: product?['category']?.toString() ?? '');
    final badgeController = TextEditingController(text: product?['badge']?.toString() ?? '');
    final stockController = TextEditingController(text: product?['stock']?.toString() ?? '0');
    var active = (product?['active'] ?? true) == true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(product == null ? 'Nouveau produit' : 'Modifier le produit'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _field(nameController, 'Nom'),
                      _field(descriptionController, 'Description', maxLines: 3),
                      _field(priceController, 'Prix', keyboardType: TextInputType.number),
                      _field(originalPriceController, 'Prix initial', keyboardType: TextInputType.number),
                      _field(imageUrlController, 'Image URL'),
                      _field(categoryController, 'Catégorie'),
                      _field(badgeController, 'Badge'),
                      _field(stockController, 'Stock', keyboardType: TextInputType.number),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: active,
                        title: const Text('Actif'),
                        onChanged: (value) => setDialogState(() => active = value),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
                FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Enregistrer')),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final payload = <String, dynamic>{
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0,
      'original_price': double.tryParse(originalPriceController.text.trim()) ?? 0,
      'image_url': imageUrlController.text.trim(),
      'category': categoryController.text.trim(),
      'badge': badgeController.text.trim(),
      'stock': int.tryParse(stockController.text.trim()) ?? 0,
      'active': active,
    };

    try {
      if (product == null) {
        await ProductService.createProduct(payload);
      } else {
        await ProductService.updateProduct(product['id'].toString(), payload);
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produit enregistré')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le produit ?'),
          content: Text('Cette action supprimera ${product['name']}.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Supprimer')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ProductService.deleteProduct(product['id'].toString());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _products.where((product) => product['active'] == true).length;
    final inactiveCount = _products.length - activeCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(AppSpacing.base),
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primarySoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Icon(FeatherIcons.arrowLeft, size: 18, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _load,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(FeatherIcons.refreshCw, size: 18, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Gestion des Produits',
                    style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Créer, modifier et supprimer les produits avec une interface cohérente avec OAYA.',
                    style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statTile(label: 'Total', value: '${_products.length}'),
                      const SizedBox(width: 12),
                      _statTile(label: 'Actifs', value: '$activeCount'),
                      const SizedBox(width: 12),
                      _statTile(label: 'Inactifs', value: '$inactiveCount'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
                          ),
                        )
                      : _products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(FeatherIcons.package, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text('Aucun produit trouvé', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl),
                              itemCount: _products.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final product = _products[index];
                                final active = product['active'] == true;
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                    boxShadow: AppShadow.card,
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 62,
                                            height: 62,
                                            decoration: BoxDecoration(
                                              color: AppColors.accentLight,
                                              borderRadius: BorderRadius.circular(AppRadius.lg),
                                            ),
                                            child: const Icon(FeatherIcons.shoppingBag, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(product['name']?.toString() ?? '', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                                    ),
                                                    _statusChip(active ? 'Actif' : 'Inactif', active ? AppColors.success : AppColors.error),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(product['category']?.toString() ?? 'Sans catégorie', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted)),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    _metaPill('Prix', '${product['price'] ?? 0}'),
                                                    _metaPill('Stock', '${product['stock'] ?? 0}'),
                                                    if ((product['badge'] as String?)?.isNotEmpty == true) _metaPill('Badge', product['badge'].toString()),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.tonal(
                                              onPressed: () => _openEditor(product: product),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: AppColors.accentLight,
                                                foregroundColor: AppColors.primary,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                              ),
                                              child: const Text('Modifier'),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: FilledButton(
                                              onPressed: () => _deleteProduct(product),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xFFFEE2E2),
                                                foregroundColor: AppColors.error,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                              ),
                                              child: const Text('Supprimer'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _metaPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text('$label: $value', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
}
