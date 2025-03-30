// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final root = _findRepositoryRoot();
  if (root == null) {
    io.stderr.writeln('Could not find repository root to flutter/cocoon');
    io.exitCode = 1;
    return;
  }

  if (args.length != 1) {
    io.stderr.writeln(
      'Usage: dart run tool/update_goldens_from_luci.dart <path-to-raw-luci-log>',
    );
    io.exitCode = 1;
    return;
  }

  final url = Uri.tryParse(args.first);
  if (url == null || url.host != 'logs.chromium.org') {
    io.stderr.writeln('Argument must be a valid HTTP URL to logs.chromium.org');
    io.exitCode = 1;
    return;
  }

  final client = io.HttpClient();
  try {
    final response = await (await client.getUrl(url)).close();
    if (response.statusCode != 200) {
      io.stderr.writeln(
        'Failed to download: ${response.statusCode} ${response.reasonPhrase}',
      );
      io.exitCode = 1;
      return;
    }

    io.stderr.writeln('Running in ${p.join(root, 'dashboard', 'test')}');
    final lines = (await utf8.decodeStream(response)).split('\n');
    final match = RegExp(r'^Shell:\s(.*)\shas failed.*#\[IMAGE\]:$');
    for (var i = 0; i < lines.length; i++) {
      if (match.matchAsPrefix(lines[i]) case final match?) {
        final absoluteLuciUrl = match.group(1)!;
        final image = absoluteLuciUrl.split('dashboard/test/').last;
        final bytes = base64Decode(lines[i + 1].substring('Shell: '.length));
        await io.File(
          p.join(root, 'dashboard', 'test', image),
        ).writeAsBytes(bytes);
        io.stderr.writeln('Wrote ${bytes.length} bytes to $image.');
        i += 2;
      }
    }
  } finally {
    client.close(force: true);
  }
}

String? _findRepositoryRoot() {
  var current = io.Directory.current;
  while (true) {
    final pubspec = io.File(p.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final contents = pubspec.readAsStringSync();
      if (contents.contains('name: _cocoon_workspace')) {
        return current.path;
      }
    }
    if (p.equals(current.path, current.parent.path)) {
      return null;
    }
    current = current.parent;
  }
}
