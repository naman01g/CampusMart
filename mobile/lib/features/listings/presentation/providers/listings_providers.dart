import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campusmart_mobile/features/listings/data/listings_repository.dart';
import 'package:campusmart_mobile/shared/models/models.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => ListingsRepository(),
);

final listingsProvider =
    StateNotifierProvider<ListingsNotifier, AsyncValue<List<ProductModel>>>((
      ref,
    ) {
      return ListingsNotifier(ref);
    });

class ListingsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final Ref _ref;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  String _sortBy = 'newest';
  String _category = '';
  ListingType? _listingType;
  double? _minPrice;
  double? _maxPrice;
  String _query = '';

  ListingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchProducts(reset: true);
  }

  void setFilters({
    String? query,
    String? category,
    ListingType? listingType,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) {
    if (query != null) _query = query;
    _category = category ?? '';
    _listingType = listingType;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _sortBy = sortBy ?? 'newest';
    fetchProducts(reset: true);
  }

  void clearFilters() {
    _query = '';
    _category = '';
    _listingType = null;
    _minPrice = null;
    _maxPrice = null;
    _sortBy = 'newest';
    fetchProducts(reset: true);
  }

  Future<void> fetchProducts({bool reset = false}) async {
    if (reset) {
      _lastDoc = null;
      _hasMore = true;
      state = const AsyncValue.loading();
    } else {
      if (!_hasMore) return;
      state = AsyncValue.data([
        ...state.value ?? [],
        ...[],
      ]); // Keep current data while loading more
    }

    try {
      final repository = _ref.read(listingsRepositoryProvider);
      final products = await repository.fetchProducts(
        query: _query.isEmpty ? null : _query,
        category: _category.isEmpty ? null : _category,
        listingType: _listingType,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        lastDoc: _lastDoc,
      );

      if (reset) {
        state = AsyncValue.data(products);
      } else {
        state = AsyncValue.data([...state.value ?? [], ...products]);
      }

      if (products.length < 20) {
        _hasMore = false;
      } else if (products.isNotEmpty) {
        // Update lastDoc for pagination
        final lastProduct = products.last;
        _lastDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(lastProduct.id)
            .get();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    await fetchProducts();
  }
}

final featuredListingsProvider = StreamProvider<List<ProductModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .where('status', isEqualTo: 'ACTIVE')
      .orderBy('createdAt', descending: true)
      .limit(6)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList(),
      );
});

final productDetailProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  productId,
) async {
  final db = FirebaseFirestore.instance;
  final doc = await db.collection('products').doc(productId).get();
  if (!doc.exists) return null;

  // Record the view as a per-user document (Spark-compatible). Fire-and-forget:
  // a view-record failure must never prevent the detail page from loading.
  final user = ref.read(authStateProvider).value;
  if (user != null) {
    unawaited(
      ref
          .read(listingsRepositoryProvider)
          .recordProductView(user.uid, productId),
    );
  }

  return ProductModel.fromFirestore(doc);
});

final productSellerProvider = FutureProvider.family<UserModel?, String>((
  ref,
  sellerId,
) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(sellerId)
      .get();
  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});

final favoriteStatusProvider = FutureProvider.family<bool, String>((
  ref,
  productId,
) async {
  final authState = ref.read(authStateProvider);
  final user = authState.value;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('favorites')
      .doc('${user.uid}_$productId')
      .get();
  return doc.exists;
});

final userFavoritesProvider = StreamProvider<List<ProductModel>>((ref) {
  final authState = ref.read(authStateProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('favorites')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
        if (snapshot.docs.isEmpty) return [];

        final products = <ProductModel>[];
        for (final doc in snapshot.docs) {
          final productId = doc.data()['productId'] as String;
          try {
            final productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(productId)
                .get();
            if (productDoc.exists && productDoc.data()?['status'] == 'ACTIVE') {
              products.add(ProductModel.fromFirestore(productDoc));
            }
          } on FirebaseException catch (e) {
            // Skip products we can't read (e.g., non-ACTIVE where user isn't seller)
            if (e.code == 'permission-denied') continue;
            rethrow;
          }
        }
        return products;
      });
});

/// Real-time feed of every listing owned by [userId] (all statuses).
final myListingsProvider = StreamProvider.family<List<ProductModel>, String>((
  ref,
  userId,
) {
  return ref.watch(listingsRepositoryProvider).watchMyListings(userId);
});
