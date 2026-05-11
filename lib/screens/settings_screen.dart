import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(FeatherIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Paramètres', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
      ),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.base), children: [
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadow.card),
          child: Column(children: [
            _tile(context, FeatherIcons.globe, 'Langue', 'Français', onTap: () => _showLangPicker(context)),
            const Divider(height: 1, color: AppColors.border),
            _tile(context, FeatherIcons.moon, 'Thème sombre', null, trailing: Switch(value: false, onChanged: (_) {}, activeColor: AppColors.accent)),
            const Divider(height: 1, color: AppColors.border),
            _tile(context, FeatherIcons.shield, 'Confidentialité', 'Gérer vos données'),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadow.card),
          child: Column(children: [
            _tile(context, FeatherIcons.info, 'À propos', 'Version 1.0.0'),
            const Divider(height: 1, color: AppColors.border),
            _tile(context, FeatherIcons.fileText, 'Conditions d\'utilisation', null),
            const Divider(height: 1, color: AppColors.border),
            _tile(context, FeatherIcons.lock, 'Politique de confidentialité', null),
          ]),
        ),
        if (auth.isAuthenticated) ...[
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Supprimer le compte'),
                content: const Text('Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                ],
              ));
              if (confirm == true && context.mounted) {
                ref.read(authProvider.notifier).signOut();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte supprimé'), behavior: SnackBarBehavior.floating));
              }
            },
            icon: const Icon(FeatherIcons.trash2, size: 16, color: Colors.red),
            label: Text('Supprimer mon compte', style: GoogleFonts.inter(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
          )),
        ],
        const SizedBox(height: 40),
      ]),
    );
  }

  void _showLangPicker(BuildContext context) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(title: Text('Français', style: GoogleFonts.inter()), leading: const Icon(FeatherIcons.check, color: AppColors.accent), onTap: () { Navigator.pop(ctx); }),
      ListTile(title: Text('English', style: GoogleFonts.inter()), onTap: () { Navigator.pop(ctx); }),
      ListTile(title: Text('العربية', style: GoogleFonts.inter()), onTap: () { Navigator.pop(ctx); }),
    ])));
  }

  Widget _tile(BuildContext context, IconData icon, String title, String? subtitle, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Center(child: Icon(icon, size: 19, color: AppColors.primary))),
      title: Text(title, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)) : null,
      trailing: trailing ?? const Icon(FeatherIcons.chevronRight, size: 18, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
