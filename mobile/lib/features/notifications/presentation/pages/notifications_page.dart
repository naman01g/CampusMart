import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/core/utils/date_utils.dart' as app_date_utils;
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 64,
                color: AppColors.secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to view notifications',
                style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Log In',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ochre,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unreadCountAsync = ref.watch(
                unreadNotificationCountProvider,
              );
              return unreadCountAsync.when(
                data: (count) {
                  if (count == 0) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () => _markAllAsRead(ref, user.uid),
                    child: Text(
                      'Mark all read',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.ochre,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: ref
          .watch(userNotificationsProvider)
          .when(
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => _buildNotificationSkeleton(),
            ),
            error: (error, _) => _buildErrorState(context, ref, error),
            data: (notifications) {
              if (notifications.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    onTap: () =>
                        _handleNotificationTap(context, ref, notification),
                  );
                },
              );
            },
          ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final isDebug = const bool.fromEnvironment('dart.vm.product') == false;
    final errorMessage = isDebug
        ? error.toString()
        : 'Couldn\'t load notifications. Please try again.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load notifications',
                style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  errorMessage,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => ref.invalidate(userNotificationsProvider),
                child: Text(
                  'Retry',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ochre,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              "You're all caught up",
              style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            Text(
              'New messages and updates will appear here',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  color: AppColors.border,
                  margin: const EdgeInsets.only(bottom: 6),
                ),
                Container(
                  height: 12,
                  width: 180,
                  color: AppColors.border,
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(height: 12, width: 100, color: AppColors.border),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(WidgetRef ref, String userId) async {
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead(userId);
      ref.invalidate(userNotificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      // Silently fail; user can retry.
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    // Mark as read if unread.
    if (!notification.isRead) {
      try {
        await ref
            .read(notificationRepositoryProvider)
            .markAsRead(notification.id);
        ref.invalidate(userNotificationsProvider);
        ref.invalidate(unreadNotificationCountProvider);
      } catch (_) {
        // Continue navigation even if mark-as-read fails.
      }
    }

    // Navigate to chat.
    if (notification.chatId.isNotEmpty) {
      context.push('/chat/${notification.chatId}');
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    // Use recipientRole (Buyer/Seller) for privacy-safe display.
    // Fallback to 'Buyer' if missing (older notifications).
    final roleLabel = notification.recipientRole.isNotEmpty
        ? notification.recipientRole
        : 'Buyer';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.warmCream : AppColors.surface,
          border: Border.all(
            color: isUnread
                ? AppColors.ochre.withValues(alpha: 0.3)
                : AppColors.border,
            width: isUnread ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isUnread
                  ? AppColors.ochreLight
                  : AppColors.border,
              child: Icon(
                Icons.chat_bubble_outline,
                color: isUnread ? AppColors.ochre : AppColors.secondaryText,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          roleLabel,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        app_date_utils.DateUtils.formatTimeAgo(
                          notification.createdAt,
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.messagePreview,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isUnread
                                ? AppColors.primaryText
                                : AppColors.secondaryText,
                            fontWeight: isUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          notification.productTitle,
                          style: AppTextStyles.caption.copyWith(
                            color: isUnread
                                ? AppColors.ochre
                                : AppColors.secondaryText,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.ochre,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
