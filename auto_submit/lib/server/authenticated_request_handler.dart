// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../request_handling/authentication.dart';
import 'request_handler.dart';
import '../service/config.dart';

/// A [RequestHandler] that handles API requests.
///
/// API requests adhere to a specific contract, as follows:
///
///  * All requests must be authenticated per [AuthenticationProvider].
///
/// `T` is the type of object that is returned as the body of the HTTP response
/// (before serialization). Subclasses whose HTTP responses don't include a
/// body should extend `RequestHandler<Body>` and return null in their service
/// handlers ([get] and [post]).
@immutable
abstract class AuthenticatedRequestHandler extends RequestHandler {
  /// Creates a new [ApiRequestHandler].
  const AuthenticatedRequestHandler({
    required Config config,
    required this.authenticationProvider,
  }) : super(config: config);

  /// Service responsible for authenticating this [Request].
  final AuthenticationProvider authenticationProvider;
}
