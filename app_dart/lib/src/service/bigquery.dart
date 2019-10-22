// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

typedef BigqueryServiceProvider = BigqueryService Function();

/// Service class for interacting with App Engine cloud datastore.
///
/// This service exists to provide an API for common datastore queries made by
/// the Cocoon backend.
@immutable
class BigqueryService {
  /// Creates a new [BigqueryService].
  ///
  /// The [bq] argument must not be null.
  const BigqueryService({
    @required this.tabledataResource,
  }) : assert(tabledataResource != null);

  final TabledataResourceApi tabledataResource;

  static BigqueryService defaultProvider() {
    return BigqueryService(
        tabledataResource: BigqueryApi(AuthenticatedClient(
                ' Bearer ya29.c.Kl6iB-OhXbeyIA9W0EbD01nWuFR5riBwEj4hu0BlDevnIzPgLELjyADBqEu51XlXkmJ7SpJZShDiemikoS9-xLoC-ePw9mkVN4NYdwQKzP5Drquv5jzpVZG5dOCGLmsv'))
            .tabledata);
  }
}

class AuthenticatedClient extends BaseClient {
  AuthenticatedClient(this._authToken);

  final String _authToken;
  final Client _delegate = Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers['Authorization'] = _authToken;
    final StreamedResponse resp = await _delegate.send(request);

    if (resp.statusCode != 200) {
      throw ClientException(
          'AuthenticatedClientError:\n'
          '  URI: ${request.url}\n'
          '  HTTP Status: ${resp.statusCode}\n'
          '  Response body:\n'
          '${(await Response.fromStream(resp)).body}',
          request.url);
    }
    return resp;
  }
}
