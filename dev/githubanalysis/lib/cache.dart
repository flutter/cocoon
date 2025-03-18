// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:github/github.dart';

import 'utils.dart';

// Returns the data from the network, in the form used in the cache.
//
// It's a bit inefficient to have the data be serialized to string and then
// immediately reparsed, but it avoids any issues where the cache is interpreted
// differently than the original data. Since this code is not performance sensitive,
// the sanity is more important.
typedef PopulateCacheCallback = Future<String> Function();

const String cacheSeparator = ':';

File cacheFileFor(final Directory cacheDirectory, final List<String> key) {
  for (final String k in key) {
    verifyStringSanity(k, const <String>{'\x00', '/', cacheSeparator});
  }
  final String cacheName = key.join(cacheSeparator);
  return File('${cacheDirectory.path}/$cacheName');
}

typedef Parser<T> = T? Function(String);

Future<T?> readFromFile<T>(final File file, final Parser<T> parser) async {
  try {
    return parser(await file.readAsString());
  } on FileSystemException {
    if (await file.exists()) {
      rethrow;
    }
  }
  return null;
}

Future<String> loadFromCache(
  final Directory cacheDirectory,
  final GitHub github,
  final List<String> key,
  final DateTime? cacheEpoch,
  final PopulateCacheCallback callback,
) async {
  final File cacheFile = cacheFileFor(cacheDirectory, key);
  final RandomAccessFile cacheFileContents = await cacheFile.open(mode: FileMode.append);
  bool firstWait = true;
  while (true) {
    try {
      await cacheFileContents.lock();
      break;
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 11) {
        if (firstWait) {
          print('\x1B[KWaiting for lock on ${cacheFile.path}');
          firstWait = false;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
        continue;
      }
      rethrow;
    }
  }
  try {
    await cacheFileContents.setPosition(0);
    final String cacheData = utf8.decode(await cacheFileContents.read(await cacheFileContents.length()));
    final int firstLineBreak = cacheData.indexOf('\n');
    bool needsReplacing = true;
    if (cacheEpoch != null) {
      if (firstLineBreak > 0) {
        final int? cacheTimeInMilliseconds = int.tryParse(cacheData.substring(0, firstLineBreak), radix: 10);
        if (cacheTimeInMilliseconds != null) {
          final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimeInMilliseconds);
          if (cacheTime.isAfter(cacheEpoch)) {
            needsReplacing = false;
          }
        }
      }
    }
    if (needsReplacing) {
      final String data;
      try {
        data = await callback();
      } on Exception {
        await cacheFile.delete();
        rethrow;
      }
      await cacheFileContents.truncate(0);
      await cacheFileContents.setPosition(0);
      await cacheFileContents.writeString('${DateTime.now().millisecondsSinceEpoch}\n');
      await cacheFileContents.writeString(data);
      return data;
    }
    return cacheData.substring(firstLineBreak + 1);
  } finally {
    await cacheFileContents.unlock();
    await cacheFileContents.close();
  }
}
