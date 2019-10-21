// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';

import 'body.dart';
import 'exceptions.dart';

/// A class based on [RequestHandler] for serving static files.
@immutable
class CacheResponseHandler extends RequestHandler<Body> {
  /// Creates a new [CacheResponseHandler].
  const CacheResponseHandler(this.filePath,
      {@required Config config})
      : super(config: config);

  /// The location of the static file to serve to the client.
  final String filePath;

  /// Services an HTTP GET Request for static files.
  @override
  Future<Body> get() async {
    final HttpResponse response = request.response;

    final String resultPath = filePath == '/' ? '/index.html' : filePath;

    /// The file path in app_dart to the files to serve
    const String basePath = 'build/web';

    final File file = fs.file('$basePath$resultPath');

    if (file.existsSync()) {
      final String mimeType = lookupMimeType(resultPath);
      return Body.forStream(file.openRead().cast<Uint8List>());
    } else {
      throw NotFoundException(resultPath);
    }
  }
}
