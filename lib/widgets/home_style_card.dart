import 'package:flutter/material.dart';

class HomeStyleCard extends StatelessWidget {
  const HomeStyleCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.radius = 18,
    this.accentA = const Color(0xFF2563EB),
    this.accentB = const Color(0xFF1E293B),
    this.alphaA = 0.18,
    this.alphaB = 0.10,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color accentA;
  final Color accentB;
  final double alphaA;
  final double alphaB;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accentA.withValues(alpha: alphaA),
            accentB.withValues(alpha: alphaB),
          ],
        ),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

