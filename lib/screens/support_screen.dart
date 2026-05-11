import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(FeatherIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Support client', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Comment pouvons-nous vous aider ?', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xxl, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Notre équipe est disponible 24/7 pour vous assister.', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _card(context, FeatherIcons.messageCircle, 'Chat en direct', 'Discutez avec un conseiller', Colors.blue),
          const SizedBox(height: 12),
          _card(context, FeatherIcons.mail, 'Envoyer un email', 'support@oaya.store', AppColors.accent),
          const SizedBox(height: 12),
          _card(context, FeatherIcons.phone, 'Appeler', '+216 XX XXX XXX', Colors.green),
          const SizedBox(height: 12),
          _card(context, FeatherIcons.helpCircle, 'FAQ', 'Questions fréquentes', AppColors.primary),
          const SizedBox(height: 32),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadow.card),
            child: Column(children: [
              Text('Horaires', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Lun - Ven: 9h00 - 18h00', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
              Text('Sam: 10h00 - 14h00', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
              Text('Dim: Fermé', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadow.card),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Center(child: Icon(icon, size: 22, color: color))),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
        trailing: const Icon(FeatherIcons.chevronRight, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}
