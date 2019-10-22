// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/bigquery.dart';

@immutable
class UpdateAgentHealthHistory
    extends ApiRequestHandler<UpdateAgentHealthHistoryResponse> {
  const UpdateAgentHealthHistory(
      Config config, AuthenticationProvider authenticationProvider,
      {@visibleForTesting this.bigqueryApi = BigqueryService.defaultProvider})
      : super(config: config, authenticationProvider: authenticationProvider);

  final BigqueryServiceProvider bigqueryApi;

  static const String agentIdParam = 'AgentID';
  static const String statusParam = 'Status';
  static const String healthDetailsParam = 'HealthDetails';

  @override
  Future<UpdateAgentHealthHistoryResponse> post() async {
    checkRequiredParameters(
        <String>[agentIdParam, statusParam, healthDetailsParam]);

    final String agentId = requestData[agentIdParam];
    final String status = requestData[statusParam];
    final String healthDetails = requestData[healthDetailsParam];
    final BigqueryService bigquery = bigqueryApi();

    final TableDataInsertAllRequest rows =
        TableDataInsertAllRequest.fromJson(<String, Object>{
      'rows': <Map<String, Object>>[
        <String, Object>{
          'json': <String, Object>{
            'Timestamp': DateTime.now().millisecondsSinceEpoch,
            'AgentID': agentId,
            'Status': status,
            'Detail': healthDetails
          },
        }
      ],
    });

    final TableDataInsertAllResponse response = await bigquery.tabledataResource
        .insertAll(rows, 'flutter-dashboard', 'cocoon', 'AgentStatus');
    //final TableDataList list = await bigquery.tabledataResource
    //    .list('flutter-dashboard', 'cocoon', 'checklist');

    return UpdateAgentHealthHistoryResponse(response);
  }
}

@immutable
class UpdateAgentHealthHistoryResponse extends JsonBody {
  const UpdateAgentHealthHistoryResponse(this.response);

  final TableDataInsertAllResponse response;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'response': response,
    };
  }
}
