import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _emailFieldKey = Key('login_email_field');
  static const _passwordFieldKey = Key('login_password_field');
  static const _submitButtonKey = Key('login_submit_button');

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPw = false, _loading = false;
  String _error = '';

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) { setState(() => _error = 'Veuillez remplir tous les champs.'); return; }
    try {
      setState(() { _loading = true; _error = ''; });
      await ref.read(authProvider.notifier).signIn(_emailCtrl.text, _passwordCtrl.text);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('Invalid') ? 'Email ou mot de passe incorrect.' : e.toString());
    } finally { if (mounted) setState(() => _loading = false); }
  }


  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Column(children: [
      Container(width: double.infinity, padding: EdgeInsets.fromLTRB(AppSpacing.base, MediaQuery.of(context).padding.top + 10, AppSpacing.base, 28),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primarySoft])),
        child: Stack(children: [
          Positioned(left: 0, top: 0, child: GestureDetector(onTap: () => context.pop(), child: const Padding(padding: EdgeInsets.all(6), child: Icon(FeatherIcons.arrowLeft, size: 22, color: Colors.white70)))),
          Center(child: Column(children: [
            Text('OAYA', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 8)),
            const SizedBox(height: 4),
            Text('Votre monde du style', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.accent, letterSpacing: 1)),
          ])),
        ])),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 40), child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base), transform: Matrix4.translationValues(0, -16, 0),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadow.card),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bon retour !', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xxl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Connectez-vous à votre compte OAYA', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          if (_error.isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFFECACA))),
            child: Row(children: [const Icon(FeatherIcons.alertCircle, size: 16, color: AppColors.error), const SizedBox(width: 8),
              Expanded(child: Text(_error, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.error)))])),
          Text('Adresse email', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8), _inputField(_emailCtrl, 'votre@email.com', FeatherIcons.mail, fieldKey: _emailFieldKey, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          Text('Mot de passe', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8), _passwordField(),
          Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: GestureDetector(
              onTap: () => context.push('/forgot-password'),
              child: Text('Mot de passe oublié ?', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.accent)),
            ))),
          GestureDetector(key: _submitButtonKey, onTap: _loading ? null : _handleLogin,
            child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: _loading ? 0.6 : 1), borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Center(child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Se connecter', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))))),
          const SizedBox(height: 20),
          Row(children: [const Expanded(child: Divider(color: AppColors.border)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('ou', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted))), const Expanded(child: Divider(color: AppColors.border))]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Pas encore de compte ? ', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
            GestureDetector(onTap: () => context.push('/register'),
              child: Text("S'inscrire", style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: AppColors.accent))),
          ]),
        ])))),
    ]));
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {Key? fieldKey, TextInputType? keyboard}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border, width: 1.5)),
    child: Row(children: [Icon(icon, size: 16, color: AppColors.textMuted), const SizedBox(width: 10),
      Expanded(child: TextField(key: fieldKey, controller: ctrl, keyboardType: keyboard, textCapitalization: TextCapitalization.none,
        decoration: InputDecoration.collapsed(hintText: hint, hintStyle: GoogleFonts.inter(color: AppColors.textMuted)),
        style: GoogleFonts.inter(fontSize: AppFontSize.base, color: AppColors.textPrimary)))]));

  Widget _passwordField() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border, width: 1.5)),
    child: Row(children: [const Icon(FeatherIcons.lock, size: 16, color: AppColors.textMuted), const SizedBox(width: 10),
      Expanded(child: TextField(key: _passwordFieldKey, controller: _passwordCtrl, obscureText: !_showPw,
        decoration: InputDecoration.collapsed(hintText: '••••••••', hintStyle: GoogleFonts.inter(color: AppColors.textMuted)),
        style: GoogleFonts.inter(fontSize: AppFontSize.base, color: AppColors.textPrimary))),
      GestureDetector(onTap: () => setState(() => _showPw = !_showPw),
        child: Icon(_showPw ? FeatherIcons.eyeOff : FeatherIcons.eye, size: 16, color: AppColors.textMuted))]));
}
