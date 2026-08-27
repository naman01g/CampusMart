import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/chat/data/chat_repository.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);

/// Every conversation involving the signed-in user, newest first.
final chatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchUserChats(user.uid);
});

/// Real-time message feed for one conversation.
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  chatId,
) {
  return ref.watch(chatRepositoryProvider).watchMessages(chatId);
});

/// Fetches a user profile by UID. Returns null if not found.
final userProfileProvider = FutureProvider.family<UserModel?, String>((
  ref,
  uid,
) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});
