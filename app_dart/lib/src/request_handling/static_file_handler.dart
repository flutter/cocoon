// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ContentType, HttpResponse;
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import 'exceptions.dart';

/// A class based on [RequestHandler] for serving static files.
@immutable
class StaticFileHandler extends RequestHandler<Body> {
  /// Creates a new [StaticFileHandler].
  const StaticFileHandler(this.filePath, {@required Config config, this.fs = const LocalFileSystem()})
      : super(config: config);

  /// The current [FileSystem] to retrieve files from.
  final FileSystem fs;

  /// The location of the static file to serve to the client.
  final String filePath;

  /// Services an HTTP GET Request for static files.
  @override
  Future<Body> get() async {
    final HttpResponse response = request.response;

    /// The map of mimeTypes not found in [mime] package.
    final Map<String, String> mimeTypeMap = <String, String>{
      '.map': 'application/json',
      '': 'text/plain',
    };

    final String resultPath = filePath == '/' ? '/index.html' : filePath;

    /// The file path in app_dart to the files to serve
    const String basePath = 'build/web';
    final File file = fs.file('$basePath$resultPath');
    if (file.existsSync()) {
      final String mimeType = mimeTypeMap.containsKey(path.extension(file.path))
          ? mimeTypeMap[path.extension(file.path)]
          : lookupMimeType(resultPath);
      response.headers.contentType = ContentType.parse(mimeType);
      return Body.forStream(file.openRead().cast<Uint8List>());
    } else {
      throw NotFoundException(resultPath);
    }
  }
}
