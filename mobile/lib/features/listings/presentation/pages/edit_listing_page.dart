import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/listings/data/listings_repository.dart';
import 'package:campusmart_mobile/features/listings/data/storage_service.dart';
import 'package:campusmart_mobile/features/listings/presentation/providers/listings_providers.dart';
import 'package:campusmart_mobile/features/listings/presentation/widgets/listing_form.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

class EditListingPage extends ConsumerStatefulWidget {
  final String productId;

  const EditListingPage({super.key, required this.productId});

  @override
  ConsumerState<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends ConsumerState<EditListingPage> {
  final _repository = ListingsRepository();
  final _storageService = StorageService();

  bool _submitting = false;
  double? _uploadProgress;

  Future<void> _handleSubmit(ProductModel product, ListingFormData data) async {
    setState(() {
      _submitting = true;
      _uploadProgress = 0;
    });

    List<String> uploadedUrls = [];
    try {
      final imageUrls = List<String>.from(data.existingImageUrls);

      if (data.newImages.isNotEmpty) {
        uploadedUrls = await _storageService.uploadProductImages(
          uid: product.sellerId,
          files: data.newImages,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        imageUrls.addAll(uploadedUrls);
      }

      // Photos the seller removed since last save are no longer referenced:
      // delete their storage objects (best-effort).
      final removedUrls = product.images
          .toSet()
          .difference(data.existingImageUrls.toSet())
          .toList();

      await _repository.updateProduct(product.id, {
        'title': data.title,
        'description': data.description,
        'listingType': data.listingType.name.toUpperCase(),
        'category': data.category,
        'price': data.price,
        'originalPrice': data.originalPrice,
        'isNegotiable': data.isNegotiable,
        'condition': data.condition,
        'images': imageUrls,
        'location': data.location,
      });

      await _storageService.deleteImages(removedUrls);

      ref.invalidate(productDetailProvider(product.id));

      if (!mounted) return;
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/listings');
      }
    } catch (e) {
      await _storageService.deleteImages(uploadedUrls);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update your listing. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/listings');
            }
          },
        ),
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load listing',
                style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.invalidate(productDetailProvider(widget.productId)),
                child: Text(
                  'Retry',
                  style: AppTextStyles.body.copyWith(color: AppColors.ochre),
                ),
              ),
            ],
          ),
        ),
        data: (product) {
          if (product == null) {
            return Center(
              child: Text(
                'Listing not found.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            );
          }

          // Ownership guard: only the seller may edit. Rules enforce this too.
          if (user == null || product.sellerId != user.uid) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You can only edit your own listings.',
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

          return ListingForm(
            initialProduct: product,
            submitLabel: 'Save Changes',
            submitting: _submitting,
            uploadProgress: _uploadProgress,
            onSubmit: (data) => _handleSubmit(product, data),
          );
        },
      ),
    );
  }
}
