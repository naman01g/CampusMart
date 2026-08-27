import 'package:flutter/material.dart';
import 'package:campusmart_mobile/core/theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, ghost }

enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool fullWidth;
  final IconData? icon;
  final Color? customColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
    this.icon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = customColor ?? AppColors.ochre;
        foregroundColor = Colors.white;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppColors.charcoal;
        foregroundColor = Colors.white;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primaryText;
        borderSide = const BorderSide(color: AppColors.border);
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primaryText;
        break;
    }

    if (isDisabled) {
      backgroundColor = backgroundColor.withValues(alpha: 0.5);
      foregroundColor = foregroundColor.withValues(alpha: 0.5);
    }

    EdgeInsets padding;
    double fontSize;
    double iconSize;

    switch (size) {
      case ButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        fontSize = 14;
        iconSize = 16;
        break;
      case ButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        fontSize = 16;
        iconSize = 18;
        break;
      case ButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
        fontSize = 18;
        iconSize = 20;
        break;
    }

    Widget child = loading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && !loading) ...[
                Icon(icon, size: iconSize, color: foregroundColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              border: borderSide != null
                  ? Border.fromBorderSide(borderSide)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
