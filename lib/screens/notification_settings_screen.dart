import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _promotionsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushEnabled = prefs.getBool('notif_push') ?? true;
      _emailEnabled = prefs.getBool('notif_email') ?? true;
      _promotionsEnabled = prefs.getBool('notif_promotions') ?? false;
    });
  }

  Future<void> _save({required String key, required bool value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(FeatherIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Notifications', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
      ),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.base), children: [
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadow.card),
          child: Column(children: [
            _switchTile('Notifications push', 'Alertes sur votre appareil', FeatherIcons.bell, _pushEnabled, (v) {
              setState(() => _pushEnabled = v);
              _save(key: 'notif_push', value: v);
            }),
            const Divider(height: 1, color: AppColors.border),
            _switchTile('Notifications email', 'Reçus et confirmations', FeatherIcons.mail, _emailEnabled, (v) {
              setState(() => _emailEnabled = v);
              _save(key: 'notif_email', value: v);
            }),
            const Divider(height: 1, color: AppColors.border),
            _switchTile('Promotions', 'Offres et nouveautés', FeatherIcons.tag, _promotionsEnabled, (v) {
              setState(() => _promotionsEnabled = v);
              _save(key: 'notif_promotions', value: v);
            }),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(color: const Color(0xFFFEFCE8), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.accentLight)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(FeatherIcons.info, size: 16, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(child: Text('Vous pouvez modifier vos préférences à tout moment. Les notifications push nécessitent une connexion internet.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5))),
          ]),
        ),
      ]),
    );
  }

  Widget _switchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Center(child: Icon(icon, size: 19, color: AppColors.primary))),
      title: Text(title, style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.accent),
    );
  }
}
