// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// An exception that may be thrown by a [RequestHandler] to trigger an error
/// HTTP response.
class HttpStatusException implements Exception {
  /// Creates a new [HttpStatusException].
  const HttpStatusException(this.statusCode, this.message);

  /// The HTTP status code to return to the issuer.
  final int statusCode;

  /// The message to show to the issuer to explain the error.
  final String message;

  @override
  String toString() => 'HTTP $statusCode: $message';
}

/// Exception that will trigger an HTTP 400 bad request.
class BadRequestException extends HttpStatusException {
  const BadRequestException([String message = 'Bad request'])
    : super(HttpStatus.badRequest, message);
}

/// Exception that will trigger an HTTP 404 not found
class NotFoundException extends HttpStatusException {
  const NotFoundException(String missing)
    : super(HttpStatus.notFound, 'Not found: $missing');
}

/// Exception that will trigger an HTTP 405 method not allowed.
class MethodNotAllowed extends HttpStatusException {
  const MethodNotAllowed(String method)
    : super(HttpStatus.methodNotAllowed, 'Unsupported method: $method');
}

/// Exception that will trigger an HTTP 409 conflict.
class ConflictException extends HttpStatusException {
  const ConflictException([
    String message = 'Request conflict with server state',
  ]) : super(HttpStatus.conflict, message);
}

/// Exception that will trigger an HTTP 500 internal server error.
class InternalServerError extends HttpStatusException {
  const InternalServerError([String message = 'Internal server error'])
    : super(HttpStatus.internalServerError, message);
}

/// Exception that will trigger an HTTP 401 not authorized.
class Unauthorized extends HttpStatusException {
  const Unauthorized([String message = 'Unauthorized'])
    : super(HttpStatus.unauthorized, message);
}

/// Exception that will trigger an HTTP 403 forbidden.
class Forbidden extends HttpStatusException {
  const Forbidden([String message = 'Forbidden'])
    : super(HttpStatus.forbidden, message);
}

/// Exception thrown when attempting to authenticate a request that cannot be
/// authenticated.
class Unauthenticated implements Exception {
  const Unauthenticated(this.message);

  final String message;

  @override
  String toString() => 'Unauthenticated: $message';
}
