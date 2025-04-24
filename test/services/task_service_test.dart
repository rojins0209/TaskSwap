import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/services/cache_service.dart';

// Mock classes
class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

void main() {
  group('TaskService', () {
    late TaskService taskService;
    
    setUp(() {
      taskService = TaskService();
    });
    
    test('getTaskById should return null for non-existent task', () async {
      // This is a simple test that doesn't require mocking
      // It will use the actual Firebase instance but with a non-existent ID
      final result = await taskService.getTaskById('non-existent-id');
      expect(result, isNull);
    });
    
    test('getUserTaskCount should return default values for non-existent user', () async {
      // This is a simple test that doesn't require mocking
      // It will use the actual Firebase instance but with a non-existent ID
      final result = await taskService.getUserTaskCount('non-existent-user');
      expect(result, {'totalTasks': 0, 'completedTasks': 0});
    });
    
    // Test cache functionality
    test('getUserTaskCount should use cache on second call', () async {
      // First, ensure the cache is clear
      await CacheService.clearCache('user_task_count_test-user');
      
      // Create a test task
      final task = Task(
        title: 'Test Task',
        description: 'Test Description',
        createdBy: 'test-user',
        points: 10,
      );
      
      // First call should hit Firestore
      final result1 = await taskService.getUserTaskCount('test-user');
      
      // Manually add to cache to simulate a previous fetch
      await CacheService.saveToCache(
        'user_task_count_test-user',
        {'totalTasks': 5, 'completedTasks': 3},
        expiry: const Duration(minutes: 5)
      );
      
      // Second call should use cache
      final result2 = await taskService.getUserTaskCount('test-user');
      
      // The second result should be the cached value
      expect(result2, {'totalTasks': 5, 'completedTasks': 3});
      
      // Clean up
      await CacheService.clearCache('user_task_count_test-user');
    });
  });
}
