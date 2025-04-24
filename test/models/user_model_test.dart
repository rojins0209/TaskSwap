import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/user_service.dart';

void main() {
  group('UserModel', () {
    test('should create a UserModel with default values', () {
      // Arrange & Act
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
      );

      // Assert
      expect(user.id, equals('test-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
      expect(user.auraPoints, equals(0));
      expect(user.streakCount, equals(0));
      expect(user.completedTasks, equals(0));
      expect(user.totalTasks, equals(0));
      expect(user.friends, isEmpty);
      expect(user.friendRequests, isEmpty);
      expect(user.auraVisibility, equals(AuraVisibility.public));
      expect(user.blockedUsers, isEmpty);
      expect(user.allowAuraFrom, equals(AllowAuraFrom.everyone));
    });

    test('should create a UserModel with custom values', () {
      // Arrange & Act
      final now = DateTime.now();
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        auraPoints: 100,
        createdAt: now,
        lastPointsEarnedAt: now,
        lastAuraDate: now,
        streakCount: 5,
        completedTasks: 10,
        totalTasks: 15,
        friends: ['friend1', 'friend2'],
        friendRequests: ['request1'],
        achievements: ['achievement1'],
        auraVisibility: AuraVisibility.friends,
        blockedUsers: ['blocked1'],
        allowAuraFrom: AllowAuraFrom.friends,
      );

      // Assert
      expect(user.id, equals('test-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.displayName, equals('Test User'));
      expect(user.photoUrl, equals('https://example.com/photo.jpg'));
      expect(user.auraPoints, equals(100));
      expect(user.createdAt, equals(now));
      expect(user.lastPointsEarnedAt, equals(now));
      expect(user.lastAuraDate, equals(now));
      expect(user.streakCount, equals(5));
      expect(user.completedTasks, equals(10));
      expect(user.totalTasks, equals(15));
      expect(user.friends, equals(['friend1', 'friend2']));
      expect(user.friendRequests, equals(['request1']));
      expect(user.achievements, equals(['achievement1']));
      expect(user.auraVisibility, equals(AuraVisibility.friends));
      expect(user.blockedUsers, equals(['blocked1']));
      expect(user.allowAuraFrom, equals(AllowAuraFrom.friends));
    });

    test('toMap should convert UserModel to Map correctly', () {
      // Arrange
      final now = DateTime.now();
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        auraPoints: 100,
        createdAt: now,
        streakCount: 5,
        auraVisibility: AuraVisibility.friends,
        allowAuraFrom: AllowAuraFrom.friends,
      );

      // Act
      final map = user.toMap();

      // Assert
      expect(map['email'], equals('test@example.com'));
      expect(map['displayName'], equals('Test User'));
      expect(map['photoUrl'], equals('https://example.com/photo.jpg'));
      expect(map['auraPoints'], equals(100));
      expect(map['streakCount'], equals(5));
      expect(map['auraVisibility'], equals('friends'));
      expect(map['allowAuraFrom'], equals('friends'));
    });

    test('copyWith should create a new instance with updated values', () {
      // Arrange
      final user = UserModel(
        id: 'test-id',
        email: 'test@example.com',
        auraPoints: 100,
      );

      // Act
      final updatedUser = user.copyWith(
        displayName: 'Updated Name',
        auraPoints: 200,
      );

      // Assert
      expect(updatedUser.id, equals('test-id')); // Unchanged
      expect(updatedUser.email, equals('test@example.com')); // Unchanged
      expect(updatedUser.displayName, equals('Updated Name')); // Updated
      expect(updatedUser.auraPoints, equals(200)); // Updated
    });

    test('equality operator should work correctly', () {
      // Arrange
      final user1 = UserModel(id: 'test-id', email: 'test@example.com');
      final user2 = UserModel(id: 'test-id', email: 'different@example.com');
      final user3 = UserModel(id: 'different-id', email: 'test@example.com');

      // Assert
      expect(user1 == user2, isTrue); // Same ID, different email
      expect(user1 == user3, isFalse); // Different ID
    });
  });
}
