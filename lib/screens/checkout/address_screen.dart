import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/progress_stepper.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});
  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  late final TextEditingController _nameCtrl;
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  String _error = '';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _nameCtrl = TextEditingController(text: profile?['full_name'] ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose(); _cityCtrl.dispose(); _postalCtrl.dispose(); super.dispose(); }

  void _handleNext() {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _addressCtrl.text.isEmpty || _cityCtrl.text.isEmpty || _postalCtrl.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.'); return;
    }
    setState(() => _error = '');
    context.push('/checkout/payment');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, body: SafeArea(child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(onTap: () => context.pop(), child: const Padding(padding: EdgeInsets.all(4), child: Icon(FeatherIcons.arrowLeft, size: 22, color: AppColors.textPrimary))),
          Text('Livraison', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(width: 30),
        ]),
      ),
      const ProgressStepper(currentStep: 1),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.xl), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Adresse de livraison', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Où souhaitez-vous recevoir votre commande ?', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        if (_error.isNotEmpty) Container(
          margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFFECACA))),
          child: Row(children: [const Icon(FeatherIcons.alertCircle, size: 16, color: AppColors.error), const SizedBox(width: 8),
            Text(_error, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.error))])),
        _field('Nom complet', _nameCtrl, 'John Doe'),
        _field('Numéro de téléphone', _phoneCtrl, '+216 XX XXX XXX', keyboard: TextInputType.phone),
        _field('Adresse', _addressCtrl, '123 Rue de la Liberté'),
        Row(children: [
          Expanded(child: _field('Code Postal', _postalCtrl, '1000', keyboard: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _field('Ville', _cityCtrl, 'Tunis')),
        ]),
      ]))),
      Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(color: AppColors.surface, border: const Border(top: BorderSide(color: AppColors.border)), boxShadow: AppShadow.sheet),
        child: GestureDetector(onTap: _handleNext,
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Center(child: Text('Continuer vers le paiement', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: Colors.white))))),
      ),
    ])));
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, keyboardType: keyboard,
        decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.border, width: 1.5))),
        style: GoogleFonts.inter(fontSize: AppFontSize.base, color: AppColors.textPrimary)),
    ]),
  );
}
