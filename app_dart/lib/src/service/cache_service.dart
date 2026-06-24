// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:redis/redis.dart';

/// Service for reading and writing values to a cache for quick access of data.
///
/// If [inMemory] is true, a cache with [inMemoryMaxNumberEntries] number
/// of entries will be created. Otherwise, it will use the default redis cache.
class CacheService {
  CacheService({this.inMemory = false, this.inMemoryMaxNumberEntries = 256})
    : _inMemoryCache = inMemory
          ? _InMemoryCache(inMemoryMaxNumberEntries)
          : null;

  final bool inMemory;
  final int inMemoryMaxNumberEntries;
  final _InMemoryCache? _inMemoryCache;

  /// Google Cloud Memorystore default url.
  static Uri memorystoreUri = Uri.parse('redis://10.0.0.4:6379');

  static const int maxCacheGetAttempts = 3;

  Command? _client;
  final _clientLock = Mutex();
  final _random = Random.secure();

  Future<Command> _getClient() async {
    if (_client != null) return _client!;
    await _clientLock.acquire();
    try {
      if (_client != null) return _client!;
      final conn = RedisConnection();
      final uri = memorystoreUri;
      _client = await conn.connect(uri.host, uri.port);
      return _client!;
    } finally {
      _clientLock.release();
    }
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

  /// Get value of [key] from the subcache [subcacheName].
  Future<Uint8List?> get(String subcacheName, String key) async {
    if (inMemory) {
      return await _inMemoryCache!.get(subcacheName, key);
    }

    final redisKey = '$subcacheName/$key';
    try {
      final value = await _runCommand(
        (client) => client.send_object(['GET', redisKey]),
      );
      if (value == null) return null;
      return base64.decode(value as String);
    } catch (e) {
      log.warn('Unable to retrieve value for $key from cache.', e);
      return null;
    }
  }

  /// Set [value] for [key] in the subcache [subcacheName] with [ttl].
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

    if (inMemory) {
      await _inMemoryCache!.set(subcacheName, key, value, ttl);
      return value;
    }

    final redisKey = '$subcacheName/$key';
    final base64Value = base64.encode(value);
    try {
      await _runCommand(
        (client) => client.send_object([
          'SET',
          redisKey,
          base64Value,
          'PX',
          ttl.inMilliseconds,
        ]),
      );
      return value;
    } catch (e) {
      log.warn('Unable to set value for $key in cache.', e);
      return null;
    }
  }

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
  Future<void> purge(String subcacheName, String key) async {
    if (inMemory) {
      await _inMemoryCache!.purge(subcacheName, key);
      return;
    }

    final redisKey = '$subcacheName/$key';
    try {
      await _runCommand((client) => client.send_object(['DEL', redisKey]));
    } catch (e) {
      log.warn('Unable to purge value for $key from cache.', e);
    }
  }

  /// Attempts to acquire a distributed lock for [key] with [ttl].
  ///
  /// If acquired, executes [block] and returns `true`. If the lock is held,
  /// retries up to [retries] times with exponential backoff and jitter.
  /// If still unable to acquire, returns `false`.
  ///
  /// Ensures the lock is released atomically using a unique token so that
  /// we do not accidentally delete a lock acquired by another instance if
  /// our TTL expired.
  Future<bool> tryLock(
    String key,
    FutureOr<void> Function() block,
    Duration ttl, [
    int retries = 5,
  ]) async {
    final token = _generateUniqueToken();
    final lockKey = 'lock:$key';

    var acquired = false;
    var attempt = 0;

    while (attempt <= retries) {
      acquired = await _acquireLock(lockKey, token, ttl);
      if (acquired) {
        break;
      }
      attempt++;
      if (attempt <= retries) {
        final delay = _getBackoffDelay(attempt);
        await Future<void>.delayed(delay);
      }
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

  Future<bool> _acquireLock(String lockKey, String token, Duration ttl) async {
    if (inMemory) {
      return await _inMemoryCache!.acquireLock(lockKey, token, ttl);
    }

    try {
      final response = await _runCommand(
        (client) => client.send_object([
          'SET',
          lockKey,
          token,
          'NX',
          'PX',
          ttl.inMilliseconds,
        ]),
      );
      return response == 'OK';
    } catch (e) {
      log.warn('Failed to acquire lock for $lockKey', e);
      return false;
    }
  }

  Future<void> _releaseLock(String lockKey, String token) async {
    if (inMemory) {
      await _inMemoryCache!.releaseLock(lockKey, token);
      return;
    }

    const releaseLockScript = '''
      if redis.call("get", KEYS[1]) == ARGV[1] then
          return redis.call("del", KEYS[1])
      else
          return 0
      end
    ''';

    try {
      await _runCommand(
        (client) => client.send_object([
          'EVAL',
          releaseLockScript,
          '1',
          lockKey,
          token,
        ]),
      );
    } catch (e) {
      log.warn('Failed to release lock for $lockKey', e);
    }
  }

  String _generateUniqueToken() {
    final values = List<int>.generate(16, (i) => _random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Duration _getBackoffDelay(int attempt) {
    final baseDelay = 50; // ms
    final maxDelay = 1000; // ms
    final factor = pow(2, attempt).toInt();
    final delay = min(baseDelay * factor, maxDelay);
    final jitter = _random.nextInt(delay ~/ 2 + 1);
    return Duration(milliseconds: delay + jitter);
  }

  Future<void> dispose() async {
    _client = null;
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

class _InMemoryCache {
  _InMemoryCache(this.maxEntries);

  final int maxEntries;
  final Map<String, _InMemoryCacheEntry> _entries = {};
  final Map<String, _InMemoryLock> _locks = {};
  final _mutex = Mutex();

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

  Future<void> set(
    String subcacheName,
    String key,
    Uint8List value,
    Duration ttl,
  ) async {
    await _mutex.acquire();
    try {
      final cacheKey = '$subcacheName/$key';

      _entries.removeWhere((k, v) => v.isExpired);

      if (_entries.length >= maxEntries && !_entries.containsKey(cacheKey)) {
        _entries.remove(_entries.keys.first);
      }

      _entries[cacheKey] = _InMemoryCacheEntry(value, DateTime.now().add(ttl));
    } finally {
      _mutex.release();
    }
  }

  Future<void> purge(String subcacheName, String key) async {
    await _mutex.acquire();
    try {
      final cacheKey = '$subcacheName/$key';
      _entries.remove(cacheKey);
    } finally {
      _mutex.release();
    }
  }

  Future<bool> acquireLock(String lockKey, String token, Duration ttl) async {
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

  Future<void> releaseLock(String lockKey, String token) async {
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
