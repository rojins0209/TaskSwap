import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// A utility class for managing transactions and preventing duplicate submissions
class TransactionManager {
  // Singleton instance
  static final TransactionManager _instance = TransactionManager._internal();
  factory TransactionManager() => _instance;
  TransactionManager._internal();

  // Get the singleton instance
  static TransactionManager get instance => _instance;

  // Map to track in-progress operations
  final Map<String, _Transaction> _inProgressTransactions = {};

  // Map to track recently completed transactions to prevent duplicates
  final Map<String, DateTime> _recentTransactions = {};

  // Lock for concurrent access
  final _lock = Object();

  /// Generate a unique transaction ID
  String generateTransactionId() {
    return const Uuid().v4();
  }

  /// Check if a transaction is already in progress
  bool isTransactionInProgress(String transactionId) {
    return synchronized(_lock, () {
      return _inProgressTransactions.containsKey(transactionId);
    });
  }

  /// Check if a transaction was recently completed (to prevent duplicates)
  bool wasRecentlyCompleted(String operationType, String entityId, {Duration window = const Duration(seconds: 5)}) {
    final transactionKey = '$operationType:$entityId';

    return synchronized(_lock, () {
      final completionTime = _recentTransactions[transactionKey];
      if (completionTime == null) {
        return false;
      }

      final now = DateTime.now();
      final elapsed = now.difference(completionTime);

      // Clean up old entries
      _cleanupOldTransactions();

      return elapsed < window;
    });
  }

  /// Execute a transaction with duplicate prevention
  /// Returns the result of the transaction, or null if it was a duplicate
  Future<T?> executeTransaction<T>({
    required String operationType,
    required String entityId,
    required Future<T> Function() operation,
    Duration deduplicationWindow = const Duration(seconds: 5),
  }) async {
    final transactionKey = '$operationType:$entityId';
    final transactionId = generateTransactionId();

    // Check for recent duplicate
    if (wasRecentlyCompleted(operationType, entityId, window: deduplicationWindow)) {
      debugPrint('Duplicate transaction detected: $transactionKey');
      return null;
    }

    // Register this transaction
    synchronized(_lock, () {
      _inProgressTransactions[transactionId] = _Transaction(
        id: transactionId,
        operationType: operationType,
        entityId: entityId,
        startTime: DateTime.now(),
      );
    });

    try {
      // Execute the operation
      final result = await operation();

      // Mark as completed
      synchronized(_lock, () {
        _inProgressTransactions.remove(transactionId);
        _recentTransactions[transactionKey] = DateTime.now();
      });

      return result;
    } catch (e) {
      // Remove from in-progress on error
      synchronized(_lock, () {
        _inProgressTransactions.remove(transactionId);
      });
      rethrow;
    }
  }

  /// Clean up old transactions to prevent memory leaks
  void _cleanupOldTransactions() {
    final now = DateTime.now();

    // Remove transactions older than 10 minutes
    _recentTransactions.removeWhere((key, time) {
      return now.difference(time) > const Duration(minutes: 10);
    });

    // Remove stale in-progress transactions (stuck for more than 5 minutes)
    _inProgressTransactions.removeWhere((id, transaction) {
      return now.difference(transaction.startTime) > const Duration(minutes: 5);
    });
  }

  /// Execute a function with a lock to prevent concurrent access
  T synchronized<T>(Object lock, T Function() function) {
    // In a real implementation, this would use a mutex or semaphore
    // For now, we'll just execute the function directly since Dart is single-threaded
    // in the main isolate
    return function();
  }
}

/// Internal class to represent a transaction
class _Transaction {
  final String id;
  final String operationType;
  final String entityId;
  final DateTime startTime;

  _Transaction({
    required this.id,
    required this.operationType,
    required this.entityId,
    required this.startTime,
  });
}
