import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';
import 'package:campusmart_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:campusmart_mobile/shared/models/models.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return _buildLoggedOutState(context);
          }
          return _buildProfileContent(context, ref, user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(authStateProvider),
                child: Text(
                  'Retry',
                  style: AppTextStyles.body.copyWith(color: AppColors.ochre),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedOutState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 64,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view your profile',
              style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to access your account and listings',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Log In',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.ochre,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => context.go('/register'),
                  child: Text(
                    'Sign Up',
                    style: AppTextStyles.body.copyWith(
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
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.border,
                  backgroundImage: user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: user.profileImage == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: AppTextStyles.h2.copyWith(color: AppColors.charcoal),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        user.email,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.isVerified
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    border: Border.all(
                      color: user.isVerified
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user.isVerified
                            ? Icons.verified
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: user.isVerified
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isVerified
                            ? 'Email Verified'
                            : 'Email Not Verified',
                        style: AppTextStyles.caption.copyWith(
                          color: user.isVerified
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.role == UserRole.admin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ochreLight,
                      border: Border.all(color: AppColors.ochre),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 14,
                          color: AppColors.ochre,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Admin',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.ochre,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // College Info
          if (user.course.isNotEmpty || user.branch.isNotEmpty || user.year > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'College Information',
                    style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 12),
                  if (user.course.isNotEmpty)
                    _buildInfoRow('Course', user.course),
                  if (user.branch.isNotEmpty)
                    _buildInfoRow('Branch', user.branch),
                  if (user.year > 0) _buildInfoRow('Year', 'Year ${user.year}'),
                  _buildInfoRow('College ID', user.collegeId),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Account Actions
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Listings',
                  subtitle: 'View and manage your listings',
                  onTap: () => context.push('/my-listings'),
                ),
                const Divider(
                  height: 1,
                  color: AppColors.border,
                  indent: 56,
                  endIndent: 16,
                ),
                _buildActionTile(
                  icon: Icons.favorite_outline,
                  title: 'Favorites',
                  subtitle: 'Your saved listings',
                  onTap: () => context.push('/favorites'),
                ),
                const Divider(
                  height: 1,
                  color: AppColors.border,
                  indent: 56,
                  endIndent: 16,
                ),
                _buildActionTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Verification Status',
                  subtitle: user.isVerified
                      ? 'Email verified'
                      : 'Verify your email to unlock all features',
                  onTap: user.isVerified
                      ? null
                      : () => context.push('/verify-email'),
                  trailing: user.isVerified
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const Icon(
                          Icons.chevron_right,
                          color: AppColors.secondaryText,
                        ),
                ),
                const Divider(
                  height: 1,
                  color: AppColors.border,
                  indent: 56,
                  endIndent: 16,
                ),
                _buildActionTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text(
                          'Are you sure you want to log out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Logout',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await ref.read(authProvider).signOut();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  textColor: AppColors.error,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Info
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'CampusMart',
                  style: AppTextStyles.h3.copyWith(color: AppColors.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your campus marketplace',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.charcoal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? textColor,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.ochre).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: textColor ?? AppColors.ochre, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          color: textColor ?? AppColors.charcoal,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.secondaryText)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
