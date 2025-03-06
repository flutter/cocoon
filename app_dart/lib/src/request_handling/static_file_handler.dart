// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ContentType;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../../cocoon_service.dart';
import 'exceptions.dart';

/// A class based on [RequestHandler] for serving static files.
@immutable
class StaticFileHandler extends RequestHandler<Body> {
  /// Creates a new [StaticFileHandler].
  const StaticFileHandler(
    this.filePath, {
    required super.config,
    this.fs = const LocalFileSystem(),
  });

  /// The current [FileSystem] to retrieve files from.
  final FileSystem fs;

  /// The location of the static file to serve to the client.
  final String filePath;

  /// Services an HTTP GET Request for static files.
  @override
  Future<Body> get() async {
    final response = request!.response;

    /// The map of mimeTypes not found in [mime] package.
    final mimeTypeMap = <String, String>{
      '.map': 'application/json',
      '': 'text/plain',
      '.smcbin': 'application/octet-stream',
    };

    final resultPath = filePath == '/' ? '/index.html' : filePath;

    /// The file path in app_dart to the files to serve
    const basePath = 'build/web';
    final file = fs.file('$basePath$resultPath');
    if (file.existsSync()) {
      final mimeType =
          mimeTypeMap.containsKey(path.extension(file.path))
              ? mimeTypeMap[path.extension(file.path)]!
              : lookupMimeType(resultPath)!;
      response.headers.contentType = ContentType.parse(mimeType);
      return Body.forStream(file.openRead().cast<Uint8List>());
    } else {
      throw NotFoundException(resultPath);
    }
  }
}
