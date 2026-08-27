import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/listings/presentation/providers/listings_providers.dart';
import 'package:campusmart_mobile/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campusmart_mobile/shared/widgets/custom_button.dart';
import 'package:campusmart_mobile/shared/models/models.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: const _HomePageContent());
  }
}

class _HomePageContent extends ConsumerWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredListingsAsync = ref.watch(featuredListingsProvider);
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.hasValue && authState.value != null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Image.asset(
            'assets/full logo.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final unreadCountAsync = ref.watch(
                  unreadNotificationCountProvider,
                );
                return unreadCountAsync.when(
                  data: (count) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () => context.push('/notifications'),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.ochre,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                  ),
                  error: (_, __) => IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                  ),
                );
              },
            ),
          ],
          floating: true,
          snap: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fresh on Campus',
                  style: AppTextStyles.h2.copyWith(color: AppColors.charcoal),
                ),
                const SizedBox(height: 16),
                featuredListingsAsync.when(
                  data: (products) => products.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          children: products
                              .take(1)
                              .map(
                                (product) =>
                                    _buildFeaturedCard(context, product),
                              )
                              .toList(),
                        ),
                  loading: () => _buildFeaturedSkeleton(),
                  error: (_, __) => _buildFeaturedSkeleton(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular Categories',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.charcoal,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/listings'),
                      child: Text(
                        'View all →',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.ochre,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCategoryGrid(),
                const SizedBox(height: 32),
                _buildHowItWorks(),
                if (!isAuthenticated) ...[
                  const SizedBox(height: 32),
                  _buildCTASection(context),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(BuildContext context, ProductModel product) {
    return InkWell(
      onTap: () => context.push('/listings/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
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
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.charcoal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.location,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.condition} • ${product.category}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.listingType == ListingType.free
                            ? 'FREE'
                            : '₹${NumberFormat('#,###').format(product.price.toInt())}',
                        style: AppTextStyles.h4.copyWith(
                          color: product.listingType == ListingType.free
                              ? AppColors.ochre
                              : AppColors.charcoal,
                        ),
                      ),
                      CustomButton(
                        text: 'Contact Seller',
                        onPressed: () =>
                            context.push('/listings/${product.id}'),
                        variant: ButtonVariant.primary,
                        size: ButtonSize.small,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: AppColors.border,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 24, width: 100, color: AppColors.border),
                    Container(height: 24, width: 80, color: AppColors.border),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Books', 'icon': Icons.menu_book},
      {'name': 'Electronics', 'icon': Icons.devices},
      {'name': 'Furniture', 'icon': Icons.chair},
      {'name': 'Clothing', 'icon': Icons.checkroom},
      {'name': 'Sports', 'icon': Icons.sports_soccer},
      {'name': 'Hostel Items', 'icon': Icons.king_bed},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return InkWell(
          onTap: () => context.push(
            '/listings?category=${Uri.encodeComponent(cat['name'] as String)}',
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat['icon'] as IconData, size: 32, color: AppColors.ochre),
                const SizedBox(height: 8),
                Text(
                  cat['name'] as String,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.charcoal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How CampusMart works',
          style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final steps = [
              (
                step: '01',
                icon: Icons.search,
                title: 'Discover',
                desc: 'Browse items listed by students around your campus.',
              ),
              (
                step: '02',
                icon: Icons.chat,
                title: 'Connect',
                desc: 'Message sellers directly and ask about the item.',
              ),
              (
                step: '03',
                icon: Icons.swap_horiz,
                title: 'Meet & Exchange',
                desc:
                    'Meet on campus, inspect the item, and complete the exchange.',
              ),
            ];

            // Desktop / tablet: all three cards side-by-side, equal width.
            if (constraints.maxWidth >= 600) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: steps
                      .map(
                        (s) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _HowItWorksCard(
                              step: s.step,
                              icon: s.icon,
                              title: s.title,
                              desc: s.desc,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            }

            // Mobile: compact cards in a smooth horizontally scrollable row.
            // First card fully visible, a portion of the next card visible to
            // signal that the row can be swiped.
            return SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 8),
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final s = steps[index];
                  return SizedBox(
                    width: constraints.maxWidth * 0.55,
                    child: _HowItWorksCard(
                      step: s.step,
                      icon: s.icon,
                      title: s.title,
                      desc: s.desc,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Ready to start?',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Join thousands of students buying and selling on campus. Verify your college email to get started.',
            style: AppTextStyles.body.copyWith(color: AppColors.border),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Get Started',
            onPressed: () => context.push('/register'),
            variant: ButtonVariant.primary,
            size: ButtonSize.large,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String desc;

  const _HowItWorksCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                step,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.ochre,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(icon, size: 20, color: AppColors.ochre),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.charcoal,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
