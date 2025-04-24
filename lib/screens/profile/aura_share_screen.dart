import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/services/aura_share_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/widgets/aura_share_card.dart';

class AuraShareScreen extends StatefulWidget {
  const AuraShareScreen({super.key});

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
      final auraData = await _auraShareService.getUserAuraData();
      
      if (mounted) {
        setState(() {
          _auraData = auraData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load aura data: $e';
          _isLoading = false;
        });
      }
    }
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
                        ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0, duration: 300.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Share your aura progress with friends and celebrate your achievements!',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideX(begin: -0.1, end: 0, duration: 300.ms),
                        const SizedBox(height: 24),
                        
                        // Aura share card
                        AuraShareCard(
                          user: _auraData!['user'],
                          auraPoints: _auraData!['auraPoints'],
                          completedTasks: _auraData!['completedTasks'],
                          streakCount: _auraData!['streakCount'],
                          auraBreakdown: Map<String, int>.from(_auraData!['auraBreakdown']),
                        ),
                        
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
                        ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
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
