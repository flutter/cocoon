// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../request_handling/api_request_handler.dart';
import '../service/logging.dart';

/// An endpoint for saving dart-internal build results to the datastore.
@immutable
class DartInternalTaskResult extends ApiRequestHandler<Body> {
  /// Creates an endpoint for storing dart-internal build results.
  const DartInternalTaskResult({
    required super.config,
    required super.authenticationProvider,
    @visibleForTesting super.requestBodyValue,
  });

  @override
  Future<Body> post() async {
    final String requestDataString = String.fromCharCodes(requestBody!);

    log.fine('POST Body: $requestDataString');

    return Body.empty;
  }
}
