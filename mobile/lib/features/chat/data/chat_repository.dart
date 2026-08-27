import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campusmart_mobile/shared/models/models.dart';
import 'package:campusmart_mobile/core/services/notification_service.dart';

/// Data layer for conversations and messages.
///
/// Chat documents live at `chats/{chatId}` with a DETERMINISTIC id of
/// `{buyerId}_{sellerId}_{productId}`, so buyer + seller + product always map
/// to exactly one conversation and repeated "Contact Seller" taps can never
/// create duplicates.
class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  String chatIdFor({
    required String buyerId,
    required String sellerId,
    required String productId,
  }) {
    return '${buyerId}_${sellerId}_$productId';
  }

  /// Returns the id of the conversation between [buyerId] and [sellerId]
  /// about [productId], creating it if it does not exist yet.
  ///
  /// Uses a deterministic document ID so repeated calls are idempotent.
  /// If the document already exists, the create fails with PERMISSION_DENIED
  /// (update rule only allows lastMessage/lastMessageAt changes), which we
  /// catch and ignore.
  Future<String> getOrCreateChat({
    required ProductModel product,
    required String buyerId,
    required String sellerId,
  }) async {
    final chatId = chatIdFor(
      buyerId: buyerId,
      sellerId: sellerId,
      productId: product.id,
    );
    final ref = _firestore.collection('chats').doc(chatId);

    try {
      await ref.set({
        'buyerId': buyerId,
        'sellerId': sellerId,
        'productId': product.id,
        'productTitle': product.title,
        'productImage': product.images.isNotEmpty ? product.images.first : null,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // Document already exists (race or idempotent retry): the update rule
      // only permits lastMessage/lastMessageAt changes, so a full create
      // fails with PERMISSION_DENIED. Safe to ignore.
      if (e.code != 'permission-denied') rethrow;
    }
    return chatId;
  }

  /// All conversations involving [userId], newest activity first.
  ///
  /// Implemented as two indexed queries (buyer side + seller side) merged
  /// locally, so sellers see incoming conversations just like buyers see
  /// their own outgoing ones. Deduplicates by chatId to prevent duplicate
  /// entries when both queries emit overlapping results.
  Stream<List<ChatModel>> watchUserChats(String userId) {
    final controller = StreamController<List<ChatModel>>();
    var buyerChats = <ChatModel>[];
    var sellerChats = <ChatModel>[];

    void emit() {
      if (!controller.isClosed) {
        final Map<String, ChatModel> deduped = {};
        for (final chat in [...buyerChats, ...sellerChats]) {
          deduped[chat.id] = chat;
        }
        final all = deduped.values.toList()
          ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        controller.add(all);
      }
    }

    final sub1 = _firestore
        .collection('chats')
        .where('buyerId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .listen((s) {
          buyerChats = s.docs.map((d) => ChatModel.fromFirestore(d)).toList();
          emit();
        }, onError: controller.addError);

    final sub2 = _firestore
        .collection('chats')
        .where('sellerId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .listen((s) {
          sellerChats = s.docs.map((d) => ChatModel.fromFirestore(d)).toList();
          emit();
        }, onError: controller.addError);

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };
    return controller.stream;
  }

  /// Real-time messages of a chat, oldest first.
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => MessageModel.fromFirestore(d)).toList(),
        );
  }

  /// Sends [text] as [senderId]. The message write, the chat preview bump,
  /// and a notification for the recipient are batched atomically.
  /// Rules guarantee senderId is the caller and only participants may
  /// touch either document. Notification is created with a deterministic
  /// ID based on message ID to prevent duplicates on retries.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    // Fetch chat data to determine recipient and product info for notification.
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      throw Exception('Chat not found');
    }
    final chatData = chatDoc.data()!;
    final buyerId = chatData['buyerId'] as String;
    final sellerId = chatData['sellerId'] as String;
    final productId = chatData['productId'] as String;
    final productTitle = chatData['productTitle'] as String? ?? '';

    final recipientId = senderId == buyerId ? sellerId : buyerId;
    // Recipient's role in this chat: 'Buyer' or 'Seller'.
    final recipientRole = recipientId == buyerId ? 'Buyer' : 'Seller';

    // Fetch sender's name for notification
    String senderName = 'User';
    try {
      final senderDoc = await _firestore
          .collection('users')
          .doc(senderId)
          .get();
      if (senderDoc.exists) {
        final senderData = senderDoc.data()!;
        senderName = (senderData['name'] as String?)?.trim() ?? 'User';
        if (senderName.isEmpty) senderName = 'User';
      }
    } catch (_) {
      // Fallback to 'User' if fetch fails
    }

    final messageRef = _firestore.collection('messages').doc();
    final notificationId = '${messageRef.id}_$chatId';

    final batch = _firestore.batch();

    // 1. Create the message.
    batch.set(messageRef, {
      'chatId': chatId,
      'senderId': senderId,
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 2. Update chat preview.
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // 3. Create notification for recipient (deterministic ID prevents duplicates on retry).
    batch.set(_firestore.collection('notifications').doc(notificationId), {
      'recipientId': recipientId,
      'senderId': senderId,
      'type': 'chat_message',
      'chatId': chatId,
      'productId': productId,
      'productTitle': productTitle,
      'senderName': senderName,
      'recipientRole': recipientRole,
      'messagePreview': text.length > 80 ? '${text.substring(0, 80)}…' : text,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();

    // 4. Send push notification via Cloudflare Worker (non-blocking).
    // Failures here must NOT affect the already-committed message.
    _sendPushNotification(
      recipientId: recipientId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      productTitle: productTitle,
      recipientRole: recipientRole,
    );
  }

  /// Fire-and-forget push notification. Errors are logged but not propagated.
  void _sendPushNotification({
    required String recipientId,
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    required String productTitle,
    required String recipientRole,
  }) {
    // Run asynchronously without awaiting - don't block the caller.
    // Using a microtask to ensure it runs after the current function returns.
    Future.microtask(() async {
      try {
        await _notificationService.sendChatNotification(
          recipientId: recipientId,
          chatId: chatId,
          senderId: senderId,
          senderName: senderName,
          messagePreview: text.length > 80 ? '${text.substring(0, 80)}…' : text,
          productTitle: productTitle,
          recipientRole: recipientRole,
        );
      } catch (e) {
        // Non-blocking: log but don't throw
        print('Push notification error (non-blocking): $e');
      }
    });
  }
}
