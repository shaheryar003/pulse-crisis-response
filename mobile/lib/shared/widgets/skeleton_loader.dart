import 'package:flutter/material.dart';
import '../tokens.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 48,
    this.borderRadius = PulseRadii.xxl,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Shift gradient horizontally to create a 45deg sweep
        final val = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: const Alignment(-2.0, -1.0),
              end: const Alignment(2.0, 1.0),
              stops: const [0.0, 0.5, 1.0],
              colors: const [
                PulseColors.ink800,
                PulseColors.ink700,
                PulseColors.ink800,
              ],
              transform: _TranslateGradient(val),
            ),
          ),
        );
      },
    );
  }
}

class _TranslateGradient extends GradientTransform {
  final double value;
  const _TranslateGradient(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Moves the gradient from -width to +width over the course of the animation
    final dx = bounds.width * (value * 2 - 1);
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}
