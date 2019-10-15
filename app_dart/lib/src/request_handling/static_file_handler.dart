// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';

import 'body.dart';
import 'exceptions.dart';

/// A class based on [RequestHandler] for serving static files.
@immutable
class StaticFileHandler<T extends Body> extends RequestHandler<Body> {
  /// Creates a new [StaticFileHandler].
  const StaticFileHandler(this.filePath);

  /// The location of the static file to serve to the client.
  final String filePath;

  /// Services an HTTP GET Request for static files.
  @override
  Future<Body> get() async {
    final HttpResponse response = request.response;

    final String resultPath = filePath == '/' ? '/index.html' : filePath;

    /// The file path in app_dart to the files to serve
    const String basePath = 'build/web';
    final File file = File('$basePath$resultPath');

    if (file.existsSync()) {
      try {
        final String mimeType = lookupMimeType(resultPath);
        response.headers.contentType = ContentType.parse(mimeType);
        return Body.forStream(Stream<Uint8List>.fromFuture(file.readAsBytes()));
      } catch (error, stackTrace) {
        throw InternalServerError('$error\n$stackTrace');
      }
    } else {
      throw NotFoundException(resultPath);
    }
  }
}
