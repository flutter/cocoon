// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../requests/exceptions.dart';
import '../service/config.dart';

/// Class capable of authenticating [HttpRequest]s.
///
///  If the request has the `'X-Appengine-Cron'` HTTP header set to "true",
///  then the request will be authenticated as an App Engine cron job.
///
///  The `'X-Appengine-Cron'` HTTP header is set automatically by App Engine
///  and will be automatically stripped from the request by the App Engine
///  runtime if the request originated from anything other than a cron job.
///  Thus, the header is safe to trust as an authentication indicator.
///
///
/// If none of the above authentication methods yield an authenticated
/// request, then the request is unauthenticated, and any call to
/// [authenticate] will throw an [Unauthenticated] exception.
///
/// See also:
///
///  * <https://cloud.google.com/appengine/docs/standard/python/reference/request-response-headers>
@immutable
class CronAuthProvider {
  const CronAuthProvider(this.config);

  /// The Cocoon config, guaranteed to be non-null.
  final Config config;

  /// Authenticates the specified [request].
  ///
  /// See the class documentation on [CronAuthProviderer] for a discussion
  /// of the different types of authentication that are accepted.
  ///
  /// This will throw an [Unauthenticated] exception if the request is
  /// unauthenticated.
  Future<bool> authenticate(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    final bool isCron = reqHeader['X-Appengine-Cron'] == 'true';

    if (isCron) {
      // Authenticate cron requests
      return true;
    }

    throw const Unauthenticated('User is not signed in');
  }
}
