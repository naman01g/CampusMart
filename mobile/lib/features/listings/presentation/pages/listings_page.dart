import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/core/utils/date_utils.dart' as app_date_utils;
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/listings/presentation/providers/listings_providers.dart';
import 'package:campusmart_mobile/shared/widgets/custom_text_field.dart';
import 'package:campusmart_mobile/shared/models/models.dart';
import 'package:intl/intl.dart';

class ListingsPage extends ConsumerWidget {
  final String? initialCategory;

  const ListingsPage({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Listings'),
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
      ),
      body: _ListingsContent(initialCategory: initialCategory),
    );
  }
}

class _ListingsContent extends ConsumerStatefulWidget {
  final String? initialCategory;

  const _ListingsContent({this.initialCategory});

  @override
  ConsumerState<_ListingsContent> createState() => _ListingsContentState();
}

class _ListingsContentState extends ConsumerState<_ListingsContent> {
  final _searchController = TextEditingController();
  String _selectedCategory = '';
  ListingType? _selectedType;
  String _sortBy = 'newest';
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    final initial = widget.initialCategory;
    if (initial != null && initial.isNotEmpty && _isValidCategory(initial)) {
      _selectedCategory = initial;
      _showFilters = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(listingsProvider.notifier).setFilters(category: initial);
        }
      });
    } else {
      _showFilters = false;
    }
  }

  bool _isValidCategory(String category) {
    return const [
      'Books',
      'Electronics',
      'Accessories',
      'Furniture',
      'Clothing',
      'Bags',
      'Sports',
      'Study Equipment',
      'Chargers & Cables',
      'Cycles',
      'Gaming',
      'Hostel Items',
      'Other',
    ].contains(category);
  }

  void _onSearchChanged() {
    ref
        .read(listingsProvider.notifier)
        .setFilters(query: _searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsProvider);
    final categories = const [
      'All',
      'Books',
      'Electronics',
      'Accessories',
      'Furniture',
      'Clothing',
      'Bags',
      'Sports',
      'Study Equipment',
      'Chargers & Cables',
      'Cycles',
      'Gaming',
      'Hostel Items',
      'Other',
    ];

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            children: [
              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _searchController,
                      label: '',
                      hintText: 'Search listings...',
                      onChanged: (value) => ref
                          .read(listingsProvider.notifier)
                          .setFilters(query: value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filter Chips - Listing Types
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypeFilterChip(
                      label: 'All Types',
                      selected: _selectedType == null,
                      onSelected: () => setState(() {
                        _selectedType = null;
                        ref
                            .read(listingsProvider.notifier)
                            .setFilters(listingType: null);
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeFilterChip(
                      label: 'Sell',
                      selected: _selectedType == ListingType.sell,
                      onSelected: () => setState(() {
                        _selectedType = ListingType.sell;
                        ref
                            .read(listingsProvider.notifier)
                            .setFilters(listingType: ListingType.sell);
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeFilterChip(
                      label: 'Exchange',
                      selected: _selectedType == ListingType.exchange,
                      onSelected: () => setState(() {
                        _selectedType = ListingType.exchange;
                        ref
                            .read(listingsProvider.notifier)
                            .setFilters(listingType: ListingType.exchange);
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeFilterChip(
                      label: 'Free',
                      selected: _selectedType == ListingType.free,
                      onSelected: () => setState(() {
                        _selectedType = ListingType.free;
                        ref
                            .read(listingsProvider.notifier)
                            .setFilters(listingType: ListingType.free);
                      }),
                    ),
                  ],
                ),
              ),
              if (_showFilters) ...[
                const SizedBox(height: 12),
                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: categories.map((cat) {
                      final isSelected =
                          _selectedCategory == cat ||
                          (cat == 'All' && _selectedCategory.isEmpty);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            cat,
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected
                                  ? AppColors.ochre
                                  : AppColors.secondaryText,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _selectedCategory = cat == 'All' ? '' : cat;
                            ref
                                .read(listingsProvider.notifier)
                                .setFilters(category: cat == 'All' ? '' : cat);
                          }),
                          backgroundColor: isSelected
                              ? AppColors.ochreLight
                              : AppColors.surface,
                          selectedColor: AppColors.ochreLight,
                          checkmarkColor: AppColors.ochre,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.ochre
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          labelStyle: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? AppColors.ochre
                                : AppColors.secondaryText,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Sort Dropdown
                Row(
                  children: [
                    Text(
                      'Sort by:',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'newest',
                          child: Text('Newest'),
                        ),
                        DropdownMenuItem(
                          value: 'oldest',
                          child: Text('Oldest'),
                        ),
                        DropdownMenuItem(
                          value: 'price-low',
                          child: Text('Price: Low to High'),
                        ),
                        DropdownMenuItem(
                          value: 'price-high',
                          child: Text('Price: High to Low'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                          ref
                              .read(listingsProvider.notifier)
                              .setFilters(sortBy: value);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Results
        Expanded(
          child: listingsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.inventory_2,
                                size: 64,
                                color: AppColors.secondaryText,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No listings found',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or search terms',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => ref
                                    .read(listingsProvider.notifier)
                                    .clearFilters(),
                                child: Text(
                                  'Clear Filters',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.ochre,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(listingsProvider),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent * 0.8) {
                      ref.read(listingsProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 190,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length + 1,
                    itemBuilder: (context, index) {
                      if (index == products.length) {
                        return _buildLoadMoreButton();
                      }
                      return _buildProductCard(products[index]);
                    },
                  ),
                ),
              );
            },
            loading: () => LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: _buildLoadingGrid(),
                  ),
                );
              },
            ),
            error: (error, stack) => LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load listings',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => ref.refresh(listingsProvider),
                            child: Text(
                              'Retry',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.ochre,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isReserved = product.status == ListingStatus.reserved;
    final isSold =
        product.status == ListingStatus.sold ||
        product.status == ListingStatus.removed;

    return InkWell(
      onTap: isSold ? null : () => context.push('/listings/${product.id}'),
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
                // Image section - constrained to ~55% of card height
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
                                    if (mounted) {
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
                                  } catch (e) {
                                    if (mounted) {
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
                // Content section - takes remaining ~45% of card height
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

  Widget _buildLoadMoreButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer(
          builder: (context, ref, _) {
            return TextButton(
              onPressed: () => ref.read(listingsProvider.notifier).loadMore(),
              child: Text(
                'Load More',
                style: AppTextStyles.body.copyWith(color: AppColors.ochre),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: selected ? AppColors.ochre : AppColors.secondaryText,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: selected ? AppColors.ochreLight : AppColors.surface,
      selectedColor: AppColors.ochreLight,
      checkmarkColor: AppColors.ochre,
      side: BorderSide(color: selected ? AppColors.ochre : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: AppTextStyles.caption.copyWith(
        color: selected ? AppColors.ochre : AppColors.secondaryText,
      ),
    );
  }
}
