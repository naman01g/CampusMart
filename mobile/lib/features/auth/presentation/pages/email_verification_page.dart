import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/shared/widgets/custom_button.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _loading = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendCooldown--);
      }
      return _resendCooldown > 0;
    });
  }

  Future<void> _resendVerification() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider).sendEmailVerification();
      if (mounted) {
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend verification email')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _loading = true);
    try {
      await ref.read(authProvider).reloadUser();
      final verified = await ref.read(authProvider).isEmailVerified();
      if (mounted) {
        if (verified) {
          // Wait for authStateProvider to emit the updated user before navigating
          // to avoid potential redirect loops
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            context.go('/');
          }
        } else {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.ochre,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: AppTextStyles.h2.copyWith(color: AppColors.charcoal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent a verification email to your AKGEC email address. Please check your inbox and click the verification link.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_resendCooldown > 0)
                Text(
                  'Resend available in $_resendCooldown seconds',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'I\'ve Verified My Email',
                loading: _loading,
                onPressed: _checkVerification,
              ),
              const SizedBox(height: 16),
              if (_resendCooldown == 0)
                TextButton(
                  onPressed: _loading ? null : _resendVerification,
                  child: Text(
                    'Resend Verification Email',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.ochre,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider).signOut();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                child: Text(
                  'Back to Login',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
