// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/service/buildbucket.dart';

import '../request_handling/fake_http.dart';

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
  }) : super(httpClient: FakeHttpClient());

  Future<Build> scheduleBuildResponse;
  Future<SearchBuildsResponse> searchBuildsResponse;
  Future<BatchResponse> batchResponse;
  Future<Build> cancelBuildResponse;
  Future<Build> getBuildResponse;

  @override
  Future<Build> scheduleBuild(ScheduleBuildRequest request) async => (scheduleBuildResponse != null)
      ? await scheduleBuildResponse
      : Build(
          id: 123,
          builderId: request.builderId,
          tags: request.tags,
        );

  @override
  Future<SearchBuildsResponse> searchBuilds(SearchBuildsRequest request) async => (searchBuildsResponse != null)
      ? await searchBuildsResponse
      : const SearchBuildsResponse(
          builds: <Build>[
            Build(
                id: 123,
                builderId: BuilderId(
                  builder: 'builder_abc',
                  bucket: 'try',
                  project: 'flutter',
                ),
                tags: <String, List<String>>{
                  'buildset': <String>['pr/git/12345', 'sha/git/259bcf77bd04e64ef2181caccc43eda57780cd21'],
                }),
          ],
        );

  @override
  Future<BatchResponse> batch(BatchRequest request) async {
    final List<Response> responses = <Response>[];
    for (Request request in request.requests) {
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
  Future<Build> cancelBuild(CancelBuildRequest request) async => (cancelBuildResponse != null)
      ? await cancelBuildResponse
      : Build(
          id: request.id,
          builderId: const BuilderId(
            bucket: 'try',
            project: 'flutter',
            builder: 'builder_abc',
          ),
          summaryMarkdown: request.summaryMarkdown);

  @override
  Future<Build> getBuild(GetBuildRequest request) async => (getBuildResponse != null)
      ? await getBuildResponse
      : Build(
          id: request.id,
          builderId: request.builderId,
          number: request.buildNumber,
        );
}
