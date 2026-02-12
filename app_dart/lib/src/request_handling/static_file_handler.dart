// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../../cocoon_service.dart';
import 'exceptions.dart';

/// A class based on [RequestHandler] for serving static files.
final class StaticFileHandler extends RequestHandler {
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
  Future<Response> get(Request request) async {
    /// The map of mimeTypes not found in [mime] package.
    const mimeTypeMap = {
      '.map': 'application/json',
      '': 'text/plain',
      '.smcbin': 'application/octet-stream',
    };

    const mimeFileMap = {'apple-app-site-association': 'application/json'};

    final resultPath = filePath == '/' ? '/index.html' : filePath;

    /// The file path in app_dart to the files to serve
    const basePath = 'build/web';
    final file = fs.file('$basePath$resultPath');
    if (file.existsSync()) {
      final mimeType =
          mimeFileMap[path.basename(file.path)] ??
          mimeTypeMap[path.extension(file.path)] ??
          lookupMimeType(resultPath) ??
          'application/octet-stream';
      return Response.stream(
        file.openRead().cast<Uint8List>(),
        contentType: MediaType.parse(mimeType),
      );
    } else {
      throw NotFoundException(resultPath);
    }
  }
}
