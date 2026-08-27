import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/shared/widgets/custom_button.dart';
import 'package:campusmart_mobile/shared/widgets/custom_text_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authProvider)
          .registerWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
      if (mounted) context.go('/verify-email');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                Text(
                  'Create your account',
                  style: AppTextStyles.h2.copyWith(color: AppColors.charcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join CampusMart with your AKGEC email',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 40),

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
                  label: 'Full Name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Password is required';
                    if (value.length < 6)
                      return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Confirm password';
                    if (value != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Create Account',
                  loading: _loading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 24),
                Text(
                  'A verification email has been sent to your AKGEC email.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: Text(
                        'Sign in',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.ochre,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
