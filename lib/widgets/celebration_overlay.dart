import 'dart:math';
import 'package:flutter/material.dart';
import 'package:taskswap/theme/app_theme.dart';

class CelebrationOverlay extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const CelebrationOverlay({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  final List<Confetti> _confetti = [];
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    // Create confetti pieces
    for (int i = 0; i < 100; i++) {
      _confetti.add(Confetti(
        color: _getRandomColor(),
        position: Offset(
          _random.nextDouble() * 400 - 50, // x position
          -50 - _random.nextDouble() * 100, // start above the screen
        ),
        size: 8 + _random.nextDouble() * 8, // random size
        velocity: Offset(
          _random.nextDouble() * 200 - 100, // random x velocity
          300 + _random.nextDouble() * 200, // random y velocity
        ),
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: _random.nextDouble() * 2 - 1,
      ));
    }
    
    // Set up animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
    
    _controller.addListener(() {
      setState(() {
        // Update confetti positions
        for (var confetti in _confetti) {
          confetti.position += confetti.velocity * 0.016; // Assuming 60fps
          confetti.rotation += confetti.rotationSpeed * 0.1;
          
          // Apply gravity
          confetti.velocity += const Offset(0, 9.8 * 0.016);
        }
      });
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      AppTheme.accentColor,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Stack(
          children: [
            // Background overlay
            Container(
              color: Colors.black.withOpacity(0.3),
            ),
            
            // Confetti
            ..._confetti.map((confetti) => Positioned(
              left: confetti.position.dx,
              top: confetti.position.dy,
              child: Transform.rotate(
                angle: confetti.rotation,
                child: Container(
                  width: confetti.size,
                  height: confetti.size,
                  decoration: BoxDecoration(
                    color: confetti.color,
                    shape: _random.nextBool() ? BoxShape.circle : BoxShape.rectangle,
                  ),
                ),
              ),
            )),
            
            // Celebration text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Challenge Completed!',
                    style: AppTheme.headingLarge.copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You earned aura points!',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Confetti {
  Color color;
  Offset position;
  double size;
  Offset velocity;
  double rotation;
  double rotationSpeed;
  
  Confetti({
    required this.color,
    required this.position,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}
