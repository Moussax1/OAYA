import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/theme.dart';
import '../services/notification_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  Future<void> _handleUpdate() async {
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (password.isEmpty || password.length < 6) {
      NotificationService.showResultDialog(context, title: 'Erreur', message: 'Le mot de passe doit contenir au moins 6 caractères.', isSuccess: false);
      return;
    }
    if (password != confirm) {
      NotificationService.showResultDialog(context, title: 'Erreur', message: 'Les mots de passe ne correspondent pas.', isSuccess: false);
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (mounted) {
        await NotificationService.showResultDialog(
          context,
          title: 'Succès',
          message: 'Votre mot de passe a été mis à jour avec succès.',
          isSuccess: true,
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showResultDialog(
          context,
          title: 'Erreur',
          message: e.toString(),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.go('/'),
          child: const Icon(FeatherIcons.arrowLeft, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouveau mot de passe', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Veuillez entrer votre nouveau mot de passe.', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              Text('Nouveau mot de passe', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.border)),
                child: TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.inter(fontSize: AppFontSize.base),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FeatherIcons.lock, size: 18, color: AppColors.textMuted),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(_obscure ? FeatherIcons.eye : FeatherIcons.eyeOff, size: 18, color: AppColors.textMuted),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Confirmer le mot de passe', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.border)),
                child: TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: GoogleFonts.inter(fontSize: AppFontSize.base),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FeatherIcons.lock, size: 18, color: AppColors.textMuted),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      child: Icon(_obscureConfirm ? FeatherIcons.eye : FeatherIcons.eyeOff, size: 18, color: AppColors.textMuted),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _loading ? null : _handleUpdate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Center(
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Mettre à jour', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
