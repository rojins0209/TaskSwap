import 'dart:convert';
import 'dart:collection';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Memory cache entry with expiration
class _MemoryCacheEntry {
  final dynamic data;
  final int timestamp;
  final int expiry;
  int lastAccessed;

  _MemoryCacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiry,
  }) : lastAccessed = DateTime.now().millisecondsSinceEpoch;

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - timestamp > expiry;
  }

  void updateLastAccessed() {
    lastAccessed = DateTime.now().millisecondsSinceEpoch;
  }
}

class CacheService {
  static const String _cachePrefix = 'cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 1);

  // In-memory cache for frequently accessed data
  static final Map<String, _MemoryCacheEntry> _memoryCache = HashMap<String, _MemoryCacheEntry>();

  // Frequently accessed keys that should be prioritized for memory caching
  static final Set<String> _priorityKeys = {
    'user_', // Prefix for user data
    'leaderboard_', // Prefix for leaderboard data
    'tasks_', // Prefix for task lists
    'friends_', // Prefix for friend lists
  };

  // Maximum number of items to keep in memory cache
  static const int _maxMemoryCacheItems = 100;

  // Check if a key should be prioritized for memory caching
  static bool _isPriorityKey(String key) {
    for (final prefix in _priorityKeys) {
      if (key.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  // Clean up memory cache if it exceeds the maximum size
  static void _cleanupMemoryCache() {
    if (_memoryCache.length <= _maxMemoryCacheItems) return;

    // Remove expired entries first
    _memoryCache.removeWhere((_, entry) => entry.isExpired);

    // If still too many entries, remove least recently accessed non-priority entries
    if (_memoryCache.length > _maxMemoryCacheItems) {
      final entries = _memoryCache.entries.toList()
        ..sort((a, b) {
          // Prioritize keeping priority keys
          final aPriority = _isPriorityKey(a.key);
          final bPriority = _isPriorityKey(b.key);

          if (aPriority && !bPriority) return 1;
          if (!aPriority && bPriority) return -1;

          // For same priority level, sort by last accessed time
          return a.value.lastAccessed.compareTo(b.value.lastAccessed);
        });

      // Remove oldest entries until we're under the limit
      final entriesToRemove = entries.take(_memoryCache.length - _maxMemoryCacheItems);
      for (final entry in entriesToRemove) {
        _memoryCache.remove(entry.key);
      }
    }
  }

  // Helper method to convert data to JSON-serializable format
  static dynamic _prepareDataForSerialization(dynamic data) {
    if (data == null) return null;

    // Handle Timestamp objects
    if (data is Timestamp) {
      return {
        '_type': 'timestamp',
        'seconds': data.seconds,
        'nanoseconds': data.nanoseconds,
      };
    }

    // Handle maps (recursively process all values)
    if (data is Map) {
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        result[key.toString()] = _prepareDataForSerialization(value);
      });
      return result;
    }

    // Handle lists (recursively process all items)
    if (data is List) {
      return data.map((item) => _prepareDataForSerialization(item)).toList();
    }

    // Handle DateTime objects
    if (data is DateTime) {
      return {
        '_type': 'datetime',
        'milliseconds': data.millisecondsSinceEpoch,
      };
    }

    // Return primitive types as is
    return data;
  }

  // Save data to both memory and disk cache
  static Future<bool> saveToCache(String key, dynamic data, {Duration? expiry}) async {
    try {
      final expiryMs = (expiry ?? _defaultCacheDuration).inMilliseconds;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Prepare data for serialization
      final serializedData = _prepareDataForSerialization(data);

      // Save to memory cache
      _memoryCache[key] = _MemoryCacheEntry(
        data: data, // Store original data in memory
        timestamp: timestamp,
        expiry: expiryMs,
      );

      // Clean up memory cache if needed
      _cleanupMemoryCache();

      // Save to disk cache
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      final cacheData = {
        'data': serializedData,
        'timestamp': timestamp,
        'expiry': expiryMs,
      };

      return await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error saving to cache: $e');
      return false;
    }
  }

  // Helper method to deserialize data from JSON format
  static dynamic _deserializeData(dynamic data) {
    if (data == null) return null;

    // Handle special types
    if (data is Map) {
      // Check if this is a serialized Timestamp
      if (data['_type'] == 'timestamp' && data.containsKey('seconds') && data.containsKey('nanoseconds')) {
        return Timestamp(data['seconds'] as int, data['nanoseconds'] as int);
      }

      // Check if this is a serialized DateTime
      if (data['_type'] == 'datetime' && data.containsKey('milliseconds')) {
        return DateTime.fromMillisecondsSinceEpoch(data['milliseconds'] as int);
      }

      // Recursively deserialize map values
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        result[key.toString()] = _deserializeData(value);
      });
      return result;
    }

    // Handle lists (recursively deserialize all items)
    if (data is List) {
      return data.map((item) => _deserializeData(item)).toList();
    }

    // Return primitive types as is
    return data;
  }

  // Get data from cache (first check memory, then disk)
  static Future<dynamic> getFromCache(String key) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;

        // Check if memory cache is expired
        if (entry.isExpired) {
          _memoryCache.remove(key);
        } else {
          // Update last accessed time and return data
          entry.updateLastAccessed();
          return entry.data;
        }
      }

      // If not in memory or expired, check disk cache
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) {
        return null;
      }

      final cacheMap = jsonDecode(cachedData);
      final timestamp = cacheMap['timestamp'] as int;
      final expiry = cacheMap['expiry'] as int;
      final serializedData = cacheMap['data'];

      // Deserialize the data
      final data = _deserializeData(serializedData);

      // Check if disk cache is expired
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > expiry) {
        // Cache expired, remove it
        await prefs.remove(cacheKey);
        return null;
      }

      // Cache hit from disk, store in memory for faster access next time
      _memoryCache[key] = _MemoryCacheEntry(
        data: data,
        timestamp: timestamp,
        expiry: expiry,
      );

      // Clean up memory cache if needed
      _cleanupMemoryCache();

      return data;
    } catch (e) {
      debugPrint('Error getting from cache: $e');
      return null;
    }
  }

  // Clear specific cache (both memory and disk)
  static Future<bool> clearCache(String key) async {
    try {
      // Clear from memory cache
      _memoryCache.remove(key);

      // Clear from disk cache
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      return await prefs.remove(cacheKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      return false;
    }
  }

  // Clear all cache (both memory and disk)
  static Future<bool> clearAllCache() async {
    try {
      // Clear memory cache
      _memoryCache.clear();

      // Clear disk cache
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
      return false;
    }
  }

  // Prefetch frequently accessed data
  static Future<void> prefetchFrequentData(String userId) async {
    try {
      // This method can be called on app startup to preload important data
      // The actual data fetching will be done by the respective services
      debugPrint('Prefetching frequent data for user: $userId');

      // We don't need to do anything here - this is just a hook for services
      // to use when implementing their own prefetching logic
    } catch (e) {
      debugPrint('Error prefetching data: $e');
    }
  }
}
