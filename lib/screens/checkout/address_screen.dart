import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../providers/providers.dart';
import '../../services/address_service.dart';
import '../../widgets/progress_stepper.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});
  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  static const _nameFieldKey = Key('address_name_field');
  static const _phoneFieldKey = Key('address_phone_field');
  static const _addressFieldKey = Key('address_address_field');
  static const _postalFieldKey = Key('address_postal_field');
  static const _cityFieldKey = Key('address_city_field');
  static const _continueButtonKey = Key('address_continue_button');

  late final TextEditingController _nameCtrl;
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  String _error = '';
  bool _saveAddress = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _nameCtrl = TextEditingController(text: profile?['full_name'] ?? '');
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    try {
      final addr = await AddressService.getDefaultAddress(userId);
      if (addr != null && mounted) {
        setState(() {
          _nameCtrl.text = addr['full_name'] ?? _nameCtrl.text;
          _phoneCtrl.text = addr['phone'] ?? '';
          _addressCtrl.text = addr['address'] ?? '';
          _cityCtrl.text = addr['city'] ?? '';
          _postalCtrl.text = addr['postal_code'] ?? '';
        });
      }
    } catch (e, st) {
      debugPrint('[AddressScreen] _loadDefaultAddress error: $e\n$st');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    _cityCtrl.dispose(); _postalCtrl.dispose();
    super.dispose();
  }

  void _handleNext() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _addressCtrl.text.isEmpty || _cityCtrl.text.isEmpty || _postalCtrl.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.'); return;
    }
    setState(() => _error = '');

    if (_saveAddress) {
      final userId = ref.read(authProvider).user?.id;
      if (userId != null) {
        try {
          await AddressService.addAddress(
            userId: userId,
            fullName: _nameCtrl.text,
            phone: _phoneCtrl.text,
            address: _addressCtrl.text,
            city: _cityCtrl.text,
            postalCode: _postalCtrl.text,
          );
        } catch (e, st) {
          debugPrint('[AddressScreen] _handleNext save address error: $e\n$st');
        }
      }
    }

    if (mounted) context.push('/checkout/payment');
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressesProvider);

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
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Adresse de livraison', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (addresses.asData?.value.isNotEmpty == true)
            TextButton.icon(
              onPressed: () => _showAddressPicker(context, addresses.asData!.value),
              icon: const Icon(FeatherIcons.mapPin, size: 14),
              label: Text('Choisir', style: GoogleFonts.inter(fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 4),
        Text('Où souhaitez-vous recevoir votre commande ?', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        if (_error.isNotEmpty) Container(
          margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFFECACA))),
          child: Row(children: [const Icon(FeatherIcons.alertCircle, size: 16, color: AppColors.error), const SizedBox(width: 8),
            Text(_error, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.error))])),
        _field('Nom complet', _nameCtrl, 'John Doe', key: _nameFieldKey),
        _field('Numéro de téléphone', _phoneCtrl, '+216 XX XXX XXX', key: _phoneFieldKey, keyboard: TextInputType.phone),
        _field('Adresse', _addressCtrl, '123 Rue de la Liberté', key: _addressFieldKey),
        Row(children: [
          Expanded(child: _field('Code Postal', _postalCtrl, '1000', key: _postalFieldKey, keyboard: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _field('Ville', _cityCtrl, 'Tunis', key: _cityFieldKey)),
        ]),
        CheckboxListTile(
          value: _saveAddress,
          onChanged: (v) => setState(() => _saveAddress = v ?? false),
          title: Text('Sauvegarder cette adresse', style: GoogleFonts.inter(fontSize: AppFontSize.sm)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ]))),
      Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(color: AppColors.surface, border: const Border(top: BorderSide(color: AppColors.border)), boxShadow: AppShadow.sheet),
        child: GestureDetector(key: _continueButtonKey, onTap: _handleNext,
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Center(child: Text('Continuer vers le paiement', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: Colors.white))))),
      ),
    ])));
  }

  void _showAddressPicker(BuildContext context, List<Map<String, dynamic>> addresses) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.all(16), child: Text('Choisir une adresse', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700))),
          ...addresses.map((a) => ListTile(
            leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Center(child: Icon(FeatherIcons.mapPin, size: 19, color: AppColors.primary))),
            title: Text(a['full_name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('${a['address']}, ${a['postal_code']} ${a['city']}', style: GoogleFonts.inter(fontSize: 12)),
            onTap: () {
              setState(() {
                _nameCtrl.text = a['full_name'] ?? '';
                _phoneCtrl.text = a['phone'] ?? '';
                _addressCtrl.text = a['address'] ?? '';
                _cityCtrl.text = a['city'] ?? '';
                _postalCtrl.text = a['postal_code'] ?? '';
              });
              Navigator.pop(ctx);
            },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {Key? key, TextInputType? keyboard}) => Padding(
    key: key,
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
