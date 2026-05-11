import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../services/address_service.dart';

class AddressListScreen extends ConsumerStatefulWidget {
  const AddressListScreen({super.key});
  @override
  ConsumerState<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends ConsumerState<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(addressesProvider);
    });
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await AddressService.deleteAddress(id);
      ref.invalidate(addressesProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse supprimée'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(FeatherIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Mes adresses', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.plus, color: AppColors.accent),
            onPressed: () => context.push('/addresses/new').then((_) => ref.invalidate(addressesProvider)),
          ),
        ],
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(FeatherIcons.mapPin, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Aucune adresse enregistrée', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Ajoutez une adresse pour faciliter vos commandes', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/addresses/new').then((_) => ref.invalidate(addressesProvider)),
                icon: const Icon(FeatherIcons.plus, size: 16),
                label: Text('Ajouter une adresse'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
              ),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.base),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final a = list[i];
              final isDefault = a['is_default'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: isDefault ? AppColors.accent : AppColors.border), boxShadow: AppShadow.card),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(children: [
                    Text(a['full_name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    if (isDefault) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.full)), child: Text('Défaut', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)))],
                  ]),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 4),
                    Text(a['address'] ?? '', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
                    Text('${a['postal_code']} ${a['city']}', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
                    Text(a['phone'] ?? '', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
                  ]),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Supprimer'), content: const Text('Supprimer cette adresse ?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red)))]));
                        if (confirm == true) _deleteAddress(a['id']);
                      } else if (v == 'default') {
                        await AddressService.updateAddress(addressId: a['id'], isDefault: true);
                        ref.invalidate(addressesProvider);
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
