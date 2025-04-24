import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/constants/gamification_constants.dart';

class AnimationUtils {
  // Controller for confetti animation
  static ConfettiController createConfettiController({
    Duration duration = const Duration(seconds: 3),
  }) {
    return ConfettiController(duration: duration);
  }

  // Show a celebration animation with confetti
  static void showCelebrationOverlay({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required ConfettiController confettiController,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          // Dialog content
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                // Trophy icon with animation
                Icon(
                  icon,
                  size: 80,
                  color: iconColor,
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                )
                .shimmer(
                  duration: const Duration(milliseconds: 1500),
                  color: Colors.white,
                  size: 0.4,
                ),
                const SizedBox(height: 24),

                // Title with animation
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 400))
                .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 16),

                // Message with animation
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 200),
                )
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 200),
                ),

                const SizedBox(height: 24),

                // Dismiss button with animation
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onDismiss != null) {
                        onDismiss();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Awesome!'),
                  ),
                )
                .animate()
                .fadeIn(
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 400),
                )
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 400),
                ),
              ],
            ),
          ),

          // Confetti animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.amber,
              ],
            ),
          ),
        ],
      ),
    );

    // Start confetti animation
    confettiController.play();
  }

  // Show a task completion animation
  static void showTaskCompletionAnimation({
    required BuildContext context,
    required String taskTitle,
    required int pointsEarned,
    required ConfettiController confettiController,
    VoidCallback? onDismiss,
    bool isChallenge = true,
  }) {
    String message = isChallenge
        ? 'You earned $pointsEarned aura points for completing "$taskTitle"'
        : 'Task completed! Share with friends to earn aura points';

    showCelebrationOverlay(
      context: context,
      title: 'Task Completed!',
      message: message,
      icon: Icons.task_alt,
      iconColor: Colors.green,
      confettiController: confettiController,
      onDismiss: onDismiss,
    );
  }

  // Show a milestone achievement animation
  static void showMilestoneAnimation({
    required BuildContext context,
    required String milestone,
    required int bonusPoints,
    required ConfettiController confettiController,
    VoidCallback? onDismiss,
  }) {
    showCelebrationOverlay(
      context: context,
      title: 'Achievement Unlocked!',
      message: 'You reached "$milestone" and earned $bonusPoints bonus aura points!',
      icon: Icons.emoji_events,
      iconColor: Colors.amber,
      confettiController: confettiController,
      onDismiss: onDismiss,
    );
  }

  // Show a streak milestone animation
  static void showStreakMilestoneAnimation({
    required BuildContext context,
    required int streakDays,
    required int bonusPoints,
    required ConfettiController confettiController,
    VoidCallback? onDismiss,
  }) {
    showCelebrationOverlay(
      context: context,
      title: '$streakDays Day Streak!',
      message: 'You\'ve been consistent for $streakDays days and earned $bonusPoints bonus aura points!',
      icon: Icons.local_fire_department,
      iconColor: Colors.orange,
      confettiController: confettiController,
      onDismiss: onDismiss,
    );
  }

  // Show an enhanced task completion animation with pulse effect
  static void showEnhancedTaskCompletionAnimation({
    required BuildContext context,
    required String taskTitle,
    required int pointsEarned,
    int? bonusPoints,
    VoidCallback? onDismiss,
  }) {
    // Create and play confetti controller
    final confettiController = ConfettiController(duration: const Duration(seconds: 3))..play();

    // Show celebration overlay
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Confetti animation
                SizedBox(
                  height: 100,
                  child: ConfettiWidget(
                    confettiController: confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    particleDrag: 0.05,
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    gravity: 0.2,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                    ],
                  ),
                ),

                // Celebration icon
                Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: Colors.amber,
                ).animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                  ),
                const SizedBox(height: 16),

                // Task completed text
                Text(
                  'Task Completed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ).animate()
                  .fadeIn(duration: const Duration(milliseconds: 400))
                  .slideY(begin: 0.5, end: 0, duration: const Duration(milliseconds: 400)),
                const SizedBox(height: 8),

                // Task title
                Text(
                  taskTitle,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).animate()
                  .fadeIn(delay: const Duration(milliseconds: 200), duration: const Duration(milliseconds: 400))
                  .slideY(begin: 0.5, end: 0, duration: const Duration(milliseconds: 400)),
                const SizedBox(height: 24),

                // Points earned
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+$pointsEarned Aura Points',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(delay: const Duration(milliseconds: 400), duration: const Duration(milliseconds: 400))
                  .scale(
                    delay: const Duration(milliseconds: 400),
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: const Duration(milliseconds: 400),
                  ),

                // Bonus points if any
                if (bonusPoints != null && bonusPoints > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.purple,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+$bonusPoints Bonus Points',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(delay: const Duration(milliseconds: 600), duration: const Duration(milliseconds: 400))
                    .scale(
                      delay: const Duration(milliseconds: 600),
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: const Duration(milliseconds: 400),
                    ),
                ],

                const SizedBox(height: 24),

                // Close button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onDismiss != null) {
                      onDismiss();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Awesome!'),
                ).animate()
                  .fadeIn(delay: const Duration(milliseconds: 800), duration: const Duration(milliseconds: 400)),
              ],
            ),
          ),
        );
      },
    );
  }
}
