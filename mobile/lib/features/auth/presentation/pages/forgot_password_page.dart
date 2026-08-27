import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/shared/widgets/custom_button.dart';
import 'package:campusmart_mobile/shared/widgets/custom_text_field.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: AppColors.warmCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoal),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                if (!_success) ...[
                  Text(
                    'Reset password',
                    style: AppTextStyles.h2.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your AKGEC email and we\'ll send you a reset link',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 40),
                ] else ...[
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Check your email',
                    style: AppTextStyles.h2.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ve sent a password reset link to your AKGEC email.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (!_success) ...[
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),

                  CustomTextField(
                    label: 'AKGEC Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Email is required';
                      if (!value.contains('@') || !value.contains('.'))
                        return 'Enter a valid college email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Send Reset Link',
                    loading: _loading,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final email = _emailController.text.trim();
                        setState(() {
                          _loading = true;
                        });
                        try {
                          await ref.read(authProvider).resetPassword(email);
                          if (mounted) setState(() => _success = true);
                        } on AuthException catch (e) {
                          setState(() => _error = e.message);
                        } catch (e) {
                          setState(
                            () => _error =
                                'Failed to send reset email. Please try again.',
                          );
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(
                      'Back to Login',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.ochre,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Back to Login',
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
