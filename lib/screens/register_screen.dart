import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPw = false, _loading = false, _done = false;
  String _error = '';

  Future<void> _handleRegister() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) { setState(() => _error = 'Veuillez remplir tous les champs.'); return; }
    if (_passwordCtrl.text.length < 6) { setState(() => _error = 'Mot de passe trop court (6 caractères minimum).'); return; }
    if (_passwordCtrl.text != _confirmCtrl.text) { setState(() => _error = 'Les mots de passe ne correspondent pas.'); return; }
    try {
      setState(() { _loading = true; _error = ''; });
      await ref.read(authProvider.notifier).signUp(_emailCtrl.text, _passwordCtrl.text, _nameCtrl.text);
      setState(() { _done = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally { if (mounted && !_done) setState(() => _loading = false); }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passwordCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_done) return _buildSuccess(context);

    return Scaffold(body: Column(children: [
      Container(width: double.infinity, padding: EdgeInsets.fromLTRB(AppSpacing.base, MediaQuery.of(context).padding.top + 10, AppSpacing.base, 28),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)])),
        child: Stack(children: [
          Positioned(left: 0, top: 0, child: GestureDetector(onTap: () => context.pop(), child: const Padding(padding: EdgeInsets.all(6), child: Icon(FeatherIcons.arrowLeft, size: 22, color: AppColors.primary)))),
          Center(child: Column(children: [
            Text('OAYA', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 8)),
            const SizedBox(height: 4),
            Text('Créer un compte', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.primary, letterSpacing: 1)),
          ])),
        ])),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 40), child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base), transform: Matrix4.translationValues(0, -16, 0),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadow.card),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bienvenue !', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xxl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Rejoignez la communauté OAYA', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          if (_error.isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFFECACA))),
            child: Row(children: [const Icon(FeatherIcons.alertCircle, size: 16, color: AppColors.error), const SizedBox(width: 8),
              Expanded(child: Text(_error, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.error)))])),
          _label('Nom complet'), _input(_nameCtrl, 'John Doe', FeatherIcons.user),
          const SizedBox(height: 16), _label('Adresse email'), _input(_emailCtrl, 'votre@email.com', FeatherIcons.mail, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16), _label('Mot de passe'), _pwField(_passwordCtrl, '6 caractères minimum'),
          const SizedBox(height: 16), _label('Confirmer le mot de passe'), _pwField(_confirmCtrl, 'Retapez le mot de passe'),
          const SizedBox(height: 24),
          GestureDetector(onTap: _loading ? null : _handleRegister,
            child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: _loading ? 0.6 : 1), borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Center(child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("Créer mon compte", style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))))),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Déjà un compte ? ', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
            GestureDetector(onTap: () => context.push('/login'), child: Text('Se connecter', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: AppColors.accent))),
          ]),
        ])))),
    ]));
  }

  Widget _buildSuccess(BuildContext context) => Scaffold(backgroundColor: AppColors.background, body: SafeArea(child: Center(child: Padding(
    padding: const EdgeInsets.all(AppSpacing.xxl), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
        child: const Center(child: Icon(FeatherIcons.mail, size: 36, color: AppColors.success))),
      const SizedBox(height: 20),
      Text('Vérifiez votre email', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text('Un lien de confirmation a été envoyé à ${_emailCtrl.text}.', style: GoogleFonts.inter(fontSize: AppFontSize.base, color: AppColors.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 32),
      GestureDetector(onTap: () => context.go('/login'),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Text('Aller à la connexion', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: Colors.white)))),
    ])))));

  Widget _label(String text) => Text(text, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  Widget _input(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboard}) => Container(
    margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border, width: 1.5)),
    child: Row(children: [Icon(icon, size: 16, color: AppColors.textMuted), const SizedBox(width: 10),
      Expanded(child: TextField(controller: ctrl, keyboardType: keyboard,
        decoration: InputDecoration.collapsed(hintText: hint, hintStyle: GoogleFonts.inter(color: AppColors.textMuted)),
        style: GoogleFonts.inter(fontSize: AppFontSize.base, color: AppColors.textPrimary)))]));

  Widget _pwField(TextEditingController ctrl, String hint) => Container(
    margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border, width: 1.5)),
    child: Row(children: [const Icon(FeatherIcons.lock, size: 16, color: AppColors.textMuted), const SizedBox(width: 10),
      Expanded(child: TextField(controller: ctrl, obscureText: !_showPw,
        decoration: InputDecoration.collapsed(hintText: hint, hintStyle: GoogleFonts.inter(color: AppColors.textMuted)),
        style: GoogleFonts.inter(fontSize: AppFontSize.base, color: AppColors.textPrimary))),
      GestureDetector(onTap: () => setState(() => _showPw = !_showPw), child: Icon(_showPw ? FeatherIcons.eyeOff : FeatherIcons.eye, size: 16, color: AppColors.textMuted))]));
}
