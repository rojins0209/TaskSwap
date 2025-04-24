import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskswap/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService', () {
    setUp(() async {
      // Set up a mock for SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('saveToCache should store data with timestamp and expiry', () async {
      // Arrange
      final testKey = 'test_key';
      final testData = {'name': 'Test User', 'points': 100};
      
      // Act
      final result = await CacheService.saveToCache(testKey, testData);
      
      // Assert
      expect(result, true);
      
      // Verify data was stored
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cache_$testKey'), isNotNull);
    });

    test('getFromCache should return null for non-existent key', () async {
      // Arrange
      final testKey = 'non_existent_key';
      
      // Act
      final result = await CacheService.getFromCache(testKey);
      
      // Assert
      expect(result, isNull);
    });

    test('getFromCache should return data for valid key', () async {
      // Arrange
      final testKey = 'test_key';
      final testData = {'name': 'Test User', 'points': 100};
      await CacheService.saveToCache(testKey, testData);
      
      // Act
      final result = await CacheService.getFromCache(testKey);
      
      // Assert
      expect(result, isNotNull);
      expect(result['name'], 'Test User');
      expect(result['points'], 100);
    });

    test('getFromCache should return null for expired data', () async {
      // Arrange
      final testKey = 'expired_key';
      final testData = {'name': 'Test User', 'points': 100};
      
      // Save with a very short expiry
      await CacheService.saveToCache(
        testKey, 
        testData, 
        expiry: const Duration(milliseconds: 1)
      );
      
      // Wait for expiry
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Act
      final result = await CacheService.getFromCache(testKey);
      
      // Assert
      expect(result, isNull);
    });

    test('clearCache should remove specific cache entry', () async {
      // Arrange
      final testKey1 = 'test_key1';
      final testKey2 = 'test_key2';
      final testData = {'name': 'Test User', 'points': 100};
      
      await CacheService.saveToCache(testKey1, testData);
      await CacheService.saveToCache(testKey2, testData);
      
      // Act
      final result = await CacheService.clearCache(testKey1);
      
      // Assert
      expect(result, true);
      
      // Verify key1 is removed but key2 still exists
      expect(await CacheService.getFromCache(testKey1), isNull);
      expect(await CacheService.getFromCache(testKey2), isNotNull);
    });

    test('clearAllCache should remove all cache entries', () async {
      // Arrange
      final testKey1 = 'test_key1';
      final testKey2 = 'test_key2';
      final testData = {'name': 'Test User', 'points': 100};
      
      await CacheService.saveToCache(testKey1, testData);
      await CacheService.saveToCache(testKey2, testData);
      
      // Act
      final result = await CacheService.clearAllCache();
      
      // Assert
      expect(result, true);
      
      // Verify both keys are removed
      expect(await CacheService.getFromCache(testKey1), isNull);
      expect(await CacheService.getFromCache(testKey2), isNull);
    });
  });
}
