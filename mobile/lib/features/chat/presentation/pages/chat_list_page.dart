import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
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
                'Please log in to view messages',
                style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to start chatting with sellers',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
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
      appBar: AppBar(title: const Text('Messages')),
      body: ref
          .watch(chatsProvider)
          .when(
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => Container(
                height: 76,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
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
                    'Failed to load conversations',
                    style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      error.toString(),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => ref.invalidate(chatsProvider),
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
            data: (chats) {
              if (chats.isEmpty) {
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
                        'No conversations yet',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start chatting with sellers from any listing',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/listings'),
                        icon: const Icon(Icons.storefront_outlined, size: 18),
                        label: const Text('Browse Listings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.charcoal,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(chatsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _ChatTile(chat: chat, currentUserId: user.uid);
                  },
                ),
              );
            },
          ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String currentUserId;

  const _ChatTile({required this.chat, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBuyer = chat.buyerId == currentUserId;
    final otherUid = isBuyer ? chat.sellerId : chat.buyerId;
    final otherProfileAsync = ref.watch(userProfileProvider(otherUid));
    final otherLabel = otherProfileAsync.when(
      data: (profile) => profile?.name.isNotEmpty == true
          ? profile!.name
          : (isBuyer ? 'Seller' : 'Buyer'),
      loading: () => isBuyer ? 'Seller' : 'Buyer',
      error: (_, __) => isBuyer ? 'Seller' : 'Buyer',
    );
    final otherProfileImage = otherProfileAsync.value?.profileImage;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/chat/${chat.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.border,
              backgroundImage: otherProfileImage != null
                  ? NetworkImage(otherProfileImage)
                  : null,
              child: otherProfileImage == null
                  ? Text(
                      otherLabel[0].toUpperCase(),
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.charcoal,
                      ),
                    )
                  : null,
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
                          otherLabel,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(chat.lastMessageAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  if (chat.productTitle != null &&
                      chat.productTitle!.isNotEmpty)
                    Text(
                      'About: ${chat.productTitle}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ochre,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    chat.lastMessage.isEmpty
                        ? 'Say hello...'
                        : chat.lastMessage,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: chat.lastMessage.isEmpty
                          ? AppColors.secondaryText
                          : AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${diff.inDays ~/ 7}w';
  }
}
