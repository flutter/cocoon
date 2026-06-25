// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';
import 'package:mutex/mutex.dart';
import 'package:redis/redis.dart';

/// Service for reading and writing values to a cache for quick access of data.
abstract class CacheService {
  CacheService();

  /// Factory constructor that returns a [RedisCacheService].
  factory CacheService.redis() = RedisCacheService;

  /// Factory constructor that returns an [InMemoryCacheService].
  factory CacheService.inMemory({int maxEntries}) = InMemoryCacheService;

  /// Google Cloud Memorystore default url.
  static Uri memorystoreUri = Uri.parse('redis://10.0.0.4:6379');

  /// Get value of [key] from the subcache [subcacheName].
  Future<Uint8List?> get(String subcacheName, String key);

  /// Set [value] for [key] in the subcache [subcacheName] with [ttl].
  Future<Uint8List?> set(
    String subcacheName,
    String key,
    Uint8List? value, {
    Duration ttl = const Duration(minutes: 1),
  });

  /// Sets the [value] for [key] in the subcache [subcacheName] with [ttl]
  /// if and only if the key does not already exist.
  ///
  /// Returns `true` if the key was successfully set, or `false` if the key
  /// already existed.
  Future<bool> setIfNotExists(
    String subcacheName,
    String key,
    Uint8List value, {
    Duration ttl = const Duration(minutes: 1),
  });

  /// Get value of [key] from the subcache [subcacheName]. If the key has no
  /// value, call [createFn] to create a value for it, set it, and return it.
  Future<Uint8List?> getOrCreate(
    String subcacheName,
    String key, {
    required Future<Uint8List> Function()? createFn,
    Duration ttl = const Duration(minutes: 1),
  }) async {
    var value = await get(subcacheName, key);

    if (createFn != null && value == null) {
      value = await createFn();
      await set(subcacheName, key, value, ttl: ttl);
    }

    return value;
  }

  /// Clear the value stored in subcache [subcacheName] for key [key].
  Future<void> purge(String subcacheName, String key);

  /// Disposes of any resources held by the cache service.
  Future<void> dispose();

  /// Runs [block] under a distributed lock on [key] with [ttl].
  ///
  /// If the lock cannot be acquired immediately, it will retry up to [retries] times
  /// with exponential backoff and jitter.
  ///
  /// Returns `true` if the lock was successfully acquired and the block was executed,
  /// or `false` if the lock could not be acquired due to contention.
  Future<bool> tryLock(
    String key,
    FutureOr<void> Function() block,
    Duration ttl, [
    int retries = 5,
  ]) async {
    final lockKey = 'lock:$key';
    final token = _generateSecureToken();

    var acquired = false;
    var attempt = 0;

    while (attempt <= retries) {
      acquired = await _acquireLock(lockKey, token, ttl);
      if (acquired) {
        break;
      }
      if (attempt == retries) {
        break;
      }
      attempt++;
      final delay = _calculateBackoff(attempt);
      await Future<void>.delayed(delay);
    }

    if (!acquired) {
      return false;
    }

    try {
      await block();
      return true;
    } finally {
      await _releaseLock(lockKey, token);
    }
  }

  /// Low-level atomic lock acquisition primitive implemented by subclasses.
  @protected
  Future<bool> _acquireLock(String lockKey, String token, Duration ttl);

  /// Low-level atomic lock release primitive implemented by subclasses.
  @protected
  Future<void> _releaseLock(String lockKey, String token);

  static String _generateSecureToken() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static Duration _calculateBackoff(int attempt) {
    final delay = 50 * pow(2, attempt - 1).toInt();
    final jitter = Random().nextInt(30);
    return Duration(milliseconds: delay + jitter);
  }
}

/// A [CacheService] implementation backed by Redis.
class RedisCacheService extends CacheService {
  RedisCacheService() : _client = null;

  Command? _client;

  Future<Command> _getClient() async {
    if (_client != null) {
      return _client!;
    }
    final connection = RedisConnection();
    final client = await connection.connect(
      CacheService.memorystoreUri.host,
      CacheService.memorystoreUri.port,
    );
    _client = client;
    return client;
  }

  Future<T> _runCommand<T>(Future<T> Function(Command client) action) async {
    var client = await _getClient();
    try {
      return await action(client);
    } catch (e) {
      log.warn('Redis command failed, attempting reconnect...', e);
      _client = null; // Force reconnect
      client = await _getClient();
      return await action(client);
    }
  }

  @override
  Future<Uint8List?> get(String subcacheName, String key) async {
    final redisKey = '$subcacheName/$key';
    try {
      final value = await _runCommand((client) => client.send_object(['GET', redisKey]));
      if (value == null) return null;
      return base64.decode(value as String);
    } catch (e) {
      log.warn('Unable to retrieve value for $key from cache.', e);
      return null;
    }
  }

  @override
  Future<Uint8List?> set(
    String subcacheName,
    String key,
    Uint8List? value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    if (value == null) {
      await purge(subcacheName, key);
      return null;
    }

    final redisKey = '$subcacheName/$key';
    final base64Value = base64.encode(value);
    try {
      await _runCommand((client) => client.send_object([
        'SET',
        redisKey,
        base64Value,
        'PX',
        ttl.inMilliseconds,
      ]));
      return value;
    } catch (e) {
      log.warn('Unable to set value for $key in cache.', e);
      return null;
    }
  }

  @override
  Future<bool> setIfNotExists(
    String subcacheName,
    String key,
    Uint8List value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    final redisKey = '$subcacheName/$key';
    final base64Value = base64.encode(value);
    try {
      final response = await _runCommand((client) => client.send_object([
        'SET',
        redisKey,
        base64Value,
        'NX',
        'PX',
        ttl.inMilliseconds,
      ]));
      return response == 'OK';
    } catch (e) {
      log.warn('Unable to set value for $key in cache.', e);
      return false;
    }
  }

  @override
  Future<void> purge(String subcacheName, String key) async {
    final redisKey = '$subcacheName/$key';
    try {
      await _runCommand((client) => client.send_object(['DEL', redisKey]));
    } catch (e) {
      log.warn('Unable to purge value for $key from cache.', e);
    }
  }

  @override
  Future<void> dispose() async {
    _client = null;
  }

  @override
  Future<bool> _acquireLock(String lockKey, String token, Duration ttl) async {
    try {
      final response = await _runCommand((client) => client.send_object([
        'SET',
        lockKey,
        token,
        'NX',
        'PX',
        ttl.inMilliseconds,
      ]));
      return response == 'OK';
    } catch (e) {
      log.warn('Failed to acquire lock for $lockKey', e);
      return false;
    }
  }

  @override
  Future<void> _releaseLock(String lockKey, String token) async {
    const releaseLockScript = '''
      if redis.call("get", KEYS[1]) == ARGV[1] then
          return redis.call("del", KEYS[1])
      else
          return 0
      end
    ''';

    try {
      await _runCommand((client) => client.send_object([
        'EVAL',
        releaseLockScript,
        '1',
        lockKey,
        token,
      ]));
    } catch (e) {
      log.warn('Failed to release lock for $lockKey', e);
    }
  }

}

/// A [CacheService] implementation backed by an in-memory thread-safe map.
class InMemoryCacheService extends CacheService {
  InMemoryCacheService({this.maxEntries = 256});

  final int maxEntries;
  final Map<String, _InMemoryCacheEntry> _entries = {};
  final Map<String, _InMemoryLock> _locks = {};
  final _mutex = Mutex();

  @override
  Future<Uint8List?> get(String subcacheName, String key) async {
    await _mutex.acquire();
    try {
      final cacheKey = '$subcacheName/$key';
      final entry = _entries[cacheKey];
      if (entry == null) return null;
      if (entry.isExpired) {
        _entries.remove(cacheKey);
        return null;
      }
      return entry.value;
    } finally {
      _mutex.release();
    }
  }

  @override
  Future<Uint8List?> set(
    String subcacheName,
    String key,
    Uint8List? value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    if (value == null) {
      await purge(subcacheName, key);
      return null;
    }

    await _mutex.acquire();
    try {
      final cacheKey = '$subcacheName/$key';

      _entries.removeWhere((k, v) => v.isExpired);

      if (_entries.length >= maxEntries && !_entries.containsKey(cacheKey)) {
        _entries.remove(_entries.keys.first);
      }

      _entries[cacheKey] = _InMemoryCacheEntry(value, DateTime.now().add(ttl));
      return value;
    } finally {
      _mutex.release();
    }
  }

  @override
  Future<bool> setIfNotExists(
    String subcacheName,
    String key,
    Uint8List value, {
    Duration ttl = const Duration(minutes: 1),
  }) async {
    await _mutex.acquire();
    try {
      final cacheKey = '$subcacheName/$key';
      final existing = _entries[cacheKey];
      if (existing != null && !existing.isExpired) {
        return false;
      }

      _entries.removeWhere((k, v) => v.isExpired);

      if (_entries.length >= maxEntries && !_entries.containsKey(cacheKey)) {
        _entries.remove(_entries.keys.first);
      }

      _entries[cacheKey] = _InMemoryCacheEntry(value, DateTime.now().add(ttl));
      return true;
    } finally {
      _mutex.release();
    }
  }

  @override
  Future<void> purge(String subcacheName, String key) async {
    await _mutex.acquire();
    try {
      final cacheKey = '$subcacheName/$key';
      _entries.remove(cacheKey);
    } finally {
      _mutex.release();
    }
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> _acquireLock(String lockKey, String token, Duration ttl) async {
    await _mutex.acquire();
    try {
      final existing = _locks[lockKey];
      final now = DateTime.now();
      if (existing != null && !existing.isExpired) {
        return false;
      }
      _locks[lockKey] = _InMemoryLock(token, now.add(ttl));
      return true;
    } finally {
      _mutex.release();
    }
  }

  @override
  Future<void> _releaseLock(String lockKey, String token) async {
    await _mutex.acquire();
    try {
      final existing = _locks[lockKey];
      if (existing != null && existing.token == token) {
        _locks.remove(lockKey);
      }
    } finally {
      _mutex.release();
    }
  }

}

class _InMemoryCacheEntry {
  _InMemoryCacheEntry(this.value, this.expiresAt);

  final Uint8List value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class _InMemoryLock {
  _InMemoryLock(this.token, this.expiresAt);

  final String token;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

extension BoolToUint8List on bool {
  /// Converts this boolean to a [Uint8List] containing a single byte.
  ///
  /// Returns `[1]` for true and `[0]` for false.
  Uint8List toUint8List() {
    return Uint8List.fromList([this ? 1 : 0]);
  }
}

extension Uint8ListToBool on Uint8List {
  /// Converts a [Uint8List] to a boolean.
  ///
  /// Returns `true` if the first byte is non-zero (C-style).
  /// Returns `false` if the list is empty or the first byte is 0.
  bool toBool() {
    if (isEmpty) return false;
    return first != 0;
  }
}
