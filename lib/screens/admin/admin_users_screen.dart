import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../services/admin_service.dart';

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

    final adminCount = _users.where((user) => _roleOf(user) == 'admin' || _roleOf(user) == 'owner').length;
    final userCount = _users.length - adminCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.base),
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primarySoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Icon(FeatherIcons.arrowLeft, size: 18, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() => _loading = true);
                          _load();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(FeatherIcons.refreshCw, size: 18, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Gestion des Utilisateurs', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Promouvoir, rétrograder et superviser les comptes depuis une interface cohérente avec l app.', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: Colors.white70, height: 1.4)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statTile(label: 'Comptes', value: '${_users.length}'),
                      const SizedBox(width: 12),
                      _statTile(label: 'Admins', value: '$adminCount'),
                      const SizedBox(width: 12),
                      _statTile(label: 'Users', value: '$userCount'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.accent),
                          const SizedBox(height: 12),
                          Text('Chargement des utilisateurs...', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(FeatherIcons.alertTriangle, size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              Text('Erreur de chargement', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                                child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted)),
                              ),
                            ],
                          ),
                        )
                      : _users.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(FeatherIcons.users, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text('Aucun utilisateur trouvé', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl),
                              itemCount: _users.length,
                              separatorBuilder: (_, i) => const SizedBox(height: 12),
                              itemBuilder: (_, i) => _userCard(_users[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> profile) {
    final role = _roleOf(profile);
    final isAdmin = role == 'admin' || role == 'owner';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadow.card,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accentLight, Color(0xFFF8F1E4)]),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(
              child: Text(
                _initials(profile),
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(profile['full_name'] ?? 'Utilisateur sans nom', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    _roleChip(role, isAdmin),
                  ],
                ),
                const SizedBox(height: 6),
                Text('ID: ${profile['id'].toString().substring(0, 8)}...', style: GoogleFonts.inter(fontSize: AppFontSize.xs, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoPill(label: 'Email', value: profile['email']?.toString() ?? 'non défini'),
                    _infoPill(label: 'Créé', value: _formatDate(profile['created_at']?.toString())),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              if (!isAdmin) const PopupMenuItem(value: 'promote', child: Text('Promote to admin')),
              if (isAdmin) const PopupMenuItem(value: 'demote', child: Text('Demote to user')),
            ],
            onSelected: (v) async {
              final userId = profile['id'] as String;
              try {
                setState(() => _loading = true);
                if (v == 'promote') {
                  await AdminService.promoteUser(userId);
                } else if (v == 'demote') {
                  await AdminService.demoteUser(userId);
                }
                await _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                }
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.more_vert, size: 18, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _roleOf(Map<String, dynamic> profile) => (profile['role'] as String?)?.toLowerCase() ?? 'user';

  String _initials(Map<String, dynamic> profile) {
    final name = (profile['full_name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return 'U';
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : 'U';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'n/a';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return 'n/a';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  Widget _roleChip(String role, bool isAdmin) {
    final display = role.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFFEF3C7) : AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(display, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: isAdmin ? const Color(0xFFB45309) : AppColors.primary)),
    );
  }

  Widget _infoPill({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _statTile({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _accessDenied(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadow.card,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                  child: const Icon(FeatherIcons.lock, size: 34, color: AppColors.error),
                ),
                const SizedBox(height: 16),
                Text('Accès Refusé', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text("Vous n'avez pas les droits d'administration.", style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Text('Retour', style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
