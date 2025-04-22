import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserCacheService {
  // Singleton pattern
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  // In-memory cache
  final Map<String, dynamic> _userCache = {};

  // Stream controllers for notifying UI components
  final Map<String, StreamController<Map<String, dynamic>>>
      _userStreamControllers = {};

  // Default expiry time
  final Duration defaultExpiry = const Duration(hours: 2);

  /// Initialize and fetch user data
  Future<Map<String, dynamic>?> initializeUser(String userId) async {
    final userData = await _fetchAndCacheUser(userId);
    _setupUserListener(userId);
    return userData;
  }

  /// Get user data from cache or fetch if needed
  Future<Map<String, dynamic>?> getUserData(String userId,
      {bool forceRefresh = false}) async {
    // Check in-memory cache first
    if (!forceRefresh && _userCache.containsKey(userId)) {
      final cachedData = _userCache[userId];
      final expiryTime = cachedData['expiryTime'] as int;

      // If cache is still valid, return it
      if (DateTime.now().millisecondsSinceEpoch < expiryTime) {
        debugPrint('📋 Using in-memory cache for user $userId');
        return cachedData['data'];
      }
    }

    // Check persistent cache if not in memory
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('USER_$userId');

      if (cachedJson != null) {
        try {
          final cachedData = jsonDecode(cachedJson);
          final expiryTime = cachedData['expiryTime'] as int;

          // If persistent cache is valid, update memory cache and return
          if (DateTime.now().millisecondsSinceEpoch < expiryTime) {
            _userCache[userId] = cachedData;
            debugPrint('💾 Using persistent cache for user $userId');
            return cachedData['data'];
          }
        } catch (e) {
          debugPrint('Cache decode error: $e');
        }
      }
    }

    // If cache invalid or force refresh, fetch new data
    return await _fetchAndCacheUser(userId);
  }

  /// Fetch user from Firestore and update cache
  Future<Map<String, dynamic>?> _fetchAndCacheUser(String userId) async {
    try {
      debugPrint('🔄 Fetching fresh user data for $userId');
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        debugPrint('⚠️ User document does not exist: $userId');
        return null;
      }

      final userData = docSnapshot.data();
      if (userData == null) return null;

      // Update caches
      await _updateCache(userId, userData);

      return userData;
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
      return null;
    }
  }

  /// Update both memory and persistent cache
  Future<void> _updateCache(
      String userId, Map<String, dynamic> userData) async {
    // Create cache object with expiry
    final cacheObject = {
      'data': userData,
      'expiryTime': DateTime.now().add(defaultExpiry).millisecondsSinceEpoch,
    };

    // Update memory cache
    _userCache[userId] = cacheObject;

    // Update persistent cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('USER_$userId', jsonEncode(cacheObject));

    // Notify listeners if any
    if (_userStreamControllers.containsKey(userId) &&
        !_userStreamControllers[userId]!.isClosed) {
      _userStreamControllers[userId]!.add(userData);
    }
  }

  /// Set up firestore listener for real-time updates
  void _setupUserListener(String userId) {
    // Create stream controller if not exists
    if (!_userStreamControllers.containsKey(userId)) {
      _userStreamControllers[userId] =
          StreamController<Map<String, dynamic>>.broadcast();
    }

    // Set up Firestore listener
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((docSnapshot) {
      if (!docSnapshot.exists) return;

      final userData = docSnapshot.data();
      if (userData == null) return;

      // Update cache with new data
      _updateCache(userId, userData);
    });
  }

  /// Get stream of user data for reactive UI
  Stream<Map<String, dynamic>> getUserStream(String userId) {
    if (!_userStreamControllers.containsKey(userId)) {
      _userStreamControllers[userId] =
          StreamController<Map<String, dynamic>>.broadcast();
      _setupUserListener(userId);
    }

    // Immediately serve cached data if available
    if (_userCache.containsKey(userId)) {
      final cachedData = _userCache[userId]['data'];
      Future.microtask(() {
        if (!_userStreamControllers[userId]!.isClosed) {
          _userStreamControllers[userId]!.add(cachedData);
        }
      });
    }

    return _userStreamControllers[userId]!.stream;
  }

  /// Access specific fields from user data
  Future<T?> getUserField<T>(String userId, String fieldPath) async {
    final userData = await getUserData(userId);
    if (userData == null) return null;

    return _extractNestedField<T>(userData, fieldPath);
  }

  /// Helper to extract nested fields using dot notation
  T? _extractNestedField<T>(Map<String, dynamic> data, String fieldPath) {
    final parts = fieldPath.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current is Map) {
        if (!current.containsKey(part)) {
          return null;
        }
        current = current[part];
      } else if (current is List && int.tryParse(part) != null) {
        final index = int.parse(part);
        if (index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }

    return current as T?;
  }

  /// Dispose resources
  void dispose(String userId) {
    if (_userStreamControllers.containsKey(userId)) {
      _userStreamControllers[userId]!.close();
      _userStreamControllers.remove(userId);
    }
  }
}
