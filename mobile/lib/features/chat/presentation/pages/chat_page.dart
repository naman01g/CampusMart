import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/core/firebase/fcm_service.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:campusmart_mobile/shared/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends ConsumerWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppColors.secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to chat',
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load conversation',
                    style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      if (GoRouter.of(context).canPop()) {
                        context.pop();
                      } else {
                        context.go('/chat');
                      }
                    },
                    child: Text(
                      'Go Back',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.ochre,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!chatSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!chatSnapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Conversation not found',
                    style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      if (GoRouter.of(context).canPop()) {
                        context.pop();
                      } else {
                        context.go('/chat');
                      }
                    },
                    child: Text(
                      'Go Back',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.ochre,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final chat = ChatModel.fromFirestore(chatSnapshot.data!);
        final isBuyer = chat.buyerId == user.uid;
        final otherUid = isBuyer ? chat.sellerId : chat.buyerId;

        return _OtherUserLoader(
          uid: otherUid,
          isBuyer: isBuyer,
          builder: (context, name, profileImage) {
            return _ChatView(
              chatId: chatId,
              currentUserId: user.uid,
              otherUserName: name,
              otherProfileImage: profileImage,
              productTitle: chat.productTitle,
            );
          },
        );
      },
    );
  }
}

class _OtherUserLoader extends ConsumerWidget {
  final String uid;
  final bool isBuyer;
  final Widget Function(BuildContext context, String name, String? profileImage)
  builder;

  const _OtherUserLoader({
    required this.uid,
    required this.isBuyer,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    return profileAsync.when(
      data: (profile) {
        final name = profile?.name.isNotEmpty == true
            ? profile!.name
            : (isBuyer ? 'Seller' : 'Buyer');
        final image = profile?.profileImage;
        return builder(context, name, image);
      },
      loading: () => builder(context, isBuyer ? 'Seller' : 'Buyer', null),
      error: (_, __) => builder(context, isBuyer ? 'Seller' : 'Buyer', null),
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserName;
  final String? otherProfileImage;
  final String? productTitle;

  const _ChatView({
    required this.chatId,
    required this.currentUserId,
    required this.otherUserName,
    this.otherProfileImage,
    this.productTitle,
  });

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  int _lastMessageCount = -1;

  @override
  void initState() {
    super.initState();
    // Mark this conversation as the one being viewed so incoming messages for
    // this exact chat do not produce a redundant system notification.
    setActiveConversation(widget.chatId);
  }

  @override
  void dispose() {
    // Leaving the chat (or the app) - resumes normal notifications.
    if (activeConversationId == widget.chatId) {
      clearActiveConversation();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            chatId: widget.chatId,
            senderId: widget.currentUserId,
            text: text,
          );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.border,
              backgroundImage: widget.otherProfileImage != null
                  ? NetworkImage(widget.otherProfileImage!)
                  : null,
              child: widget.otherProfileImage == null
                  ? Text(
                      widget.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.charcoal,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUserName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.productTitle != null &&
                      widget.productTitle!.isNotEmpty)
                    Text(
                      widget.productTitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/chat');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load messages',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(chatMessagesProvider(widget.chatId)),
                      child: Text(
                        'Retry',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.ochre,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.length != _lastMessageCount) {
                  _lastMessageCount = messages.length;
                  _scrollToBottom();
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start the conversation',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Ask about availability, price or a meetup spot',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUserId;
                    return _buildMessageBubble(
                      message.message,
                      isMe,
                      message.createdAt,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_sending,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      filled: true,
                      fillColor: AppColors.warmCream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  color: AppColors.ochre,
                  onPressed: _sending ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.ochreLight,
                    foregroundColor: AppColors.ochre,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe, DateTime createdAt) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.ochre : AppColors.surface,
              border: Border.all(
                color: isMe ? Colors.transparent : AppColors.border,
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: isMe ? Colors.white : AppColors.charcoal,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Text(
              DateFormat('d MMM, HH:mm').format(createdAt.toLocal()),
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
