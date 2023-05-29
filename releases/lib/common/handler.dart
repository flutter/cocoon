// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import 'context.dart';

export 'package:shelf/shelf.dart' hide Handler;
export 'context.dart';

@immutable
abstract class Handler {
  const Handler(this.route);

  final String route;

  /// Services a GET request.
  ///
  /// Subclasses should override this method if they support GET requests.
  ///
  /// An unimplemented response will be returned if there is no concrete implementation.
  Future<Response> get(Context context, Request request) async {
    return Response(501, body: 'GET ${request.url.path} not implemented');
  }

  /// Services a POST request.
  ///
  /// Subclasses should override this method if they support POST requests.
  ///
  /// An unimplemented response will be returned if there is no concrete implementation.
  Future<Response> post(Context context, Request request) async {
    return Response(501, body: 'POST ${request.url.path} not implemented');
  }
}
