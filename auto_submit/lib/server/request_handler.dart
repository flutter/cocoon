// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../service/config.dart';
import '../requests/exceptions.dart';

@immutable
abstract class RequestHandler {
  const RequestHandler({
    required this.config,
  });

  final Config config;

  /// Services an HTTP request.
  ///
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future<Response> run(Request request) async {
    throw const MethodNotAllowed('GET');
  }

  /// Gets the value associated with the specified [key] in the request
  /// context.
  ///
  /// Concrete subclasses should not call this directly. Instead, they should
  /// access the getters that are tied to specific keys, such as [request]
  /// and [response].
  ///
  /// If this is called outside the context of an HTTP request, this will
  /// throw a [StateError].
  @protected
  U? getValue<U>(RequestKey<U> key, {bool allowNull = false}) {
    final U? value = Zone.current[key] as U?;
    if (!allowNull && value == null) {
      throw StateError('Attempt to access ${key.name} while not in a request context');
    }
    return value;
  }

  /// Gets the current [request].
  ///
  /// If this is called outside the context of an HTTP request, this will
  /// throw a [StateError].
  @protected
  Request? get request => getValue<Request>(RequestKey.request);

  /// Gets the current [HttpResponse].
  ///
  /// If this is called outside the context of an HTTP request, this will
  /// throw a [StateError].
  @protected
  Response? get response => getValue<Response>(RequestKey.response);

  /// Services an HTTP GET.
  ///
  /// Subclasses should override this method if they support GET requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future get() async {
    throw const MethodNotAllowed('GET');
  }

  /// Services an HTTP POST.
  ///
  /// Subclasses should override this method if they support POST requests.
  /// The default implementation will respond with HTTP 405 method not allowed.
  @protected
  Future post(Request request) async {
    throw const MethodNotAllowed('POST');
  }

  /// The package:http Client to use for googleapis requests.
  @protected
  http.Client? get httpClient => getValue<http.Client>(
        RequestKey.httpClient,
        allowNull: true,
      );
}

/// A key that can be used to index a value within the request context.
///
/// Subclasses will only need to deal directly with this class if they add
/// their own request context values.
@protected
class RequestKey<T> {
  const RequestKey(this.name);

  final String name;

  static const RequestKey<Request> request = RequestKey<Request>('request');
  static const RequestKey<Response> response = RequestKey<Response>('response');
  static const RequestKey<http.Client> httpClient = RequestKey<http.Client>('httpClient');

  @override
  String toString() => '$runtimeType($name)';
}
