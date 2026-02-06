import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

/// Tarjeta con efecto glassmorphism cálido
/// Cristal "ahumado" con tinte naranja sutil
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.glassBase.withValues(alpha: AppColors.glassOpacity),
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.cardBorderRadius,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: AppColors.glassBorderOpacity),
          width: AppDimensions.cardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: AppDimensions.cardShadowBlur,
            offset: const Offset(0, AppDimensions.cardShadowOffsetY),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
