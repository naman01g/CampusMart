import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

class ListingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProductModel>> fetchProducts({
    String? query,
    String? category,
    ListingType? listingType,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'newest',
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection('products')
        .where('status', isEqualTo: 'ACTIVE');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (listingType != null) {
      query = query.where(
        'listingType',
        isEqualTo: listingType.name.toUpperCase(),
      );
    }

    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }

    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }

    switch (sortBy) {
      case 'newest':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'oldest':
        query = query.orderBy('createdAt', descending: false);
        break;
      case 'price-low':
        query = query.orderBy('price', descending: false);
        break;
      case 'price-high':
        query = query.orderBy('price', descending: true);
        break;
      default:
        query = query.orderBy('createdAt', descending: true);
    }

    query = query.limit(20);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  /// Creates a product document and returns its generated id.
  ///
  /// sellerId must already be set to the authenticated uid by the caller.
  /// createdAt/updatedAt are written as server timestamps via [ProductModel.toMap].
  Future<String> createProduct(ProductModel product) async {
    final doc = _firestore.collection('products').doc();
    await doc.set(product.toMap());
    return doc.id;
  }

  /// Updates ONLY the caller-supplied fields plus updatedAt.
  ///
  /// Protected fields (sellerId, views, favoritesCount, createdAt) are never
  /// accepted here; Firestore rules reject them even if a caller tried.
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    final forbidden = {'sellerId', 'views', 'favoritesCount', 'createdAt'};
    final clean = Map<String, dynamic>.from(data);
    for (final field in forbidden) {
      clean.remove(field);
    }
    await _firestore.collection('products').doc(productId).update({
      ...clean,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProductStatus(
    String productId,
    ListingStatus status,
  ) async {
    await updateProduct(productId, {'status': status.name.toUpperCase()});
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  /// Real-time feed of every listing owned by [userId], newest first,
  /// regardless of status (ACTIVE / RESERVED / SOLD / REMOVED).
  Stream<List<ProductModel>> watchMyListings(String userId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Records a product view (Spark-compatible, no Cloud Functions).
  ///
  /// Two writes, batched:
  /// 1. A deterministic per-user-per-product ledger document at
  ///    `views/{userId}_{productId}` (id derived from the caller's uid, so
  ///    repeated opens reuse it).
  /// 2. An atomic counter bump on `products/{productId}.views` using
  ///    FieldValue.increment(1). Firestore rules permit this update ONLY
  ///    when no other field changes and the value advances by exactly 1.
  ///
  /// Best-effort only: failures are swallowed so listing details never break.
  Future<void> recordProductView(String userId, String productId) async {
    try {
      final batch = _firestore.batch();
      batch.set(_firestore.collection('views').doc('${userId}_$productId'), {
        'userId': userId,
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_firestore.collection('products').doc(productId), {
        'views': FieldValue.increment(1),
      });
      await batch.commit();
    } catch (_) {
      // View counting must never block or fail the UI.
    }
  }

  /// Toggles the caller's favorite mark on a product.
  ///
  /// The `favorites` collection is the single source of truth; product
  /// counter fields (`favoritesCount`) are never written from the client.
  ///
  /// [isFavorite] is the DESIRED final state: `true` ensures the document at
  /// `favorites/{userId}_{productId}` exists (create), `false` deletes it.
  /// Both paths are idempotent.
  Future<void> toggleFavorite(
    String userId,
    String productId,
    bool isFavorite,
  ) async {
    final favoriteRef = _firestore
        .collection('favorites')
        .doc('${userId}_$productId');

    if (isFavorite) {
      await favoriteRef.set({
        'userId': userId,
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Deleting a non-existent document is a no-op success in Firestore,
      // so unfavorite-when-not-favorited is safe.
      await favoriteRef.delete();
    }
  }

  Future<bool> isFavorite(String userId, String productId) async {
    final doc = await _firestore
        .collection('favorites')
        .doc('${userId}_$productId')
        .get();
    return doc.exists;
  }

  Stream<List<ProductModel>> watchFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final productIds = snapshot.docs
              .map((doc) => doc.data()['productId'] as String)
              .toList();
          if (productIds.isEmpty) return [];

          final products = <ProductModel>[];
          for (final productId in productIds) {
            try {
              final doc = await _firestore
                  .collection('products')
                  .doc(productId)
                  .get();
              if (doc.exists && doc.data()?['status'] == 'ACTIVE') {
                products.add(ProductModel.fromFirestore(doc));
              }
            } on FirebaseException catch (e) {
              // Skip products we can't read (e.g., non-ACTIVE where user isn't seller)
              if (e.code == 'permission-denied') continue;
              rethrow;
            }
          }
          return products;
        });
  }
}
