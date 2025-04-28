import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:taskswap/models/user_model.dart';

class AuraShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's aura breakdown
  Future<Map<String, dynamic>> getUserAuraData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      return getUserAuraDataById(currentUser.uid);
    } catch (e) {
      debugPrint('Error getting user aura data: $e');
      rethrow;
    }
  }

  // Get a specific user's aura breakdown by ID
  Future<Map<String, dynamic>> getUserAuraDataById(String userId) async {
    try {
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Get completed tasks to analyze aura breakdown
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .get();

      // Calculate aura breakdown by task type
      final Map<String, int> auraBreakdown = {};

      for (var doc in tasksSnapshot.docs) {
        final taskData = doc.data();
        final taskType = taskData['type'] as String? ?? 'Other';

        if (auraBreakdown.containsKey(taskType)) {
          auraBreakdown[taskType] = auraBreakdown[taskType]! + 1;
        } else {
          auraBreakdown[taskType] = 1;
        }
      }

      // If no completed tasks with types, add some default categories
      if (auraBreakdown.isEmpty) {
        auraBreakdown['Personal'] = 0;
        auraBreakdown['Challenge'] = 0;
      }

      // Create user model
      final user = UserModel.fromFirestore(userDoc);

      // Convert UserModel to Map for the AuraShareCard
      final userMap = {
        'id': user.id,
        'displayName': user.displayName ?? 'User',
        'email': user.email,
        'photoUrl': user.photoUrl,
      };

      return {
        'user': userMap,
        'auraPoints': userData['auraPoints'] ?? 0,
        'completedTasks': userData['completedTasks'] ?? 0,
        'streakCount': userData['streakCount'] ?? 0,
        'auraBreakdown': auraBreakdown,
      };
    } catch (e) {
      debugPrint('Error getting user aura data by ID: $e');
      rethrow;
    }
  }

  // Generate a summary text of the user's aura
  String generateAuraSummaryText(Map<String, int> auraBreakdown, int totalPoints, int streakCount) {
    final StringBuffer summary = StringBuffer();
    summary.write('My TaskSwap Aura: $totalPoints points');

    if (streakCount > 0) {
      summary.write(', $streakCount day streak! 🔥\n\n');
    } else {
      summary.write('!\n\n');
    }

    if (auraBreakdown.isNotEmpty) {
      summary.write('Breakdown: ');

      final List<String> breakdownParts = [];
      auraBreakdown.forEach((type, count) {
        String emoji;
        switch (type) {
          case 'Gym':
            emoji = '💪';
            break;
          case 'Study':
            emoji = '📚';
            break;
          case 'Work':
            emoji = '💼';
            break;
          case 'Mindfulness':
            emoji = '🧘';
            break;
          case 'Health':
            emoji = '❤️';
            break;
          case 'Social':
            emoji = '👥';
            break;
          case 'Creative':
            emoji = '🎨';
            break;
          case 'Challenge':
            emoji = '🏆';
            break;
          case 'Personal':
            emoji = '👤';
            break;
          default:
            emoji = '⭐';
        }

        breakdownParts.add('$count $type $emoji');
      });

      summary.write(breakdownParts.join(', '));
    }

    return summary.toString();
  }
}
