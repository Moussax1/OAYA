import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.client.from('profiles').select().order('created_at', ascending: false);
      if (mounted) setState(() { _users = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (!auth.isAdmin) return _accessDenied(context);

    return Scaffold(backgroundColor: AppColors.background, body: SafeArea(child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(onTap: () => context.pop(), child: const Padding(padding: EdgeInsets.all(4), child: Icon(FeatherIcons.arrowLeft, size: 22))),
          Text('Gestion des Utilisateurs', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700)),
          GestureDetector(onTap: () { setState(() => _loading = true); _load(); }, child: const Icon(FeatherIcons.refreshCw, size: 20)),
        ]),
      ),
      Expanded(child: _loading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: AppColors.accent), const SizedBox(height: 12),
              Text('Chargement des utilisateurs...', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted)),
            ]))
          : _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(FeatherIcons.alertTriangle, size: 48, color: AppColors.error), const SizedBox(height: 12),
              Text('Erreur de chargement', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
            ]))
          : _users.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(FeatherIcons.users, size: 48, color: AppColors.textMuted), const SizedBox(height: 12),
              Text('Aucun utilisateur trouvé', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: _users.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _userCard(_users[i]),
            )),
    ])));
  }

  Widget _userCard(Map<String, dynamic> profile) {
    final isAdmin = profile['role'] == 'admin';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadow.card),
      child: Row(children: [
        Container(width: 46, height: 46, decoration: const BoxDecoration(color: AppColors.accentLight, shape: BoxShape.circle),
          child: const Center(child: Icon(FeatherIcons.user, size: 24, color: AppColors.accent))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(profile['full_name'] ?? 'Utilisateur sans nom', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text('ID: ${profile['id'].toString().substring(0, 8)}...', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(AppRadius.full)),
          child: Text((profile['role'] as String?)?.toUpperCase() ?? 'USER',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isAdmin ? const Color(0xFFB45309) : const Color(0xFF4B5563))),
        ),
      ]),
    );
  }

  Widget _accessDenied(BuildContext context) => Scaffold(backgroundColor: AppColors.background,
    body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(FeatherIcons.lock, size: 48, color: AppColors.error), const SizedBox(height: 12),
      Text('Accès Refusé', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text("Vous n'avez pas les droits d'administration.", style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      GestureDetector(onTap: () => context.pop(),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Text('Retour', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: Colors.white)))),
    ])))));
}
