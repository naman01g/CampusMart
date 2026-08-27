import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';

/// DEVELOPMENT / TESTING ONLY — Spark-plan image fallback.
///
/// The Firebase project `campusart` runs on the free Spark plan without a
/// provisioned Storage bucket, so real photo uploads fail. This module lets
/// DEBUG builds publish listings with a small set of ordinary, publicly
/// accessible placeholder image URLs so the marketplace flow stays testable.
///
/// HARD GUARANTEES:
/// - Unreachable in release builds (kDebugMode gate inside [offer]).
/// - Production/release always uses the real Firebase Storage upload flow;
///   nothing here is reachable there.
/// - No local device file paths ever reach Firestore — only these remote
///   URLs do, stored in Product.images like any other image URL.
/// - These URLs are NOT disguised as Firebase Storage download URLs.
/// - Nothing is uploaded silently anywhere; the fallback requires an
///   explicit user confirmation dialog after a failed upload attempt.
///
/// Remove this whole file once the project intentionally moves to Blaze and
/// Storage is provisioned.
class TestImageFallback {
  TestImageFallback._();

  /// Stable, public, non-Firebase image URLs (Lorem Picsum seeds resolve
  /// deterministically and never expire).
  static const _pool = [
    'https://picsum.photos/seed/campusmart-test-1/800/800',
    'https://picsum.photos/seed/campusmart-test-2/800/800',
    'https://picsum.photos/seed/campusmart-test-3/800/800',
    'https://picsum.photos/seed/campusmart-test-4/800/800',
    'https://picsum.photos/seed/campusmart-test-5/800/800',
    'https://picsum.photos/seed/campusmart-test-6/800/800',
  ];

  /// Recognises fallback URLs so the UI can flag them as TEST IMAGE MODE.
  static bool isTestImageUrl(String url) =>
      url.startsWith('https://picsum.photos/');

  /// Returns [count] distinct placeholder URLs (capped by the pool size).
  static List<String> imagesForCount(int count) {
    final n = count.clamp(1, _pool.length);
    return _pool.sublist(0, n);
  }

  /// Explains that cloud upload is unavailable and offers placeholder test
  /// images. Returns the URLs if accepted, null if declined or if this is a
  /// release build (where it must never be offered).
  static Future<List<String>?> offer(
    BuildContext context,
    int pickedCount,
  ) async {
    // Release builds never see this fallback.
    if (!kDebugMode) return null;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Photo storage unavailable'),
        content: Text(
          'Uploading photos from your device needs Firebase Storage, which is '
          'not active on this project yet.\n\n'
          'You can publish now with $pickedCount generic PLACEHOLDER test '
          'image(s) instead. They are not your actual photos.\n\n'
          '(Development build option)',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Use test images',
              style: AppTextStyles.body.copyWith(
                color: AppColors.ochre,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (accepted != true) return null;
    return imagesForCount(pickedCount);
  }
}
