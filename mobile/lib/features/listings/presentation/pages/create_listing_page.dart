import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/features/listings/data/listings_repository.dart';
import 'package:campusmart_mobile/features/listings/data/storage_service.dart';
import 'package:campusmart_mobile/features/listings/presentation/widgets/listing_form.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({super.key});

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  final _repository = ListingsRepository();
  final _storageService = StorageService();

  bool _submitting = false;
  double? _uploadProgress;

  Future<void> _handleSubmit(ListingFormData data) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      _showError('Please log in to create a listing.');
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0;
    });

    try {
      final imageUrls = List<String>.from(data.existingImageUrls);

      // 1. Upload new photos first so a failure never leaves a partial product.
      if (data.newImages.isNotEmpty) {
        final uploadedUrls = await _storageService.uploadProductImages(
          uid: user.uid,
          files: data.newImages,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
        imageUrls.addAll(uploadedUrls);
      }

      // 2. Create the product document.
      final now = DateTime.now();
      final product = ProductModel(
        id: '',
        sellerId: user.uid,
        title: data.title,
        description: data.description,
        listingType: data.listingType,
        category: data.category,
        price: data.price,
        originalPrice: data.originalPrice,
        isNegotiable: data.isNegotiable,
        condition: data.condition,
        images: imageUrls,
        location: data.location,
        status: ListingStatus.active,
        views: 0,
        favoritesCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      final productId = await _repository.createProduct(product);

      if (!mounted) return;
      // Replace so Android back from the new listing skips the form.
      context.pushReplacement('/listings/$productId');
    } catch (e) {
      _showError('Could not publish your listing. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadProgress = null;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Listing'),
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
      body: ListingForm(
        submitLabel: 'Publish Listing',
        submitting: _submitting,
        uploadProgress: _uploadProgress,
        onSubmit: _handleSubmit,
      ),
    );
  }
}
