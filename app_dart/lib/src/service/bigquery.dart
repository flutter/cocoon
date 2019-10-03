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
                ' Bearer ya29.ImaUB565j6Nta1wSsLrdvWYt-mVhm7-CCOVWakB1nViUtRqCr-zd13zzJKNykQCJ_Edz8oYt8DlnLLz4CazJ_6_QbNOQcHxm2uDC7_QM5zOsL1uabBWFapIL-eaFUgfkWKQt28vqtFk'))
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
