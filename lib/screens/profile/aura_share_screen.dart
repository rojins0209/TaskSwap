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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: _buildBackgroundPattern(),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 28,
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
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),

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
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getUserTitle(auraPoints),
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.auto_awesome,
                        value: auraPoints.toString(),
                        label: 'Aura Points',
                      ),
                      _buildStatItem(
                        icon: Icons.task_alt,
                        value: completedTasks.toString(),
                        label: 'Tasks Done',
                      ),
                      _buildStatItem(
                        icon: Icons.local_fire_department,
                        value: streakCount.toString(),
                        label: 'Day Streak',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Aura breakdown
                  const Text(
                    'Aura Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Breakdown bars
                  ..._buildBreakdownBars(auraBreakdown),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 500));
  }

  Widget _buildBackgroundPattern() {
    return CustomPaint(
      painter: PatternPainter(),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBreakdownBars(Map<String, int> breakdown) {
    final List<Widget> bars = [];
    final List<MapEntry<String, int>> sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get total for percentage calculation
    final int total = breakdown.values.fold(0, (sum, value) => sum + value);
    if (total == 0) return [const Text('No data available', style: TextStyle(color: Colors.white70))];

    for (final entry in sortedEntries) {
      final double percentage = total > 0 ? entry.value / total : 0;
      final String categoryName = entry.key;
      final Color categoryColor = _getCategoryColor(categoryName);

      bars.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.white.withAlpha(50),
                  valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return bars;
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
