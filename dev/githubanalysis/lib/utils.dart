// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:github/github.dart';

const Duration clockSkew = Duration(seconds: 5);
int minApiPoints = 250; // number of points to leave for debugging, etc

class Abort implements Exception {}

enum Mode { full, abbreviated, aborted }

Mode mode = Mode.full;
final Completer<void> aborter = Completer<void>();

Future<void> rateLimit(
    final GitHub github, final String status, final String next) async {
  if (mode == Mode.aborted) {
    throw Abort();
  }
  stdout.write(
    '$status${github.rateLimitRemaining != null ? ". Rate limits: ${github.rateLimitRemaining}/${github.rateLimitLimit} per hour" : ""}.\x1B[K\r',
  );
  if (github.rateLimitRemaining != null &&
      github.rateLimitRemaining! < minApiPoints) {
    Duration delay = github.rateLimitReset!.difference(DateTime.now());
    if (delay > Duration.zero) {
      delay += clockSkew;
      print(
          '\nWaiting until ${DateTime.now().add(delay).toLocal()} to continue with $next...');
      await Future.any<void>(<Future<void>>[
        Future<void>.delayed(delay),
        aborter.future,
      ]);
      minApiPoints = 50;
    }
  }
}

void verifyStringSanity(
    final String value, final Set<String> disallowedSubstrings) {
  for (final String substring in disallowedSubstrings) {
    if (value.contains(substring)) {
      throw FormatException('Found "$disallowedSubstrings" in "$value".');
    }
  }
}

DateTime maxAge(final Duration maxAge) => DateTime.now().subtract(maxAge);
