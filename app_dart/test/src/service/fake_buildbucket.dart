// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/service/buildbucket.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Fake [BuildBucketClient] for handling requests to BuildBucket.
///
/// By default, returns good responses but can be updated to throw exceptions.
// ignore: must_be_immutable
class FakeBuildBucketClient extends BuildBucketClient {
  FakeBuildBucketClient({
    this.scheduleBuildResponse,
    this.batchResponse,
    this.getBuildResponse,
  }) : super(httpClient: MockClient((_) async => http.Response('', 200)));

  Future<Build>? scheduleBuildResponse;
  Future<BatchResponse> Function()? batchResponse;
  Future<Build>? getBuildResponse;
  int scheduleBuildCalls = 0;

  @override
  Future<Build> scheduleBuild(
    ScheduleBuildRequest? request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async {
    scheduleBuildCalls++;
    return (scheduleBuildResponse != null)
        ? await scheduleBuildResponse!
        : Build(
            id: '123',
            builderId: request!.builderId,
            tags: request.tags,
          );
  }

  @override
  Future<BatchResponse> batch(
    BatchRequest request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async {
    if (batchResponse != null) {
      return batchResponse!();
    }
    final List<Response> responses = <Response>[];
    for (Request request in request.requests!) {
      if (request.getBuild != null) {
        responses.add(Response(getBuild: await getBuild(request.getBuild)));
      } else if (request.scheduleBuild != null) {
        responses.add(Response(scheduleBuild: await scheduleBuild(request.scheduleBuild)));
      }
    }
    return BatchResponse(responses: responses);
  }

  @override
  Future<Build> getBuild(
    GetBuildRequest? request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async =>
      (getBuildResponse != null)
          ? await getBuildResponse!
          : Build(
              id: request!.id!,
              builderId: request.builderId!,
              number: request.buildNumber,
            );
}
