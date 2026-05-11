import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../services/address_service.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  const AddressFormScreen({super.key, this.existing});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  bool _isDefault = false;
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e['full_name'] ?? '';
      _phoneCtrl.text = e['phone'] ?? '';
      _addressCtrl.text = e['address'] ?? '';
      _cityCtrl.text = e['city'] ?? '';
      _postalCtrl.text = e['postal_code'] ?? '';
      _isDefault = e['is_default'] == true;
    } else {
      final profile = ref.read(authProvider).profile;
      _nameCtrl.text = profile?['full_name'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    _cityCtrl.dispose(); _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _addressCtrl.text.isEmpty || _cityCtrl.text.isEmpty || _postalCtrl.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final auth = ref.read(authProvider);
      if (auth.user == null) return;
      await AddressService.addAddress(
        userId: auth.user!.id,
        fullName: _nameCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
        city: _cityCtrl.text,
        postalCode: _postalCtrl.text,
        isDefault: _isDefault,
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(FeatherIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Nouvelle adresse', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error.isNotEmpty) Container(
            margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: const Color(0xFFFECACA))),
            child: Row(children: [const Icon(FeatherIcons.alertCircle, size: 16, color: AppColors.error), const SizedBox(width: 8),
              Expanded(child: Text(_error, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w500, color: AppColors.error)))])),
          _field('Nom complet', _nameCtrl, 'John Doe'),
          _field('Numéro de téléphone', _phoneCtrl, '+216 XX XXX XXX', keyboard: TextInputType.phone),
          _field('Adresse', _addressCtrl, '123 Rue de la Liberté'),
          Row(children: [
            Expanded(child: _field('Code Postal', _postalCtrl, '1000', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _field('Ville', _cityCtrl, 'Tunis')),
          ]),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v ?? false),
            title: Text('Définir comme adresse par défaut', style: GoogleFonts.inter(fontSize: AppFontSize.sm)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Enregistrer', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
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
