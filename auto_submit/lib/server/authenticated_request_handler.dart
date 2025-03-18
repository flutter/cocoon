// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../request_handling/authentication.dart';
import '../requests/exceptions.dart';
import 'request_handler.dart';

/// A [RequestHandler] that handles API requests.
///
///  * All requests must be authenticated per [CronAuthProvider].
@immutable
abstract class AuthenticatedRequestHandler extends RequestHandler {
  /// Creates a new [ApiRequestHandler].
  const AuthenticatedRequestHandler({
    required super.config,
    required this.cronAuthProvider,
  });

  /// Service responsible for authenticating this [Request].
  final CronAuthProvider cronAuthProvider;

  @override
  Future<Response> run(Request request) async {
    try {
      await cronAuthProvider.authenticate(request);
    } on Unauthenticated catch (error) {
      log2.info('Authenticate error: $error');
      return Response.forbidden(error.toString());
    }
    return super.run(request);
  }
}
