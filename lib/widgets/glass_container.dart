import 'package:flutter/material.dart';

// Custom painter to draw the light grid pattern in the background
class GridPainter extends CustomPainter {
  final Color gridColor;
  final double stepSize;

  GridPainter({
    required this.gridColor,
    this.stepSize = 30.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += stepSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += stepSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor || oldDelegate.stepSize != stepSize;
  }
}

// The clean dashboard floating card with thin border and flat solid/semi-translucent surface
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    // Keep parameters for compatibility
    double blur = 0,
    double borderOpacity = 0,
    double fillOpacity = 0,
    List<Color>? gradientColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors matching the dashboard in the screenshots
    final cardColor = isDark ? const Color(0xFF16171D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262930) : const Color(0xFFE5E8EB);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Dashboard grid background container
class LiquidBackground extends StatelessWidget {
  final Widget child;

  const LiquidBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Background color matching the screenshots
    final backgroundColor = isDark ? const Color(0xFF0D0E12) : const Color(0xFFF9FAFC);
    final gridColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03);

    return Stack(
      children: [
        // Solid background color
        Container(color: backgroundColor),
        // Grid pattern
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(gridColor: gridColor),
          ),
        ),
        // Main content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
