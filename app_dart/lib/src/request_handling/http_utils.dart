// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http_parser/http_parser.dart';

export 'package:http_parser/http_parser.dart' show MediaType;

/// A collection of HTTP status codes.
///
/// This is used instead of 'dart:io' to keep the library platform-neutral.
class HttpStatus {
  static const int ok = 200;
  static const int accepted = 202;
  static const int permanentRedirect = 308;
  static const int movedTemporarily = 302;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int conflict = 409;
  static const int internalServerError = 500;
  static const int serviceUnavailable = 503;
}

/// A collection of HTTP header names.
///
/// This is used instead of 'dart:io' to keep the library platform-neutral.
class HttpHeaders {
  static const String contentTypeHeader = 'content-type';
  static const String acceptHeader = 'accept';
  static const String authorizationHeader = 'authorization';
}

final MediaType kContentTypeText = MediaType('text', 'plain', {
  'charset': 'utf-8',
});
final MediaType kContentTypeHtml = MediaType('text', 'html', {
  'charset': 'utf-8',
});
final MediaType kContentTypeJson = MediaType('application', 'json', {
  'charset': 'utf-8',
});
final MediaType kContentTypeBinary = MediaType('application', 'octet-stream');
final MediaType kImageSvgXml = MediaType('image', 'svg+xml');

/// Exception thrown when an HTTP request fails.
class HttpException implements Exception {
  HttpException(this.message);
  final String message;
  @override
  String toString() => 'HttpException: $message';
}

/// Exception thrown when a socket operation fails.
class SocketException implements Exception {
  SocketException(this.message);
  final String message;
  @override
  String toString() => 'SocketException: $message';
}
