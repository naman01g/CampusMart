import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/updates/data/update_repository.dart';

/// Prompts the user to update the app to a newer available version.
Future<void> showUpdateDialog(
  BuildContext context,
  AppUpdateInfo update,
) async {
  final download = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update_alt, color: AppColors.ochre),
          const SizedBox(width: 8),
          Text(
            'CampusMart Update Available',
            style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${update.latestVersion} is ready to download.',
            style: AppTextStyles.body.copyWith(color: AppColors.charcoal),
          ),
          if (update.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              update.releaseNotes,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'After downloading, if Android asks, allow your browser to '
            'install apps from this source to complete the update.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Not Now',
            style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ochre,
            foregroundColor: Colors.white,
          ),
          child: Text('Update Now', style: AppTextStyles.button),
        ),
      ],
    ),
  );

  if (download == true) {
    final uri = Uri.parse(update.apkUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the download link.')),
      );
    }
  }
}
