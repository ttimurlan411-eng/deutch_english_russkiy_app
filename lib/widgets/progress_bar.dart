import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A slim progress bar with a rounded shape.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color = AppTheme.primary,
    this.backgroundColor = const Color(0xFFE8EAF2),
  });

  /// Progress between 0.0 and 1.0.
  final double value;

  /// Thickness of the bar.
  final double height;

  /// Color of the filled part.
  final Color color;

  /// Color of the remaining part.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: clamped),
        builder: (context, animated, _) {
          return LinearProgressIndicator(
            value: animated,
            minHeight: height,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          );
        },
      ),
    );
  }
}
