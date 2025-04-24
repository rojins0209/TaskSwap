import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class AuthBackground extends StatefulWidget {
  final Widget child;

  const AuthBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      isDark
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surfaceContainerLow,
                    ],
                    stops: const [0.3, 1.0],
                    transform: GradientRotation(_controller.value * 2 * math.pi),
                  ),
                ),
              );
            },
          ),

          // Top wave decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(size.width, size.height * 0.4),
                  painter: WavePainter(
                    color: colorScheme.primary.withAlpha(30),
                    waveHeight: 40,
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
          ),

          // Animated floating bubbles
          ...List.generate(8, (index) {
            final random = math.Random(index);
            final bubbleSize = 20.0 + random.nextDouble() * 80;
            final posX = random.nextDouble() * MediaQuery.of(context).size.width;
            final posY = random.nextDouble() * MediaQuery.of(context).size.height;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final animValue = (_controller.value + index / 8) % 1.0;
                final yOffset = math.sin(animValue * 2 * math.pi) * 20;

                return Positioned(
                  left: posX,
                  top: posY + yOffset,
                  child: Container(
                    height: bubbleSize,
                    width: bubbleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? (index % 2 == 0 ? Colors.purpleAccent.withAlpha(20) : Colors.blueAccent.withAlpha(15))
                          : (index % 2 == 0 ? Colors.tealAccent.withAlpha(20) : Colors.blueAccent.withAlpha(15)),
                    ),
                  ),
                );
              },
            );
          }),

          // Bottom wave decoration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(size.width, size.height * 0.2),
                  painter: BottomWavePainter(
                    color: colorScheme.secondary.withAlpha(20),
                    waveHeight: 30,
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
          ),

          // Main content with modern container design
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Top decorative element
                      Container(
                        width: 80,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 30),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white30 : Colors.black12,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),

                      // Main form container
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isDark
                                  ? const Color(0xCC1E1E2A) // 80% opacity
                                  : const Color(0xCCFFFFFF), // 80% opacity
                              isDark
                                  ? const Color(0xE615151F) // 90% opacity
                                  : const Color(0xE6F8F9FA), // 90% opacity
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withAlpha(25) // 10% opacity
                                : Colors.black.withAlpha(13), // 5% opacity
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withAlpha(77) // 30% opacity
                                  : Colors.black.withAlpha(20), // 8% opacity
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),

                      // Bottom decorative element
                      Container(
                        width: 60,
                        height: 6,
                        margin: const EdgeInsets.only(top: 30),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white30 : Colors.black12,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  final double waveHeight;
  final double animationValue;

  WavePainter({required this.color, required this.waveHeight, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from top left
    path.moveTo(0, 0);

    // Line to top right
    path.lineTo(size.width, 0);

    // Line to bottom right (before wave)
    path.lineTo(size.width, size.height - waveHeight);

    // Create wave pattern with animation
    final waveWidth = size.width / 3;
    final animOffset = animationValue * size.width;

    // First curve down
    path.quadraticBezierTo(
      size.width - waveWidth * 0.75 + animOffset % waveWidth,
      size.height - waveHeight * 0.5,
      size.width - waveWidth * 1.5 + animOffset % waveWidth,
      size.height
    );

    // Second curve up
    path.quadraticBezierTo(
      size.width - waveWidth * 2.25 + animOffset % waveWidth,
      size.height + waveHeight * 0.5,
      size.width - waveWidth * 3 + animOffset % waveWidth,
      size.height - waveHeight * 0.2
    );

    // Third curve down
    path.quadraticBezierTo(
      size.width - waveWidth * 3.75 + animOffset % waveWidth,
      size.height - waveHeight * 0.8,
      0,
      size.height - waveHeight * 0.5
    );

    // Close the path
    path.lineTo(0, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class BottomWavePainter extends CustomPainter {
  final Color color;
  final double waveHeight;
  final double animationValue;

  BottomWavePainter({required this.color, required this.waveHeight, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from bottom left
    path.moveTo(0, size.height);

    // Line to bottom right
    path.lineTo(size.width, size.height);

    // Line to top right (before wave)
    path.lineTo(size.width, waveHeight);

    // Create wave pattern with animation (reversed direction)
    final waveWidth = size.width / 3;
    final animOffset = -animationValue * size.width;

    // First curve up
    path.quadraticBezierTo(
      size.width - waveWidth * 0.75 + animOffset % waveWidth,
      waveHeight * 0.5,
      size.width - waveWidth * 1.5 + animOffset % waveWidth,
      0
    );

    // Second curve down
    path.quadraticBezierTo(
      size.width - waveWidth * 2.25 + animOffset % waveWidth,
      -waveHeight * 0.5,
      size.width - waveWidth * 3 + animOffset % waveWidth,
      waveHeight * 0.2
    );

    // Third curve up
    path.quadraticBezierTo(
      size.width - waveWidth * 3.75 + animOffset % waveWidth,
      waveHeight * 0.8,
      0,
      waveHeight * 0.5
    );

    // Close the path
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BottomWavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
