import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/core/utils/date_utils.dart' as app_date_utils;
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/listings/presentation/providers/listings_providers.dart';
import 'package:campusmart_mobile/shared/models/models.dart';
import 'package:intl/intl.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_outline,
                size: 64,
                color: AppColors.secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to view favorites',
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
      appBar: AppBar(title: const Text('Favorites')),
      body: ref
          .watch(userFavoritesProvider)
          .when(
            loading: () => _buildLoadingGrid(),
            error: (error, _) => _buildErrorState(context, ref, error),
            data: (products) {
              if (products.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(userFavoritesProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(context, products[index]),
                ),
              );
            },
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
              Icons.favorite_outline,
              size: 64,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            Text(
              'Save listings you want to come back to.',
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

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 55,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  color: AppColors.border,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      color: AppColors.border,
                      margin: const EdgeInsets.only(bottom: 6),
                    ),
                    Container(
                      height: 12,
                      width: 60,
                      color: AppColors.border,
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 16,
                          width: 60,
                          color: AppColors.border,
                        ),
                        Container(
                          height: 12,
                          width: 80,
                          color: AppColors.border,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load favorites',
              style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Couldn\'t load favorites. Please try again.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(userFavoritesProvider),
              child: Text(
                'Retry',
                style: AppTextStyles.body.copyWith(color: AppColors.ochre),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final isReserved = product.status == ListingStatus.reserved;
    final isSold =
        product.status == ListingStatus.sold ||
        product.status == ListingStatus.removed;

    return InkWell(
      onTap: isSold
          ? null
          : () => GoRouter.of(context).push('/listings/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 55,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: product.images.isNotEmpty
                            ? Image.network(
                                product.images[0],
                                width: double.infinity,
                                height: double.infinity,
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
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildTypeBadge(product.listingType),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Consumer(
                          builder: (context, ref, _) {
                            final favoriteAsync = ref.watch(
                              favoriteStatusProvider(product.id),
                            );
                            return favoriteAsync.when(
                              data: (isFavorite) => IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite
                                      ? AppColors.error
                                      : AppColors.secondaryText,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final authState = ref.read(authStateProvider);
                                  final user = authState.value;
                                  if (user == null) {
                                    if (context.mounted) {
                                      context.push(
                                        '/login',
                                        extra: {
                                          'from': '/listings/${product.id}',
                                        },
                                      );
                                    }
                                    return;
                                  }
                                  try {
                                    await ref
                                        .read(listingsRepositoryProvider)
                                        .toggleFavorite(
                                          user.uid,
                                          product.id,
                                          !isFavorite,
                                        );
                                    ref.invalidate(
                                      favoriteStatusProvider(product.id),
                                    );
                                    ref.invalidate(userFavoritesProvider);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to update favorite',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 45,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Flexible(
                          child: Text(
                            product.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                product.listingType == ListingType.free
                                    ? 'FREE'
                                    : '₹${NumberFormat('#,###').format(product.price.toInt())}',
                                style: AppTextStyles.h4.copyWith(
                                  color: product.listingType == ListingType.free
                                      ? AppColors.ochre
                                      : AppColors.charcoal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${product.location} • ${app_date_utils.DateUtils.formatTimeAgo(product.createdAt)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isReserved)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'RESERVED',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (isSold)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SOLD',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ListingType type) {
    Color bgColor;
    Color textColor;
    String label;

    switch (type) {
      case ListingType.sell:
        bgColor = AppColors.surface;
        textColor = AppColors.charcoal;
        label = 'Sell';
        break;
      case ListingType.exchange:
        bgColor = AppColors.ochreLight;
        textColor = AppColors.ochre;
        label = 'Exchange';
        break;
      case ListingType.free:
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
        label = 'Free';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
