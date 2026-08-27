import 'package:flutter/material.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.ochre,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'CM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'CampusMart',
              style: AppTextStyles.h1.copyWith(color: AppColors.charcoal),
            ),
            const SizedBox(height: 12),
            Text(
              'Your campus marketplace',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.ochre),
            ),
          ],
        ),
      ),
    );
  }
}
