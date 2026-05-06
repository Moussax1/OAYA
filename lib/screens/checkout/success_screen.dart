import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [AppColors.background, Color(0xFFFEFCE8)],
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animation
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.1), offset: const Offset(0, 10), blurRadius: 20)],
                ),
                child: ClipOval(
                  child: Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_6u60fscy.json',
                    width: 120, height: 120, repeat: false,
                    errorBuilder: (_, __, ___) => const Icon(FeatherIcons.checkCircle, size: 60, color: AppColors.success),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Commande Confirmée !', textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text('Merci pour votre achat. Votre commande a été reçue et sera traitée dans les plus brefs délais.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: AppFontSize.base, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 40),
              // Details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(FeatherIcons.package, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(child: Text("Vous recevrez un email avec les détails d'expédition.",
                        style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(FeatherIcons.clock, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Livraison estimée : 3 à 5 jours ouvrés.',
                        style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4))),
                  ]),
                ]),
              ),
              const SizedBox(height: 40),
              // Buttons
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Center(child: Text('Voir mes commandes',
                      style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.go('/'),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text("Retour à l'accueil",
                      style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
