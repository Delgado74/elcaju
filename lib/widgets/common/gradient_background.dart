import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Fondo con gradiente diagonal de El Caju
/// Púrpura profundo → Naranja marañón
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.backgroundGradient,
          stops: AppColors.backgroundGradientStops,
        ),
      ),
      child: child,
    );
  }
}
