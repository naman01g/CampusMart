import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/core/utils/date_utils.dart' as app_date_utils;
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/chat/data/chat_repository.dart';
import 'package:campusmart_mobile/features/listings/presentation/providers/listings_providers.dart';
import 'package:campusmart_mobile/shared/models/models.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ListingDetailPage extends ConsumerWidget {
  final String productId;

  const ListingDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return _buildNotFound(context);
          }
          return _ListingDetailContent(product: product);
        },
        loading: () => _buildLoadingSkeleton(),
        error: (error, stack) => _buildError(context, error),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Listing not found',
                style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              Text(
                'This listing may have been removed.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (GoRouter.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/listings');
                  }
                },
                child: Text(
                  'Browse Listings',
                  style: AppTextStyles.body.copyWith(color: AppColors.ochre),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: AppColors.border,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 24,
              width: 120,
              color: AppColors.border,
              margin: const EdgeInsets.only(bottom: 8),
            ),
            Container(
              height: 16,
              width: 80,
              color: AppColors.border,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            Container(
              height: 16,
              width: 100,
              color: AppColors.border,
              margin: const EdgeInsets.only(bottom: 8),
            ),
            Container(height: 12, width: 60, color: AppColors.border),
            const SizedBox(height: 24),
            Container(
              height: 16,
              width: 100,
              color: AppColors.border,
              margin: const EdgeInsets.only(bottom: 8),
            ),
            Container(height: 12, width: 100, color: AppColors.border),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Container(height: 48, color: AppColors.border)),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 48, color: AppColors.border)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load listing',
                style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (GoRouter.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/listings');
                  }
                },
                child: Text(
                  'Retry',
                  style: AppTextStyles.body.copyWith(color: AppColors.ochre),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingDetailContent extends ConsumerWidget {
  final ProductModel product;

  const _ListingDetailContent({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(productSellerProvider(product.sellerId));
    final favoriteAsync = ref.watch(favoriteStatusProvider(product.id));
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final isSold =
        product.status == ListingStatus.sold ||
        product.status == ListingStatus.removed;

    return _ListingDetailView(
      product: product,
      sellerAsync: sellerAsync,
      favoriteAsync: favoriteAsync,
      user: user,
      isSold: isSold,
    );
  }
}

class _ListingDetailView extends ConsumerStatefulWidget {
  final ProductModel product;
  final AsyncValue<UserModel?> sellerAsync;
  final AsyncValue<bool> favoriteAsync;
  final UserModel? user;
  final bool isSold;

  const _ListingDetailView({
    required this.product,
    required this.sellerAsync,
    required this.favoriteAsync,
    required this.user,
    required this.isSold,
  });

  @override
  ConsumerState<_ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends ConsumerState<_ListingDetailView> {
  final _chatRepository = ChatRepository();
  int _currentImageIndex = 0;
  late final PageController _pageController;
  bool _favorited = false;
  bool _contactingSeller = false;

  @override
  void initState() {
    super.initState();
    _favorited = widget.favoriteAsync.value ?? false;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ListingDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.favoriteAsync.value != oldWidget.favoriteAsync.value) {
      _favorited = widget.favoriteAsync.value ?? false;
    }
  }

  Future<void> _toggleFavorite() async {
    final user = widget.user;
    if (user == null) return;

    setState(() => _favorited = !_favorited);
    try {
      await ref
          .read(listingsRepositoryProvider)
          .toggleFavorite(user.uid, widget.product.id, _favorited);
    } catch (e) {
      setState(() => _favorited = !_favorited);
    }
  }

  /// Opens a chat with the seller. When [sendGreeting] is true the exact
  /// message "Hi, is this still available?" is sent so it appears in the
  /// conversation (used by the "Hi, is this still available?" action).
  Future<void> _openChat({required bool sendGreeting}) async {
    final user = widget.user;
    if (user == null) {
      if (mounted) {
        context.push(
          '/login',
          extra: {'from': '/listings/${widget.product.id}'},
        );
      }
      return;
    }
    if (widget.product.sellerId == user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This is your own listing')),
        );
      }
      return;
    }

    setState(() => _contactingSeller = true);
    try {
      final chatId = await _chatRepository.getOrCreateChat(
        product: widget.product,
        buyerId: user.uid,
        sellerId: widget.product.sellerId,
      );

      if (sendGreeting) {
        // Send the exact "still available" message so the conversation starts
        // with the intended message and it appears in the chat.
        await _chatRepository.sendMessage(
          chatId: chatId,
          senderId: user.uid,
          text: 'Hi, is this still available?',
        );
      }

      if (!mounted) return;
      await context.push('/chat/$chatId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start the conversation. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _contactingSeller = false);
    }
  }

  Future<void> _handleShare() async {
    final url = 'https://campusmart.app/listings/${widget.product.id}';
    await Share.share(
      'Check out this listing on CampusMart: ${widget.product.title}\n$url',
      subject: widget.product.title,
    );
  }

  Widget _buildSellerInfo(UserModel? seller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller Information',
            style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.border,
                backgroundImage: seller?.profileImage != null
                    ? NetworkImage(seller!.profileImage!)
                    : null,
                child: _buildAvatarChild(seller),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          seller?.name ?? 'Unknown',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.charcoal,
                          ),
                        ),
                        if (seller?.isVerified == true) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: AppColors.success,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${seller?.course} • ${seller?.branch} • Year ${seller?.year}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.charcoal,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildAvatarChild(UserModel? seller) {
    final profileImage = seller?.profileImage;
    if (profileImage == null) {
      final name = seller?.name;
      if (name?.isNotEmpty == true) {
        return Text(
          name![0].toUpperCase(),
          style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
        );
      }
      return Text(
        '?',
        style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
      );
    }
    return null;
  }

  Widget _buildSellerSection() {
    return widget.sellerAsync.when(
      data: (seller) => _buildSellerInfo(seller),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isSold = widget.isSold;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Gallery
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
              onPressed: () {
                if (GoRouter.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/listings');
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.charcoal),
                onPressed: _handleShare,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  product.images.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: product.images.length,
                          onPageChanged: (index) {
                            if (mounted) {
                              setState(() => _currentImageIndex = index);
                            }
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              product.images[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : Container(
                                      color: AppColors.border,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.border,
                                child: const Icon(
                                  Icons.inventory_2,
                                  size: 48,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.border,
                          child: const Center(
                            child: Icon(
                              Icons.inventory_2,
                              size: 48,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: product.images.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${product.images.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.charcoal,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Thumbnail strip at bottom
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: product.images.length,
                          itemBuilder: (context, index) {
                            final isSelected = index == _currentImageIndex;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.ochre
                                        : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.border,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.network(
                                    product.images[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.inventory_2,
                                      size: 24,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price Block
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Posted ${app_date_utils.DateUtils.formatTimeAgo(product.createdAt)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _favorited ? Icons.favorite : Icons.favorite_border,
                          color: AppColors.charcoal,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.listingType == ListingType.free
                        ? 'FREE'
                        : '₹${NumberFormat('#,###').format(product.price.toInt())}',
                    style: AppTextStyles.h2.copyWith(
                      color: product.listingType == ListingType.free
                          ? AppColors.ochre
                          : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Chips / Quick Specs
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(product.category),
                      _buildChip(product.condition),
                      if (product.isNegotiable &&
                          product.listingType == ListingType.sell)
                        Chip(
                          label: Text(
                            'Negotiable',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ochre,
                            ),
                          ),
                          backgroundColor: AppColors.ochreLight,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  // Description Block
                  Text(
                    'Description',
                    style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Meetup Location
                  Container(
                    padding: const EdgeInsets.all(16),
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
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.charcoal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meetup Location',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.charcoal,
                                ),
                              ),
                              Text(
                                product.location,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Seller Block
                  _buildSellerSection(),
                  const SizedBox(height: 16),
                  // Quick Actions Block (Desktop only)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600)
                        return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _contactingSeller
                                ? null
                                : () => _openChat(sendGreeting: true),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _contactingSeller
                                      ? 'Starting chat...'
                                      : 'Hi, is this still available?',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // Bottom padding for sticky bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Sticky Bottom Action Bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          8 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        _favorited ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                      ),
                      label: Text(
                        _favorited ? 'Saved' : 'Save',
                        style: AppTextStyles.button,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isSold || _contactingSeller
                          ? null
                          : () => _openChat(sendGreeting: true),
                      icon: _contactingSeller
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.chat, size: 18),
                      label: Text(
                        isSold
                            ? 'Sold'
                            : (_contactingSeller
                                  ? 'Starting chat...'
                                  : 'Hi, is this still available?'),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        backgroundColor: isSold
                            ? AppColors.secondaryText
                            : AppColors.ochre,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.charcoal),
      ),
      backgroundColor: AppColors.warmCream,
      side: BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
