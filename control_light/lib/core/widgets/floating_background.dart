import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FloatingBackground extends StatefulWidget {
  const FloatingBackground({super.key});

  @override
  State<FloatingBackground> createState() => _FloatingBackgroundState();
}

class _FloatingBackgroundState extends State<FloatingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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
      builder: (_, __) {
        final palette = AppColors.of(Theme.of(context).brightness);
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [const Color(0xFF102347), palette.background],
              radius: 0.9 + sin(_controller.value * pi) * 0.05,
            ),
          ),
          child: Stack(
            children: [
              _glow(const Offset(0.2, 0.15), AppColors.accentCyan),
              _glow(const Offset(0.8, 0.25), AppColors.accentPurple),
              _glow(const Offset(0.5, 0.85), AppColors.accentGreen),
            ],
          ),
        );
      },
    );
  }

  Widget _glow(Offset alignment, Color color) {
    return Align(
      alignment: Alignment(alignment.dx * 2 - 1, alignment.dy * 2 - 1),
      child: Transform.scale(
        scale: 1 + sin(_controller.value * pi * 2) * 0.08,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
