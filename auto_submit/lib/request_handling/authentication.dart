// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../requests/exceptions.dart';

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
/// See also:
///
///  * <https://cloud.google.com/appengine/docs/standard/python/reference/request-response-headers>
@immutable
// TODO(Kristin): Generalize this to implement from a AuthProvider. https://github.com/flutter/flutter/issues/101614
class CronAuthProvider {
  const CronAuthProvider();

  /// Authenticates the specified [request].
  ///
  /// This will throw an [Unauthenticated] exception if the request is
  /// unauthenticated.
  Future<bool> authenticate(Request request) async {
    final reqHeader = request.headers;
    final isCron = reqHeader['X-Appengine-Cron'] == 'true';
    if (isCron) {
      // Authenticate cron requests
      return true;
    }
    throw const Unauthenticated('User is not signed in');
  }
}
