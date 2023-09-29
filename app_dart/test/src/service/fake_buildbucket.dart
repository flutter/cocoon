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
    this.searchBuildsResponse,
    this.batchResponse,
    this.cancelBuildResponse,
    this.getBuildResponse,
    this.listBuildersResponse,
  }) : super(httpClient: MockClient((_) async => http.Response('', 200)));

  Future<Build>? scheduleBuildResponse;
  Future<SearchBuildsResponse>? searchBuildsResponse;
  Future<BatchResponse> Function()? batchResponse;
  Future<Build>? cancelBuildResponse;
  Future<Build>? getBuildResponse;
  Future<ListBuildersResponse>? listBuildersResponse;

  @override
  Future<Build> scheduleBuild(
    ScheduleBuildRequest? request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async =>
      (scheduleBuildResponse != null)
          ? await scheduleBuildResponse!
          : Build(
              id: '123',
              builderId: request!.builderId,
              tags: request.tags,
            );

  @override
  Future<SearchBuildsResponse> searchBuilds(
    SearchBuildsRequest? request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async =>
      (searchBuildsResponse != null)
          ? await searchBuildsResponse!
          : const SearchBuildsResponse(
              builds: <Build>[
                Build(
                  id: '123',
                  builderId: BuilderId(
                    builder: 'builder_abc',
                    bucket: 'try',
                    project: 'flutter',
                  ),
                  tags: <String, List<String>>{
                    'buildset': <String>['pr/git/12345', 'sha/git/259bcf77bd04e64ef2181caccc43eda57780cd21'],
                    'cipd_version': <String>['refs/heads/main'],
                    'github_link': <String>['https://github/flutter/flutter/pull/1'],
                  },
                  input: Input(
                    properties: <String, Object>{'bringup': 'true'},
                  ),
                ),
              ],
            );

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
      if (request.cancelBuild != null) {
        responses.add(Response(cancelBuild: await cancelBuild(request.cancelBuild)));
      } else if (request.getBuild != null) {
        responses.add(Response(getBuild: await getBuild(request.getBuild)));
      } else if (request.scheduleBuild != null) {
        responses.add(Response(scheduleBuild: await scheduleBuild(request.scheduleBuild)));
      } else if (request.searchBuilds != null) {
        responses.add(Response(searchBuilds: await searchBuilds(request.searchBuilds)));
      }
    }
    return BatchResponse(responses: responses);
  }

  @override
  Future<Build> cancelBuild(
    CancelBuildRequest? request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async =>
      (cancelBuildResponse != null)
          ? await cancelBuildResponse!
          : Build(
              id: request!.id,
              builderId: const BuilderId(
                bucket: 'try',
                project: 'flutter',
                builder: 'builder_abc',
              ),
              summaryMarkdown: request.summaryMarkdown,
            );

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

  @override
  Future<ListBuildersResponse> listBuilders(
    ListBuildersRequest? request, {
    String buildBucketUri = 'https://localhost/builders',
  }) async =>
      (listBuildersResponse != null)
          ? await listBuildersResponse!
          : const ListBuildersResponse(
              builders: <BuilderItem>[
                BuilderItem(
                  id: BuilderId(
                    bucket: 'prod',
                    project: 'flutter',
                    builder: 'Linux_android A',
                  ),
                ),
                BuilderItem(
                  id: BuilderId(
                    bucket: 'prod',
                    project: 'flutter',
                    builder: 'Linux_android B',
                  ),
                ),
              ],
            );
}
