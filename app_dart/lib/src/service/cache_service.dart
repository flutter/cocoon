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

class VersionedCacheEntry {
  const VersionedCacheEntry({
    required this.key,
    required this.value,
    required this.revisionId,
    this.ttl = const Duration(hours: 12),
  });

  final String key;
  final Uint8List value;
  final int revisionId;
  final Duration ttl;
}

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

  /// Get values for multiple [keys] from the subcache [subcacheName] in a single batch API call.
  Future<List<Uint8List?>> getMulti(String subcacheName, List<String> keys);

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

  /// Atomically inserts multiple [entries] into [subcacheName] in a single batch API call
  /// if and only if their [VersionedCacheEntry.revisionId] is strictly greater than any
  /// existing cached revision for that key.
  Future<void> insertVersioned(
    String subcacheName,
    List<VersionedCacheEntry> entries,
  );

  /// Get the set of string values for [key] from the subcache [subcacheName].
  Future<Set<String>> getSet(String subcacheName, String key);

  /// Atomically adds [values] to the set at [key] in [subcacheName].
  /// If the set does not yet exist, it is created with [ttl].
  /// If the set already exists, all [values] are added to it without altering its TTL.
  Future<void> updateSet(
    String subcacheName,
    String key,
    Set<String> values, {
    Duration ttl = const Duration(hours: 12),
  });

  /// Atomically adds [value] to the set at [key] in [subcacheName] if and only if the set already exists.
  /// Returns `true` if the set existed and [value] was added, or `false` if the set did not exist.
  Future<bool> addToSetIfExists(String subcacheName, String key, String value);

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

  @override
  Future<List<Uint8List?>> getMulti(
    String subcacheName,
    List<String> keys,
  ) async {
    if (keys.isEmpty) return const [];
    try {
      final redisKeys = keys.map((k) => '$subcacheName/$k').toList();
      final values = await _runCommand(
        (client) => client.send_object(['MGET', ...redisKeys]),
      );
      if (values is! List) {
        return List.filled(keys.length, null);
      }
      return values.map((value) {
        if (value == null) return null;
        return base64.decode(value as String);
      }).toList();
    } catch (e) {
      log.warn('Unable to retrieve multi-values from cache.', e);
      return List.filled(keys.length, null);
    }
  }

  @override
  Future<void> insertVersioned(
    String subcacheName,
    List<VersionedCacheEntry> entries,
  ) async {
    if (entries.isEmpty) return;
    const insertVersionedScript = '''
      local numKeys = tonumber(ARGV[1])
      for i = 1, numKeys do
        local key = KEYS[i]
        local val = ARGV[1 + (i - 1) * 3 + 1]
        local rev = tonumber(ARGV[1 + (i - 1) * 3 + 2])
        local ttl = tonumber(ARGV[1 + (i - 1) * 3 + 3])

        local revKey = "revisions/" .. key
        local existingRev = tonumber(redis.call("get", revKey) or 0)
        if rev > existingRev or (not redis.call("exists", key)) then
          redis.call("set", key, val, "PX", ttl)
          redis.call("set", revKey, rev, "PX", ttl)
        end
      end
      return 1
    ''';
    const batchSize = 20;
    for (var i = 0; i < entries.length; i += batchSize) {
      final chunk = entries.sublist(i, min(i + batchSize, entries.length));
      try {
        final keys = chunk.map((e) => '$subcacheName/${e.key}').toList();
        final args = [
          chunk.length.toString(),
          for (final e in chunk) ...[
            base64.encode(e.value),
            e.revisionId.toString(),
            e.ttl.inMilliseconds.toString(),
          ],
        ];
        await _runCommand(
          (client) => client.send_object([
            'EVAL',
            insertVersionedScript,
            keys.length.toString(),
            ...keys,
            ...args,
          ]),
        );
      } catch (e) {
        log.warn('Unable to insert versioned entries into cache.', e);
      }
    }
  }

  @override
  Future<Set<String>> getSet(String subcacheName, String key) async {
    final redisKey = '$subcacheName/$key';
    try {
      final values = await _runCommand(
        (client) => client.send_object(['SMEMBERS', redisKey]),
      );
      if (values is! List || values.isEmpty) {
        return const {};
      }
      return values.map((e) => e.toString()).toSet();
    } catch (e) {
      log.warn('Unable to retrieve set for $key from cache.', e);
      return const {};
    }
  }

  @override
  Future<void> updateSet(
    String subcacheName,
    String key,
    Set<String> values, {
    Duration ttl = const Duration(hours: 12),
  }) async {
    if (values.isEmpty) return;
    const updateSetScript = '''
      if redis.call("exists", KEYS[1]) == 1 then
        for i = 1, #ARGV - 1 do
          redis.call("sadd", KEYS[1], ARGV[i])
        end
      else
        for i = 1, #ARGV - 1 do
          redis.call("sadd", KEYS[1], ARGV[i])
        end
        redis.call("pexpire", KEYS[1], tonumber(ARGV[#ARGV]))
      end
      return 1
    ''';
    final redisKey = '$subcacheName/$key';
    try {
      final args = [...values, ttl.inMilliseconds.toString()];
      await _runCommand(
        (client) => client.send_object([
          'EVAL',
          updateSetScript,
          '1',
          redisKey,
          ...args,
        ]),
      );
    } catch (e) {
      log.warn('Unable to update set for $key in cache.', e);
    }
  }

  @override
  Future<bool> addToSetIfExists(
    String subcacheName,
    String key,
    String value,
  ) async {
    const addToSetScript = '''
      if redis.call("exists", KEYS[1]) == 1 then
        redis.call("sadd", KEYS[1], ARGV[1])
        return 1
      end
      return 0
    ''';
    final redisKey = '$subcacheName/$key';
    try {
      final response = await _runCommand(
        (client) =>
            client.send_object(['EVAL', addToSetScript, '1', redisKey, value]),
      );
      return response == 1 || response == '1';
    } catch (e) {
      log.warn('Unable to add to set for $key in cache.', e);
      return false;
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
      final response = await _runCommand(
        (client) => client.send_object([
          'SET',
          redisKey,
          base64Value,
          'NX',
          'PX',
          ttl.inMilliseconds,
        ]),
      );
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
      await _runCommand(
        (client) =>
            client.send_object(['DEL', redisKey, 'revisions/$redisKey']),
      );
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
}

/// A [CacheService] implementation backed by an in-memory thread-safe map.
class InMemoryCacheService extends CacheService {
  InMemoryCacheService({this.maxEntries = 256});

  final int maxEntries;
  final Map<String, _InMemoryCacheEntry> _entries = {};
  final Map<String, _InMemorySetEntry> _sets = {};
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
  Future<List<Uint8List?>> getMulti(
    String subcacheName,
    List<String> keys,
  ) async {
    await _mutex.acquire();
    try {
      return keys.map((key) {
        final cacheKey = '$subcacheName/$key';
        final entry = _entries[cacheKey];
        if (entry == null || entry.isExpired) {
          _entries.remove(cacheKey);
          return null;
        }
        return entry.value;
      }).toList();
    } finally {
      _mutex.release();
    }
  }

  @override
  Future<void> insertVersioned(
    String subcacheName,
    List<VersionedCacheEntry> entries,
  ) async {
    if (entries.isEmpty) return;
    await _mutex.acquire();
    try {
      _entries.removeWhere((k, v) => v.isExpired);
      for (final entry in entries) {
        final cacheKey = '$subcacheName/${entry.key}';
        final existing = _entries[cacheKey];
        if (existing == null ||
            existing.isExpired ||
            entry.revisionId > existing.revisionId) {
          if (_entries.length >= maxEntries &&
              !_entries.containsKey(cacheKey)) {
            _entries.remove(_entries.keys.first);
          }
          _entries[cacheKey] = _InMemoryCacheEntry(
            entry.value,
            DateTime.now().add(entry.ttl),
            revisionId: entry.revisionId,
          );
        }
      }
    } finally {
      _mutex.release();
    }
  }

  @override
  Future<Set<String>> getSet(String subcacheName, String key) async {
    await _mutex.acquire();
    try {
      final cacheKey = '$subcacheName/$key';
      final entry = _sets[cacheKey];
      if (entry == null || entry.isExpired) {
        _sets.remove(cacheKey);
        return const {};
      }
      return Set.of(entry.values);
    } finally {
      _mutex.release();
    }
  }

  @override
  Future<void> updateSet(
    String subcacheName,
    String key,
    Set<String> values, {
    Duration ttl = const Duration(hours: 12),
  }) async {
    if (values.isEmpty) return;
    await _mutex.acquire();
    try {
      final cacheKey = '$subcacheName/$key';
      final existing = _sets[cacheKey];
      if (existing != null && !existing.isExpired) {
        existing.values.addAll(values);
      } else {
        _sets[cacheKey] = _InMemorySetEntry(
          Set.of(values),
          DateTime.now().add(ttl),
        );
      }
    } finally {
      _mutex.release();
    }
  }

  @override
  Future<bool> addToSetIfExists(
    String subcacheName,
    String key,
    String value,
  ) async {
    await _mutex.acquire();
    try {
      final cacheKey = '$subcacheName/$key';
      final existing = _sets[cacheKey];
      if (existing != null && !existing.isExpired) {
        existing.values.add(value);
        return true;
      }
      return false;
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
      _sets.remove(cacheKey);
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
  _InMemoryCacheEntry(this.value, this.expiresAt, {this.revisionId = 0});

  final Uint8List value;
  final DateTime expiresAt;
  final int revisionId;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class _InMemorySetEntry {
  _InMemorySetEntry(this.values, this.expiresAt);

  final Set<String> values;
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
