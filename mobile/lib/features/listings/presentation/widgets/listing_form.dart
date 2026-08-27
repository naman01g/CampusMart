import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/listings/data/storage_service.dart';
import 'package:campusmart_mobile/features/listings/data/test_image_fallback.dart';
import 'package:campusmart_mobile/shared/models/models.dart';
import 'package:campusmart_mobile/shared/widgets/custom_button.dart';
import 'package:campusmart_mobile/shared/widgets/custom_text_field.dart';

/// Everything the submit handler needs to persist a listing.
class ListingFormData {
  final String title;
  final String description;
  final ListingType listingType;
  final String category;
  final String condition;
  final double price;
  final double? originalPrice;
  final bool isNegotiable;
  final String location;

  /// Download URLs that already live in Storage (edit mode keeps/removes these).
  final List<String> existingImageUrls;

  /// Local image files picked in this session that must be uploaded on submit.
  final List<File> newImages;

  ListingFormData({
    required this.title,
    required this.description,
    required this.listingType,
    required this.category,
    required this.condition,
    required this.price,
    required this.originalPrice,
    required this.isNegotiable,
    required this.location,
    required this.existingImageUrls,
    required this.newImages,
  });
}

/// One slot in the image strip: either a remote URL (already stored) or a
/// freshly picked local file.
class _ImageEntry {
  final XFile? file;
  final String? url;
  _ImageEntry.file(XFile this.file) : url = null;
  _ImageEntry.url(String this.url) : file = null;
  bool get isLocal => file != null;

  /// True when the URL is a Spark-plan placeholder test image.
  bool get isTestImage => !isLocal && TestImageFallback.isTestImageUrl(url!);
}

class ListingForm extends StatefulWidget {
  /// Pre-fills the form in edit mode; null in create mode.
  final ProductModel? initialProduct;
  final bool submitting;
  final double? uploadProgress;
  final String submitLabel;
  final Future<void> Function(ListingFormData data) onSubmit;

  const ListingForm({
    super.key,
    this.initialProduct,
    this.submitting = false,
    this.uploadProgress,
    this.submitLabel = 'Submit',
    required this.onSubmit,
  });

  @override
  State<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<ListingForm> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _locationController;

  late ListingType _listingType;
  String? _category;
  String? _condition;
  bool _isNegotiable = false;
  List<_ImageEntry> _images = [];
  String? _imageError;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p != null && p.price > 0 ? _formatPrice(p.price) : '',
    );
    final initialOriginalPrice = p?.originalPrice;
    _originalPriceController = TextEditingController(
      text: initialOriginalPrice != null
          ? _formatPrice(initialOriginalPrice)
          : '',
    );
    _locationController = TextEditingController(text: p?.location ?? '');
    _listingType = p?.listingType ?? ListingType.sell;
    _category = p?.category;
    _condition = p?.condition;
    _isNegotiable = p?.isNegotiable ?? false;
    _images = (p?.images ?? const []).map((u) => _ImageEntry.url(u)).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  static String _formatPrice(double value) {
    return value.truncateToDouble() == value
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  double? _parsePrice(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim().replaceAll(',', ''));
  }

  bool get _isSell => _listingType == ListingType.sell;

  Future<void> _addImages() async {
    if (widget.submitting) return;
    try {
      final picked = await _storageService.pickImages(
        currentCount: _images.length,
        context: context,
      );
      if (picked.isEmpty) return;
      setState(() {
        _images.addAll(picked.map((f) => _ImageEntry.file(f)));
        _imageError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick images. Please try again.')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // Field-level validation first so messages appear inline.
    if (!_formKey.currentState!.validate()) return;

    // Image validation is manual because the picker lives outside the Form.
    if (_images.isEmpty) {
      setState(() => _imageError = 'Add at least one product photo.');
      return;
    }

    final price = _parsePrice(_priceController.text) ?? 0;
    final originalPrice = _parsePrice(_originalPriceController.text);

    final data = ListingFormData(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      listingType: _listingType,
      category: _category!,
      condition: _condition!,
      // Price only carries meaning for SELL; the model still needs a number.
      price: _isSell ? price : 0,
      originalPrice: _isSell ? originalPrice : null,
      isNegotiable: _isSell && _isNegotiable,
      location: _locationController.text.trim(),
      existingImageUrls: _images
          .where((e) => !e.isLocal)
          .map((e) => e.url!)
          .toList(),
      newImages: _images
          .where((e) => e.isLocal)
          .map((e) => File(e.file!.path))
          .toList(),
    );

    await widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final submitting = widget.submitting;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Photos'),
            const SizedBox(height: 8),
            _buildImageStrip(enabled: !submitting),
            if (_images.any((e) => e.isTestImage)) ...[
              const SizedBox(height: 8),
              _buildTestImageModeBanner(),
            ] else if (kDebugMode) ...[
              const SizedBox(height: 6),
              Text(
                'Device photo upload needs cloud storage; a placeholder '
                'test-image option will be offered if it is unavailable.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            if (_imageError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _imageError!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),
            const SizedBox(height: 20),

            CustomTextField(
              controller: _titleController,
              label: 'Title',
              hintText: 'What are you selling?',
              enabled: !submitting,
              maxLength: 80,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Title is required.';
                if (value.length < 3)
                  return 'Title must be at least 3 characters.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              hintText: 'Describe the item, its usage and any flaws...',
              enabled: !submitting,
              maxLines: 5,
              maxLength: 1000,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Description is required.';
                if (value.length < 10)
                  return 'Description must be at least 10 characters.';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _sectionLabel('Listing Type'),
            const SizedBox(height: 8),
            _buildListingTypeSelector(enabled: !submitting),
            const SizedBox(height: 20),

            _buildDropdownField(
              label: 'Category',
              hint: 'Select a category',
              value: _category,
              items: categories,
              enabled: !submitting,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please select a category.' : null,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Condition',
              hint: 'Select condition',
              value: _condition,
              items: conditions,
              enabled: !submitting,
              validator: (v) => v == null || v.isEmpty
                  ? 'Please select the condition.'
                  : null,
              onChanged: (v) => setState(() => _condition = v),
            ),
            const SizedBox(height: 20),

            if (_isSell) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'Price (₹)',
                      hintText: '0',
                      enabled: !submitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (!_isSell) return null;
                        final parsed = _parsePrice(v ?? '');
                        if (parsed == null) return 'Price is required.';
                        if (parsed <= 0) return 'Price must be greater than 0.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _originalPriceController,
                      label: 'Original Price (₹)',
                      hintText: 'Optional',
                      enabled: !submitting,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (!_isSell || (v ?? '').trim().isEmpty) return null;
                        final original = _parsePrice(v!);
                        final current = _parsePrice(_priceController.text);
                        if (original == null) return 'Enter a valid number.';
                        if (original <= 0) return 'Must be greater than 0.';
                        if (current != null && original < current) {
                          return 'Cannot be lower than the price.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isNegotiable,
                onChanged: submitting
                    ? null
                    : (v) => setState(() => _isNegotiable = v ?? false),
                title: Text(
                  'Price is negotiable',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.ochre,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warmCream,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _listingType == ListingType.free
                      ? 'This item will be listed for FREE.'
                      : 'This item will be listed for EXCHANGE.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            CustomTextField(
              controller: _locationController,
              label: 'Meetup Location',
              hintText: 'e.g. Main Gate, Library, Block C',
              enabled: !submitting,
              maxLength: 60,
              validator: (v) {
                if ((v?.trim() ?? '').isEmpty)
                  return 'Meetup location is required.';
                return null;
              },
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: widget.submitLabel,
              onPressed: _submit,
              loading: submitting,
              fullWidth: true,
              size: ButtonSize.large,
            ),
            if (submitting && widget.uploadProgress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.uploadProgress!.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  color: AppColors.ochre,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.uploadProgress! >= 1.0
                    ? 'Publishing your listing...'
                    : 'Uploading photos... ${(widget.uploadProgress! * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
    );
  }

  /// Visible only while placeholder test images are actually in use.
  Widget _buildTestImageModeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        border: Border.all(color: AppColors.warning),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Test image mode - publishing with placeholder photos (development build).',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required bool enabled,
    required String? Function(String?) validator,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: AppTextStyles.body),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: validator,
          style: AppTextStyles.body.copyWith(color: AppColors.primaryText),
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.secondaryText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.secondaryText,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.ochre, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListingTypeSelector({required bool enabled}) {
    return Row(
      children: [
        _typeOption(ListingType.sell, 'SELL', enabled),
        const SizedBox(width: 8),
        _typeOption(ListingType.exchange, 'EXCHANGE', enabled),
        const SizedBox(width: 8),
        _typeOption(ListingType.free, 'FREE', enabled),
      ],
    );
  }

  Widget _typeOption(ListingType type, String label, bool enabled) {
    final selected = _listingType == type;
    return Expanded(
      child: InkWell(
        onTap: enabled ? () => setState(() => _listingType = type) : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.ochreLight : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.ochre : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.ochre : AppColors.secondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageStrip({required bool enabled}) {
    final itemCount =
        _images.length + (_images.length < StorageService.maxImages ? 1 : 0);

    if (enabled) {
      return SizedBox(
        height: 108,
        child: ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              final entry = _images.removeAt(oldIndex);
              _images.insert(newIndex, entry);
            });
          },
          proxyDecorator: (child, index, animation) => ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.05).animate(animation),
            child: child,
          ),
          itemBuilder: (context, index) {
            if (index == _images.length) {
              return _buildAddTile(
                key: const ValueKey('add_tile'),
                enabled: true,
              );
            }
            final entry = _images[index];
            return _buildThumbnail(
              key: ValueKey(
                entry.isLocal
                    ? 'local_${entry.file!.path}'
                    : 'url_${entry.url}',
              ),
              entry: entry,
              index: index,
              enabled: true,
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == _images.length) {
            return _buildAddTile(
              key: const ValueKey('add_tile'),
              enabled: false,
            );
          }
          final entry = _images[index];
          return _buildThumbnail(
            key: ValueKey(
              entry.isLocal ? 'local_${entry.file!.path}' : 'url_${entry.url}',
            ),
            entry: entry,
            index: index,
            enabled: false,
          );
        },
      ),
    );
  }

  Widget _buildAddTile({required Key key, required bool enabled}) {
    return GestureDetector(
      key: key,
      onTap: enabled ? _addImages : null,
      child: Container(
        width: 92,
        height: 92,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppColors.warmCream,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.secondaryText,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '${_images.length}/${StorageService.maxImages}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail({
    required Key key,
    required _ImageEntry entry,
    required int index,
    required bool enabled,
  }) {
    return Stack(
      key: key,
      children: [
        Container(
          width: 92,
          height: 92,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(4),
            color: AppColors.border,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: entry.isLocal
                ? Image.file(File(entry.file!.path), fit: BoxFit.cover)
                : Image.network(
                    entry.url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
        if (enabled)
          Positioned(
            top: -6,
            right: -2,
            child: Material(
              color: AppColors.charcoal,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _removeImage(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
