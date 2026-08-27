import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  static const int maxImages = 5;

  static const String _cloudName = 'xaexfxrr';
  static const String _uploadPreset = 'campusmart';

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Lets the user pick up to [max] images from the device gallery.
  Future<List<XFile>> pickImagesFromGallery({
    int currentCount = 0,
    int max = maxImages,
  }) async {
    final remaining = max - currentCount;

    if (remaining <= 0) return [];

    final picked = await _picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 80,
      limit: remaining,
    );

    return picked.take(remaining).toList();
  }

  /// Lets the user take a single photo with the camera.
  Future<XFile?> pickImageFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 80,
    );
    return picked;
  }

  /// Shows a dialog to let the user choose between Camera and Gallery,
  /// then picks images accordingly.
  Future<List<XFile>> pickImages({
    int currentCount = 0,
    int max = maxImages,
    required BuildContext context,
  }) async {
    final remaining = max - currentCount;

    if (remaining <= 0) {
      return [];
    }

    // Show source selection dialog
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => _ImageSourceSelector(remaining: remaining),
    );

    if (source == null) {
      return [];
    }

    if (source == ImageSource.camera) {
      final picked = await pickImageFromCamera();
      return picked != null ? [picked] : [];
    } else {
      return pickImagesFromGallery(currentCount: currentCount, max: max);
    }
  }

  /// Uploads product images directly to Cloudinary.
  ///
  /// Returns Cloudinary secure URLs in the same order as [files].
  Future<List<String>> uploadProductImages({
    required String uid,
    required List<File> files,
    void Function(double progress)? onProgress,
  }) async {
    final urls = <String>[];

    try {
      for (var i = 0; i < files.length; i++) {
        final file = files[i];

        final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

        request.fields['upload_preset'] = _uploadPreset;

        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(
            'Cloudinary upload failed '
            '(${response.statusCode}): ${response.body}',
          );
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final secureUrl = data['secure_url'] as String?;

        if (secureUrl == null || secureUrl.isEmpty) {
          throw Exception(
            'Cloudinary upload succeeded but no secure_url was returned.',
          );
        }

        urls.add(secureUrl);

        onProgress?.call(((i + 1) / files.length).clamp(0.0, 1.0));
      }

      return urls;
    } catch (e) {
      rethrow;
    }
  }

  /// Cloudinary deletion requires server-side authentication.
  /// Do not put the Cloudinary API secret inside the Flutter app.
  Future<void> deleteImages(List<String> urls) async {
    // Intentionally empty.
  }
}

class _ImageSourceSelector extends StatelessWidget {
  final int remaining;

  const _ImageSourceSelector({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Add Photos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              subtitle: Text('Take a photo (1 remaining)'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              subtitle: Text('Choose up to $remaining photos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
