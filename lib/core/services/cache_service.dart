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
  final Map<String, Map<String, dynamic>> _treatmentsCache = {};
  final Map<String, Map<String, dynamic>> _emotionalDataCache = {};

  // Stream controllers for notifying UI components
  final Map<String, StreamController<Map<String, dynamic>>>
      _userStreamControllers = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>>
      _treatmentsStreamControllers = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>>
      _emotionalDataStreamControllers = {};

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
        return cachedData['data'] as Map<String, dynamic>;
      }
    }

    // Check persistent cache if not in memory
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('USER_$userId');

      if (cachedJson != null) {
        try {
          final cachedData = jsonDecode(cachedJson) as Map<String, dynamic>;
          final expiryTime = cachedData['expiryTime'] as int;

          // If persistent cache is valid, update memory cache and return
          if (DateTime.now().millisecondsSinceEpoch < expiryTime) {
            _userCache[userId] = cachedData;
            debugPrint('💾 Using persistent cache for user $userId');
            return cachedData['data'] as Map<String, dynamic>;
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
      final cachedData = _userCache[userId]['data'] as Map<String, dynamic>;
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

  // SUBCOLLECTION METHODS

  /// Get user treatments from cache or fetch if needed
  Future<List<Map<String, dynamic>>> getUserTreatments(
    String userId, {
    bool forceRefresh = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cacheKey =
        'treatments_${startDate?.toIso8601String() ?? ''}_${endDate?.toIso8601String() ?? ''}';

    // Check in-memory cache first
    if (!forceRefresh &&
        _treatmentsCache.containsKey(userId) &&
        _treatmentsCache[userId]!.containsKey(cacheKey)) {
      final cachedData = _treatmentsCache[userId]![cacheKey];
      final expiryTime = cachedData['expiryTime'] as int;

      // If cache is still valid, return it
      if (DateTime.now().millisecondsSinceEpoch < expiryTime) {
        debugPrint('📋 Using in-memory cache for treatments of user $userId');
        return (cachedData['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
    }

    // Check persistent cache if not in memory
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('USER_${userId}_TREATMENTS_$cacheKey');

      if (cachedJson != null) {
        try {
          final cachedData = jsonDecode(cachedJson) as Map<String, dynamic>;
          final expiryTime = cachedData['expiryTime'] as int;

          // If persistent cache is valid, update memory cache and return
          if (DateTime.now().millisecondsSinceEpoch < expiryTime) {
            if (!_treatmentsCache.containsKey(userId)) {
              _treatmentsCache[userId] = {};
            }

            // Restore timestamps in cached data
            final treatmentsData = (cachedData['data'] as List)
                .map((item) =>
                    _restoreTimestamps(Map<String, dynamic>.from(item)))
                .toList();

            _treatmentsCache[userId]![cacheKey] = {
              'data': treatmentsData,
              'expiryTime': expiryTime,
            };

            debugPrint(
                '💾 Using persistent cache for treatments of user $userId');
            return treatmentsData;
          }
        } catch (e) {
          debugPrint('Cache decode error: $e');
        }
      }
    }

    // If cache invalid or force refresh, fetch new data
    return await _fetchAndCacheTreatments(userId, cacheKey, startDate, endDate);
  }

  /// Fetch treatments from Firestore and update cache
  Future<List<Map<String, dynamic>>> _fetchAndCacheTreatments(
    String userId,
    String cacheKey,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      debugPrint('🔄 Fetching fresh treatment data for $userId');

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userTreatments');

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('date', isLessThan: endDate);
      }

      final querySnapshot = await query.get();

      final List<Map<String, dynamic>> treatments =
          querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Ensure the document ID is included
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Update caches
      await updateTreatmentsCache(userId, cacheKey, treatments);

      return treatments;
    } catch (e) {
      debugPrint('❌ Error fetching treatment data: $e');
      return [];
    }
  }

  /// Update treatments cache (memory and persistent)
  Future<void> updateTreatmentsCache(
    String userId,
    String cacheKey,
    List<Map<String, dynamic>> treatments,
  ) async {
    // Convert all Timestamps to serializable format
    final serializableTreatments = treatments.map((treatment) {
      return _convertTimestamps(treatment);
    }).toList();

    // Create cache object with expiry
    final cacheObject = {
      'data': serializableTreatments,
      'expiryTime': DateTime.now().add(defaultExpiry).millisecondsSinceEpoch,
    };

    // Update memory cache
    if (!_treatmentsCache.containsKey(userId)) {
      _treatmentsCache[userId] = {};
    }
    _treatmentsCache[userId]![cacheKey] = cacheObject;

    // Update persistent cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'USER_${userId}_TREATMENTS_$cacheKey', jsonEncode(cacheObject));

    // Notify listeners if any
    if (_treatmentsStreamControllers.containsKey(userId) &&
        !_treatmentsStreamControllers[userId]!.isClosed) {
      _treatmentsStreamControllers[userId]!.add(treatments);
    }
  }

  /// Get emotional data from cache or fetch if needed
  Future<List<Map<String, dynamic>>> getUserEmotionalData(
    String userId, {
    bool forceRefresh = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cacheKey =
        'emotional_${startDate?.toIso8601String() ?? ''}_${endDate?.toIso8601String() ?? ''}';

    // Check in-memory cache first
    if (!forceRefresh &&
        _emotionalDataCache.containsKey(userId) &&
        _emotionalDataCache[userId]!.containsKey(cacheKey)) {
      final cachedData = _emotionalDataCache[userId]![cacheKey];
      final expiryTime = cachedData['expiryTime'] as int;

      // If cache is still valid, return it
      if (DateTime.now().millisecondsSinceEpoch < expiryTime) {
        debugPrint(
            '📋 Using in-memory cache for emotional data of user $userId');
        return (cachedData['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
    }

    // Check persistent cache if not in memory
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('USER_${userId}_EMOTIONAL_$cacheKey');

      if (cachedJson != null) {
        try {
          final cachedData = jsonDecode(cachedJson) as Map<String, dynamic>;
          final expiryTime = cachedData['expiryTime'] as int;

          // If persistent cache is valid, update memory cache and return
          if (DateTime.now().millisecondsSinceEpoch < expiryTime) {
            if (!_emotionalDataCache.containsKey(userId)) {
              _emotionalDataCache[userId] = {};
            }
            _emotionalDataCache[userId]![cacheKey] = cachedData;
            debugPrint(
                '💾 Using persistent cache for emotional data of user $userId');
            return (cachedData['data'] as List)
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          }
        } catch (e) {
          debugPrint('Cache decode error: $e');
        }
      }
    }

    // If cache invalid or force refresh, fetch new data
    return await _fetchAndCacheEmotionalData(
        userId, cacheKey, startDate, endDate);
  }

  /// Fetch emotional data from Firestore and update cache
  Future<List<Map<String, dynamic>>> _fetchAndCacheEmotionalData(
    String userId,
    String cacheKey,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      debugPrint('🔄 Fetching fresh emotional data for $userId');

      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emotionalData');

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('date', isLessThan: endDate);
      }

      final querySnapshot = await query.get();

      final List<Map<String, dynamic>> emotionalData =
          querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Ensure the document ID is included
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Update caches
      await _updateEmotionalDataCache(userId, cacheKey, emotionalData);

      return emotionalData;
    } catch (e) {
      debugPrint('❌ Error fetching emotional data: $e');
      return [];
    }
  }

  /// Update emotional data cache (memory and persistent)
  Future<void> _updateEmotionalDataCache(
    String userId,
    String cacheKey,
    List<Map<String, dynamic>> emotionalData,
  ) async {
    // Create cache object with expiry
    final cacheObject = {
      'data': emotionalData,
      'expiryTime': DateTime.now().add(defaultExpiry).millisecondsSinceEpoch,
    };

    // Update memory cache
    if (!_emotionalDataCache.containsKey(userId)) {
      _emotionalDataCache[userId] = {};
    }
    _emotionalDataCache[userId]![cacheKey] = cacheObject;

    // Update persistent cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'USER_${userId}_EMOTIONAL_$cacheKey', jsonEncode(cacheObject));

    // Notify listeners if any
    if (_emotionalDataStreamControllers.containsKey(userId) &&
        !_emotionalDataStreamControllers[userId]!.isClosed) {
      _emotionalDataStreamControllers[userId]!.add(emotionalData);
    }
  }

  /// Get stream of treatments data for reactive UI
  Stream<List<Map<String, dynamic>>> getTreatmentsStream(String userId) {
    if (!_treatmentsStreamControllers.containsKey(userId)) {
      _treatmentsStreamControllers[userId] =
          StreamController<List<Map<String, dynamic>>>.broadcast();
      _setupTreatmentsListener(userId);
    }

    return _treatmentsStreamControllers[userId]!.stream;
  }

  /// Set up firestore listener for treatments
  void _setupTreatmentsListener(String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userTreatments')
        .snapshots()
        .listen((querySnapshot) {
      final List<Map<String, dynamic>> treatments =
          querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Update all treatment caches to avoid stale data
      for (final cacheKey in _treatmentsCache[userId]?.keys ?? <String>[]) {
        updateTreatmentsCache(userId, cacheKey, treatments);
      }
    });
  }

  /// Get stream of emotional data for reactive UI
  Stream<List<Map<String, dynamic>>> getEmotionalDataStream(String userId) {
    if (!_emotionalDataStreamControllers.containsKey(userId)) {
      _emotionalDataStreamControllers[userId] =
          StreamController<List<Map<String, dynamic>>>.broadcast();
      _setupEmotionalDataListener(userId);
    }

    return _emotionalDataStreamControllers[userId]!.stream;
  }

  /// Set up firestore listener for emotional data
  void _setupEmotionalDataListener(String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('emotionalData')
        .snapshots()
        .listen((querySnapshot) {
      final List<Map<String, dynamic>> emotionalData =
          querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Update all emotional data caches to avoid stale data
      for (final cacheKey in _emotionalDataCache[userId]?.keys ?? <String>[]) {
        _updateEmotionalDataCache(userId, cacheKey, emotionalData);
      }
    });
  }

  /// Clear specific cache
  Future<void> clearCache(String userId,
      {bool clearUser = true,
      bool clearTreatments = true,
      bool clearEmotional = true}) async {
    final prefs = await SharedPreferences.getInstance();

    if (clearUser) {
      _userCache.remove(userId);
      await prefs.remove('USER_$userId');
    }

    if (clearTreatments) {
      _treatmentsCache.remove(userId);
      // Clear all treatment cache keys
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('USER_${userId}_TREATMENTS_'))
          .toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    }

    if (clearEmotional) {
      _emotionalDataCache.remove(userId);
      // Clear all emotional data cache keys
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('USER_${userId}_EMOTIONAL_'))
          .toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    }
  }

  /// Dispose resources
  void dispose(String userId) {
    if (_userStreamControllers.containsKey(userId)) {
      _userStreamControllers[userId]!.close();
      _userStreamControllers.remove(userId);
    }

    if (_treatmentsStreamControllers.containsKey(userId)) {
      _treatmentsStreamControllers[userId]!.close();
      _treatmentsStreamControllers.remove(userId);
    }

    if (_emotionalDataStreamControllers.containsKey(userId)) {
      _emotionalDataStreamControllers[userId]!.close();
      _emotionalDataStreamControllers.remove(userId);
    }
  }
}

Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
  return data.map((key, value) {
    if (value is Timestamp) {
      return MapEntry(key, {
        '__type__': 'timestamp',
        'seconds': value.seconds,
        'nanoseconds': value.nanoseconds,
      });
    } else if (value is Map<String, dynamic>) {
      return MapEntry(key, _convertTimestamps(value));
    } else if (value is List) {
      return MapEntry(
          key,
          value.map((e) {
            if (e is Map<String, dynamic>) {
              return _convertTimestamps(e);
            }
            return e;
          }).toList());
    }
    return MapEntry(key, value);
  });
}

// And the reverse method
Map<String, dynamic> _restoreTimestamps(Map<String, dynamic> data) {
  return data.map((key, value) {
    if (value is Map && value['__type__'] == 'timestamp') {
      return MapEntry(key, Timestamp(value['seconds'], value['nanoseconds']));
    } else if (value is Map<String, dynamic>) {
      return MapEntry(key, _restoreTimestamps(value));
    } else if (value is List) {
      return MapEntry(
          key,
          value.map((e) {
            if (e is Map<String, dynamic>) {
              return _restoreTimestamps(e);
            }
            return e;
          }).toList());
    }
    return MapEntry(key, value);
  });
}
