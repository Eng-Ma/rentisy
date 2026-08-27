import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  final double? size;
  final Color? color;
  final double strokeWidth;

  const AppLoader({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final loaderColor = color ?? AppColors.primary;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
        ),
      ),
    );
  }
}
