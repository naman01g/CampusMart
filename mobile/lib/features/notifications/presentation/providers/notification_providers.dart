import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/notifications/data/notification_repository.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

/// Stream of all notifications for the current user, newest first.
final userNotificationsProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref
      .watch(notificationRepositoryProvider)
      .watchUserNotifications(user.uid);
});

/// Stream of unread notification count for the current user.
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(0);
  return ref.watch(notificationRepositoryProvider).watchUnreadCount(user.uid);
});
