import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/shared/widgets/custom_button.dart';
import 'package:campusmart_mobile/shared/widgets/custom_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _restoring = false;
  bool _profileMissing = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _profileMissing = false;
      _error = null;
    });

    try {
      await ref
          .read(authProvider)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      // Navigation is driven by authStateProvider via the router redirect.
      // If the profile fetch fails there, this navigation simply bounces
      // back to /login where the retryable error banner appears.
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } on UserProfileMissingException catch (e) {
      setState(() {
        _profileMissing = true;
        _error = '${e.message} You can restore it below.';
      });
    } on AuthProfileUnavailableException catch (e) {
      setState(() => _error = e.message);
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e));
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      default:
        return 'Sign-in failed (${e.code}). Please try again.';
    }
  }

  /// One-tap recovery when the Auth account exists but users/{uid} is gone.
  Future<void> _restoreProfile() async {
    setState(() {
      _restoring = true;
      _error = null;
    });
    try {
      await ref.read(authProvider).restoreMissingProfile();
      final session = await ref.refresh(authStateProvider.future);
      if (session != null && mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } on AuthProfileUnavailableException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(
        () => _error = 'Could not restore your profile. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
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
                  'Welcome back',
                  style: AppTextStyles.h2.copyWith(color: AppColors.charcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your CampusMart account',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 40),

                // Retryable error surfaced when the session could not be
                // established (e.g. Firestore unreachable after sign-in).
                if (authAsync.hasError && !_loading && _error == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Could not load your account. Check your connection.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(authStateProvider),
                          child: Text(
                            'Retry',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.ochre,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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

                if (_profileMissing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CustomButton(
                      text: 'Restore my profile',
                      loading: _restoring,
                      variant: ButtonVariant.outline,
                      fullWidth: true,
                      onPressed: _restoreProfile,
                    ),
                  ),

                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Email is required';
                    if (!value.contains('@')) return 'Enter a valid email';
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
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.ochre,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Sign In',
                  loading: _loading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(
                        'Sign up',
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
