import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isOutlined ? null : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        border: isOutlined
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      text,
                      style: AppTextStyles.button.copyWith(
                        color: isOutlined
                            ? AppColors.primary
                            : AppColors.textWhite,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
