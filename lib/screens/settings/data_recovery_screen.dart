import 'package:flutter/material.dart';
import 'package:taskswap/services/data_recovery_service.dart';
import 'package:flutter/services.dart';

class DataRecoveryScreen extends StatefulWidget {
  const DataRecoveryScreen({Key? key}) : super(key: key);

  @override
  State<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends State<DataRecoveryScreen> {
  final DataRecoveryService _dataRecoveryService = DataRecoveryService();
  bool _isLoading = false;
  Map<String, dynamic>? _diagnosisResult;
  String? _errorMessage;
  bool _recoveryComplete = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Recovery'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information card
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Data Recovery Tool',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This tool can help diagnose and fix issues with your app data. '
                      'Use this if you\'re experiencing problems with missing friends, '
                      'leaderboard data, or other app functionality.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            // Diagnosis button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _diagnoseDatabaseIssues,
              icon: const Icon(Icons.search),
              label: const Text('Diagnose Database Issues'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recovery button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _performFullRecovery,
              icon: const Icon(Icons.healing),
              label: const Text('Perform Full Data Recovery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing... Please wait'),
                  ],
                ),
              ),
            ],
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Error',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            if (_diagnosisResult != null) ...[
              const SizedBox(height: 24),
              Text(
                'Diagnosis Results',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDiagnosisResultCard(),
            ],
            
            if (_recoveryComplete) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Recovery Complete',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Data recovery process has been completed. Please restart the app to see the changes.',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Return to App'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisResultCard() {
    if (_diagnosisResult == null) {
      return const SizedBox.shrink();
    }

    final result = _diagnosisResult!;
    final items = <Widget>[];

    // User document
    items.add(_buildResultItem(
      'User Document',
      result['userDocExists'] == true ? 'Found' : 'Missing',
      result['userDocExists'] == true ? Icons.check_circle : Icons.error,
      result['userDocExists'] == true ? Colors.green : Colors.red,
    ));

    // Friends count
    items.add(_buildResultItem(
      'Friends',
      '${result['friendsCount'] ?? 0} found',
      result['friendsCount'] > 0 ? Icons.check_circle : Icons.warning,
      result['friendsCount'] > 0 ? Colors.green : Colors.orange,
    ));

    // Tasks count
    items.add(_buildResultItem(
      'Tasks',
      '${result['tasksCount'] ?? 0} found',
      result['tasksCount'] > 0 ? Icons.check_circle : Icons.warning,
      result['tasksCount'] > 0 ? Colors.green : Colors.orange,
    ));

    // Challenges count
    final totalChallenges = (result['sentChallengesCount'] ?? 0) + (result['receivedChallengesCount'] ?? 0);
    items.add(_buildResultItem(
      'Challenges',
      '$totalChallenges found',
      totalChallenges > 0 ? Icons.check_circle : Icons.warning,
      totalChallenges > 0 ? Colors.green : Colors.orange,
    ));

    // Activities count
    items.add(_buildResultItem(
      'Activities',
      '${result['activitiesCount'] ?? 0} found',
      result['activitiesCount'] > 0 ? Icons.check_circle : Icons.warning,
      result['activitiesCount'] > 0 ? Colors.green : Colors.orange,
    ));

    // Firestore connection
    items.add(_buildResultItem(
      'Firestore Connection',
      result['firestoreConnection'] == 'OK' ? 'Connected' : 'Error',
      result['firestoreConnection'] == 'OK' ? Icons.check_circle : Icons.error,
      result['firestoreConnection'] == 'OK' ? Colors.green : Colors.red,
    ));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _diagnoseDatabaseIssues() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      HapticFeedback.mediumImpact();
      final result = await _dataRecoveryService.diagnoseDatabase();
      
      setState(() {
        _diagnosisResult = result;
        _isLoading = false;
        
        if (result.containsKey('error')) {
          _errorMessage = result['error'].toString();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error diagnosing database: $e';
      });
    }
  }

  Future<void> _performFullRecovery() async {
    if (_isLoading) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Recovery'),
        content: const Text(
          'This will attempt to repair your user data, rebuild your friends list, '
          'and recalculate your stats. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      HapticFeedback.mediumImpact();
      final result = await _dataRecoveryService.performFullRecovery();
      
      setState(() {
        _diagnosisResult = result['diagnosis'];
        _isLoading = false;
        _recoveryComplete = result['success'] == true;
        
        if (result.containsKey('error')) {
          _errorMessage = result['error'].toString();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error performing recovery: $e';
      });
    }
  }
}
