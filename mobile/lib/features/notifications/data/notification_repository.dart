import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Real-time notifications for a user, newest first.
  /// Deduplicates by notification document ID to prevent duplicates
  /// from stream emissions or retries.
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final Map<String, NotificationModel> deduped = {};
          for (final doc in snapshot.docs) {
            final notification = NotificationModel.fromFirestore(doc);
            deduped[notification.id] = notification;
          }
          return deduped.values.toList();
        });
  }

  /// Real-time unread notification count for a user.
  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
