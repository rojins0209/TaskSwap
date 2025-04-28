import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/aura_share_service.dart';

// AuraShareCard Widget
class AuraShareCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final int auraPoints;
  final int completedTasks;
  final int streakCount;
  final Map<String, int> auraBreakdown;

  const AuraShareCard({
    Key? key,
    required this.user,
    required this.auraPoints,
    required this.completedTasks,
    required this.streakCount,
    required this.auraBreakdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate level based on aura points
    final int level = (auraPoints / 100).floor() + 1;
    final int pointsForNextLevel = level * 100;
    final double progress = (auraPoints % 100) / 100;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromColor(colorScheme.primary).withLightness(0.4).toColor(),
            HSLColor.fromColor(colorScheme.tertiary).withLightness(0.3).toColor(),
          ],
          stops: const [0.2, 0.9],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(60),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withAlpha(30),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: const ColorFilter.mode(
            Colors.black12,
            BlendMode.srcOver,
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: _buildBackgroundPattern(),
              ),

              // Glowing orb in the background
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withAlpha(80),
                        Colors.white.withAlpha(0),
                      ],
                      stops: const [0.1, 1.0],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with logo and level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App logo
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TaskSwap',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withAlpha(50),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Level $level',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // User info with avatar
                    Row(
                      children: [
                        // Avatar with glow effect
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withAlpha(100),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white.withAlpha(50),
                            backgroundImage: user['photoUrl'] != null && user['photoUrl'].isNotEmpty
                                ? NetworkImage(user['photoUrl'])
                                : null,
                            child: user['photoUrl'] == null || user['photoUrl'].isEmpty
                                ? Text(
                                    _getInitials(user['displayName'] ?? user['email'] ?? '?'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),

                        // User name and title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['displayName'] ?? user['email'] ?? 'Anonymous',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getTitleColor(auraPoints).withAlpha(50),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getTitleColor(auraPoints).withAlpha(100),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getUserTitle(auraPoints),
                                      style: TextStyle(
                                        color: _getTitleColor(auraPoints),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (streakCount >= 3) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withAlpha(50),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange.withAlpha(100),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            color: Colors.orange,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$streakCount',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Level progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress to Level ${level + 1}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$auraPoints / $pointsForNextLevel',
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            // Background
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            // Progress
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber,
                                      Colors.orange,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withAlpha(100),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Stats cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.auto_awesome,
                            value: auraPoints.toString(),
                            label: 'Aura Points',
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.task_alt,
                            value: completedTasks.toString(),
                            label: 'Tasks Done',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Aura breakdown
                    Text(
                      'Aura Breakdown',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Breakdown bars with animation
                    ..._buildBreakdownBars(auraBreakdown),

                    // Footer with timestamp
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Generated on ${DateTime.now().toString().split(' ')[0]}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 600))
    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack);
  }

  Widget _buildBackgroundPattern() {
    return CustomPaint(
      painter: PatternPainter(),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTitleColor(int points) {
    if (points >= 1000) return Colors.purple;
    if (points >= 500) return Colors.blue;
    if (points >= 250) return Colors.green;
    if (points >= 100) return Colors.amber;
    return Colors.white;
  }

  List<Widget> _buildBreakdownBars(Map<String, int> breakdown) {
    final List<Widget> bars = [];
    final List<MapEntry<String, int>> sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get total for percentage calculation
    final int total = breakdown.values.fold(0, (sum, value) => sum + value);
    if (total == 0) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'No task data available yet.\nComplete tasks to see your aura breakdown!',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        )
      ];
    }

    // For animation delay calculation
    int index = 0;

    for (final entry in sortedEntries) {
      final double percentage = total > 0 ? entry.value / total : 0;
      final String categoryName = entry.key;
      final Color categoryColor = _getCategoryColor(categoryName);
      final int count = entry.value;

      // Calculate animation delay based on index
      final int delayMs = 100 + (index * 50);

      bars.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: categoryColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(categoryName),
                      color: categoryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Category name
                  Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),

                  // Count and percentage
                  Row(
                    children: [
                      Text(
                        count.toString(),
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${(percentage * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress bar with animation
              Stack(
                children: [
                  // Background
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),

                  // Animated progress
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutQuart,
                    height: 10,
                    width: percentage * 300, // Fixed width based on percentage
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          categoryColor.withAlpha(200),
                          categoryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withAlpha(60),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: delayMs),
        ).slideX(
          begin: 0.1,
          end: 0,
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: delayMs),
          curve: Curves.easeOutQuad,
        ),
      );

      index++;
    }

    return bars;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Icons.work;
      case 'health':
        return Icons.favorite;
      case 'learning':
        return Icons.school;
      case 'personal':
        return Icons.person;
      case 'gym':
        return Icons.fitness_center;
      case 'meditation':
        return Icons.self_improvement;
      case 'reading':
        return Icons.menu_book;
      case 'challenge':
        return Icons.emoji_events;
      default:
        return Icons.category;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  String _getUserTitle(int points) {
    if (points >= 1000) return 'Aura Master';
    if (points >= 500) return 'Aura Expert';
    if (points >= 250) return 'Aura Adept';
    if (points >= 100) return 'Aura Apprentice';
    return 'Aura Novice';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blue;
      case 'health':
        return Colors.green;
      case 'learning':
        return Colors.purple;
      case 'personal':
        return Colors.orange;
      case 'gym':
        return Colors.red;
      case 'meditation':
        return Colors.teal;
      case 'reading':
        return Colors.indigo;
      default:
        return Colors.amber;
    }
  }
}

// Pattern Painter for background
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withAlpha(10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw diagonal lines
    for (double i = 0; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(0, i),
        paint,
      );
    }

    // Draw circles
    paint.style = PaintingStyle.fill;
    final double maxRadius = size.width * 0.1;
    final List<Offset> circlePositions = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.7),
    ];

    for (final position in circlePositions) {
      canvas.drawCircle(
        position,
        maxRadius * (0.5 + 0.5 * position.dx / size.width),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuraShareScreen extends StatefulWidget {
  final UserModel? userProfile;

  const AuraShareScreen({super.key, this.userProfile});

  @override
  State<AuraShareScreen> createState() => _AuraShareScreenState();
}

class _AuraShareScreenState extends State<AuraShareScreen> {
  final AuraShareService _auraShareService = AuraShareService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _auraData;

  @override
  void initState() {
    super.initState();
    _loadAuraData();
  }

  Future<void> _loadAuraData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final auraData = widget.userProfile != null
          ? await _auraShareService.getUserAuraDataById(widget.userProfile!.id)
          : await _auraShareService.getUserAuraData();

      if (mounted) {
        setState(() {
          _auraData = auraData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading aura data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load aura data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Builds the aura share card with error handling
  Widget _buildAuraShareCard() {
    try {
      // Validate that all required data is present
      if (_auraData == null) {
        return _buildErrorCard('No aura data available');
      }

      // Check for required fields
      if (!_auraData!.containsKey('user') ||
          !_auraData!.containsKey('auraPoints') ||
          !_auraData!.containsKey('completedTasks') ||
          !_auraData!.containsKey('streakCount') ||
          !_auraData!.containsKey('auraBreakdown')) {
        return _buildErrorCard('Incomplete aura data');
      }

      // Safely extract and convert data
      final Map<String, int> auraBreakdown = {};
      try {
        final rawBreakdown = _auraData!['auraBreakdown'];
        if (rawBreakdown is Map) {
          rawBreakdown.forEach((key, value) {
            if (key is String && value is int) {
              auraBreakdown[key] = value;
            }
          });
        }
      } catch (e) {
        debugPrint('Error parsing aura breakdown: $e');
      }

      // Return the actual card with safely extracted data
      Map<String, dynamic> userMap;

      // Handle the user data safely
      if (_auraData!['user'] is Map) {
        userMap = Map<String, dynamic>.from(_auraData!['user']);
      } else {
        // Fallback user data if the user object is not a Map
        userMap = {
          'displayName': 'User',
          'email': 'user@example.com',
          'photoUrl': null,
          'id': '',
        };
      }

      return AuraShareCard(
        user: userMap,
        auraPoints: _auraData!['auraPoints'] ?? 0,
        completedTasks: _auraData!['completedTasks'] ?? 0,
        streakCount: _auraData!['streakCount'] ?? 0,
        auraBreakdown: auraBreakdown,
      );
    } catch (e) {
      debugPrint('Error building aura card: $e');
      return _buildErrorCard('Error displaying aura card');
    }
  }

  /// Builds a fallback error card when the aura card can't be displayed
  Widget _buildErrorCard(String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.errorContainer,
            colorScheme.error.withAlpha(179), // ~70% opacity
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to display Aura Card',
            style: TextStyle(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: colorScheme.onErrorContainer.withAlpha(204), // ~80% opacity
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAuraData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Share Your Aura',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: _loadAuraData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your aura data...',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: colorScheme.onSurface),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadAuraData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Intro text
                        Text(
                          'Your Aura Card',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
                        const SizedBox(height: 8),
                        Text(
                          'Share your aura progress with friends and celebrate your achievements!',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
                        const SizedBox(height: 24),

                        // Aura share card with error handling
                        _buildAuraShareCard(),

                        const SizedBox(height: 32),

                        // Tips section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tips to Boost Your Aura',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTipItem(
                                icon: Icons.local_fire_department,
                                color: Colors.orange,
                                text: 'Complete tasks daily to maintain your streak',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 8),
                              _buildTipItem(
                                icon: Icons.emoji_events,
                                color: Colors.amber,
                                text: 'Challenge friends to earn bonus points',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 8),
                              _buildTipItem(
                                icon: Icons.diversity_3,
                                color: Colors.green,
                                text: 'Diversify your task types for a balanced aura',
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required Color color,
    required String text,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
