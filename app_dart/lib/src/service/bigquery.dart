// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'access_client_provider.dart';

@immutable
class BigqueryService {
  const BigqueryService(this.accessClientProvider) : assert(accessClientProvider != null);

  /// The Cocoon configuration.
  final AccessClientProvider accessClientProvider;

  /// Return a [TabledataResourceApi] with an authenticated [client]
  Future<TabledataResourceApi> defaultTabledata() async {
      final Client client = await accessClientProvider.createAccessClient(
      scopes: const <String>[
        BigqueryApi.BigqueryScope
      ],
    );
    return BigqueryApi(client).tabledata;
  }
}
