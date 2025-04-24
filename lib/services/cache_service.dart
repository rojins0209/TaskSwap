import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _cachePrefix = 'cache_';
  static const Duration _defaultCacheDuration = Duration(hours: 1);

  // Save data to cache
  static Future<bool> saveToCache(String key, dynamic data, {Duration? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': (expiry ?? _defaultCacheDuration).inMilliseconds,
      };

      return await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error saving to cache: $e');
      return false;
    }
  }

  // Get data from cache
  static Future<dynamic> getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) {
        return null;
      }

      final cacheMap = jsonDecode(cachedData);
      final timestamp = cacheMap['timestamp'] as int;
      final expiry = cacheMap['expiry'] as int;

      // Check if cache is expired
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > expiry) {
        // Cache expired, remove it
        await prefs.remove(cacheKey);
        return null;
      }

      return cacheMap['data'];
    } catch (e) {
      debugPrint('Error getting from cache: $e');
      return null;
    }
  }

  // Clear specific cache
  static Future<bool> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      return await prefs.remove(cacheKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      return false;
    }
  }

  // Clear all cache
  static Future<bool> clearAllCache() async {
    try {
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
}
