import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/core/utils/date_utils.dart' as app_date_utils;
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/listings/data/listings_repository.dart';
import 'package:campusmart_mobile/features/listings/presentation/providers/listings_providers.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

class MyListingsPage extends ConsumerWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Listings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2,
                size: 64,
                color: AppColors.secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to view your listings',
                style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Log In',
                  style: AppTextStyles.body.copyWith(color: AppColors.ochre),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: _MyListingsBody(userId: user.uid),
    );
  }
}

class _MyListingsBody extends ConsumerStatefulWidget {
  final String userId;

  const _MyListingsBody({required this.userId});

  @override
  ConsumerState<_MyListingsBody> createState() => _MyListingsBodyState();
}

class _MyListingsBodyState extends ConsumerState<_MyListingsBody> {
  final _repository = ListingsRepository();

  static const _filters = <String?, String>{
    null: 'All',
    ListingStatusIndex.active: 'Active',
    ListingStatusIndex.reserved: 'Reserved',
    ListingStatusIndex.sold: 'Sold',
  };

  String? _selectedStatus;

  Future<void> _confirmAndChangeStatus(
    ProductModel product,
    ListingStatus status,
  ) async {
    final label = switch (status) {
      ListingStatus.reserved => 'Mark as Reserved?',
      ListingStatus.sold => 'Mark as Sold?',
      ListingStatus.active => 'Mark as Active?',
      _ => 'Update status?',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text('Update "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: AppColors.ochre)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.updateProductStatus(product.id, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the listing.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmAndDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Delete "${product.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete the listing.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(myListingsProvider(widget.userId));
    final selectedLabel = _filters[_selectedStatus]!;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.entries.map((entry) {
                final isSelected = _selectedStatus == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = entry.key),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.ochreLight,
                    checkmarkColor: AppColors.ochre,
                    side: BorderSide(
                      color: isSelected ? AppColors.ochre : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.ochre
                          : AppColors.secondaryText,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: listingsAsync.when(
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                height: 120,
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
                    'Failed to load your listings',
                    style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(myListingsProvider(widget.userId)),
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
            data: (listings) {
              final filtered = _selectedStatus == null
                  ? listings
                  : listings
                        .where(
                          (l) => l.status.name.toUpperCase() == _selectedStatus,
                        )
                        .toList();

              if (listings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 64,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No listings yet',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sell or give away items you no longer need',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/sell'),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Create Listing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ochre,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.filter_alt_off_outlined,
                        size: 64,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No $selectedLabel listings',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(myListingsProvider(widget.userId)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _MyListingCard(
                    product: filtered[index],
                    onEdit: () =>
                        context.push('/listings/${filtered[index].id}/edit'),
                    onReserve: () => _confirmAndChangeStatus(
                      filtered[index],
                      ListingStatus.reserved,
                    ),
                    onActivate: () => _confirmAndChangeStatus(
                      filtered[index],
                      ListingStatus.active,
                    ),
                    onSold: () => _confirmAndChangeStatus(
                      filtered[index],
                      ListingStatus.sold,
                    ),
                    onDelete: () => _confirmAndDelete(filtered[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ListingStatusIndex {
  static const active = 'ACTIVE';
  static const reserved = 'RESERVED';
  static const sold = 'SOLD';
}

class _MyListingCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onReserve;
  final VoidCallback onActivate;
  final VoidCallback onSold;
  final VoidCallback onDelete;

  const _MyListingCard({
    required this.product,
    required this.onEdit,
    required this.onReserve,
    required this.onActivate,
    required this.onSold,
    required this.onDelete,
  });

  bool get _isActive => product.status == ListingStatus.active;
  bool get _isReserved => product.status == ListingStatus.reserved;
  bool get _isClosed =>
      product.status == ListingStatus.sold ||
      product.status == ListingStatus.removed;

  Color get _statusColor => switch (product.status) {
    ListingStatus.active => AppColors.success,
    ListingStatus.reserved => AppColors.warning,
    _ => AppColors.error,
  };

  String get _statusLabel => product.status.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/listings/${product.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: AppColors.border,
                      child: Icon(
                        Icons.inventory_2,
                        size: 32,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (product.images.isNotEmpty)
                      Image.network(
                        product.images[0],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
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
                          product.title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            border: Border.all(color: _statusColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _statusLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: _statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.listingType == ListingType.free
                        ? 'FREE'
                        : product.listingType == ListingType.exchange
                        ? 'EXCHANGE'
                        : '\u20B9${NumberFormat('#,###').format(product.price.toInt())}${product.isNegotiable ? ' (Negotiable)' : ''}',
                    style: AppTextStyles.label.copyWith(
                      color: product.listingType == ListingType.sell
                          ? AppColors.charcoal
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.views} views \u2022 ${app_date_utils.DateUtils.formatTimeAgo(product.createdAt)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _cardAction(
                        icon: Icons.visibility_outlined,
                        label: 'View',
                        onTap: () => context.push('/listings/${product.id}'),
                      ),
                      if (!_isClosed) ...[
                        _cardAction(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onTap: onEdit,
                        ),
                      ],
                      if (_isActive)
                        _cardAction(
                          icon: Icons.bookmark_border,
                          label: 'Reserve',
                          onTap: onReserve,
                        ),
                      if (_isReserved) ...[
                        _cardAction(
                          icon: Icons.play_arrow_outlined,
                          label: 'Active',
                          onTap: onActivate,
                        ),
                        _cardAction(
                          icon: Icons.check_circle_outline,
                          label: 'Sold',
                          onTap: onSold,
                        ),
                      ],
                      if (_isActive) ...[
                        _cardAction(
                          icon: Icons.check_circle_outline,
                          label: 'Sold',
                          onTap: onSold,
                        ),
                      ],
                      _cardAction(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        destructive: true,
                        onTap: onDelete,
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

  Widget _cardAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? AppColors.error : AppColors.charcoal;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
            color: destructive
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
