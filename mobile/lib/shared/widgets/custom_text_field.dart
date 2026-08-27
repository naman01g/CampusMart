import 'package:flutter/material.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';
import 'package:campusmart_mobile/core/theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? maxLength;
  final Widget? suffixIcon;
  final bool enabled;
  final String? helperText;
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.suffixIcon,
    this.enabled = true,
    this.helperText,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.secondaryText,
            ),
            helperText: helperText,
            helperStyle: AppTextStyles.caption,
            suffixIcon: suffixIcon,
            counterText: '',
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
}
