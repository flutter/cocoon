// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:dbcrypt/dbcrypt.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/agent.dart';
import '../model/whitelisted_account.dart';

import 'api_response.dart';
import 'exceptions.dart';
import 'request_context.dart';
import 'request_handler.dart';

/// A [RequestHandler] that handles API requests.
///
/// API requests adhere to a specific contract, as follows:
///
///  * They support  HTTP POST only.
///  * If any request body is specified, it must be specified as a JSON-encoded
///    map.
///  * All requests must be authenticated, either as:
///    * An agent
///    * An  AppEngine cronjob
///    * A user with a "@google.com" email address or a whitelisted email
///      address (see [WhitelistedAccount]).
///
/// `T` is the type of response that is returned in [handleApiRequest].
@immutable
abstract class ApiRequestHandler<T extends ApiResponse> extends RequestHandler {
  /// Creates a new [ApiRequestHandler].
  const ApiRequestHandler({
    @required Config config,
  }) : super(config: config);

  /// Handles an API request, and returns the corresponding API response.
  ///
  /// The [request] argument is the JSON deserialized body of the HTTP request,
  /// if such a body was specified.
  ///
  /// The [context] argument contains information such as the authentication
  /// credentials of the request. All API requests are authenticated, but some
  /// contain extra authentication information, such as which [Agent] is making
  /// the request.
  @protected
  Future<T> handleApiRequest(RequestContext context, Map<String, dynamic> request);

  /// Services an API request.
  ///
  /// This first authenticates the request and JSON deserializes the request
  /// body (as a [Map<String, dynamic>]), then it calls the [handleApiRequest]
  /// handler, which subclasses are responsible for implementing.
  @override
  Future<void> post(HttpRequest request, HttpResponse response) async {
    RequestContext context = await _getRequestContext(request);
    Map body = await utf8.decoder.bind(request).transform(json.decoder).cast<Map>().first;

    T apiResponse = await handleApiRequest(context, body.cast<String, dynamic>());
    response
      ..statusCode = HttpStatus.ok
      ..write(json.encode(apiResponse));
    await response.flush();
    await response.close();
  }

  Future<RequestContext> _getRequestContext(HttpRequest request) async {
    String agentAuthToken = request.headers.value('Agent-Auth-Token');
    bool isCron = request.headers.value('X-Appengine-Cron') == 'true';
    if (agentAuthToken != null) {
      // Authenticate as an agent. Note that it could simultaneously be cron
      // and agent, or Google account and agent.
      String agentId = request.headers.value('Agent-ID');
      if (agentId == null) {
        throw Unauthorized('Missing required HTTP header: Agent-ID');
      }

      Key agentKey = config.db.emptyKey.append(Agent, id: agentId);
      List<Agent> results = await config.db.lookup<Agent>(<Key>[agentKey]);
      Agent agent = results.single;
      if (!_compareHashAndPassword(agent.authToken, agentAuthToken)) {
        throw Unauthorized('Invalid agent: $agentId');
      }

      return RequestContext(agent: agent);
    } else if (isCron) {
      // Authenticate cron requests that are not agents.
      return RequestContext();
    } else {
      // Authenticate as a signed-in Google account.
      String email = request.headers.value('X-AppEngine-User-Email');

      if (email == null) {
        throw Unauthorized('User  is not signed in');
      }

      if (!email.endsWith('@google.com')) {
        Query<WhitelistedAccount> query = config.db.query<WhitelistedAccount>()
          ..filter('Email =', email)
          ..limit(20);

        if (await query.run().isEmpty) {
          throw Unauthorized('$email is not authorized to access the dashboard');
        }
      }

      return RequestContext();
    }
  }

  // This method is expensive (run time of ~1,500ms!). If the server starts
  // handling any meaningful API traffic, we should move request processing
  // to dedicated isolates in a pool.
  static bool _compareHashAndPassword(List<int> serverAuthTokenHash, String clientAuthToken) {
    String serverAuthTokenHashAscii = ascii.decode(serverAuthTokenHash);
    DBCrypt crypt = DBCrypt();
    return crypt.checkpw(clientAuthToken, serverAuthTokenHashAscii);
  }
}
