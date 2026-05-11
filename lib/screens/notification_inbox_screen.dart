import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../providers/providers.dart';
import '../services/notification_service.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mes notifications',
          style: GoogleFonts.playfairDisplay(
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.settings, color: AppColors.textMuted),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Paramètres de notification',
          ),
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(FeatherIcons.checkSquare, color: AppColors.textMuted),
              onPressed: () async {
                await NotificationService.markAllAsRead(auth.user!.id);
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationCountProvider);
              },
              tooltip: 'Tout marquer comme lu',
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FeatherIcons.bell, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: GoogleFonts.inter(
                      fontSize: AppFontSize.base,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous recevrez des notifications ici lors des mises à jour de vos commandes.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isUnread = notif['read'] == false;
                final createdAt = notif['created_at'] as String?;
                final timeStr = createdAt != null
                    ? _formatTime(DateTime.parse(createdAt))
                    : '';

                return GestureDetector(
                  onTap: () async {
                    if (isUnread) {
                      await NotificationService.markAsRead(notif['id']);
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadNotificationCountProvider);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUnread ? const Color(0xFFFEFCE8) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isUnread ? AppColors.accentLight : AppColors.border,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isUnread ? AppColors.accent.withValues(alpha: 0.15) : AppColors.accentLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: Icon(
                            isUnread ? FeatherIcons.bell : FeatherIcons.check,
                            size: 19,
                            color: isUnread ? AppColors.accent : AppColors.textMuted,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: AppFontSize.sm,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notif['body'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FeatherIcons.alertCircle, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Erreur de chargement',
                style: GoogleFonts.inter(
                  fontSize: AppFontSize.base,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  ref.invalidate(notificationsProvider);
                  ref.invalidate(unreadNotificationCountProvider);
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return DateFormat('dd/MM/yy').format(dt);
  }
}
