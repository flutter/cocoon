// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/service/build_bucket_v2_client.dart';
import 'package:fixnum/src/int64.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Fake [BuildBucketV2Client] for handling requests to BuildBucket.
///
/// By default, returns good responses but can be updated to throw exceptions.
// ignore: must_be_immutable
class FakeBuildBucketV2Client extends BuildBucketV2Client {
  FakeBuildBucketV2Client({
    this.scheduleBuildResponse,
    this.searchBuildsResponse,
    this.batchResponse,
    this.cancelBuildResponse,
    this.getBuildResponse,
    this.listBuildersResponse,
  }) : super(httpClient: MockClient((_) async => http.Response('', 200)));

  Future<bbv2.Build>? scheduleBuildResponse;
  Future<bbv2.SearchBuildsResponse>? searchBuildsResponse;
  Future<bbv2.BatchResponse> Function()? batchResponse;
  Future<bbv2.Build>? cancelBuildResponse;
  Future<bbv2.Build>? getBuildResponse;
  Future<bbv2.ListBuildersResponse>? listBuildersResponse;

  bbv2.StringPair _createStringPair(String key, String value) {
    final bbv2.StringPair stringPair = bbv2.StringPair.create();
    stringPair.key = key;
    stringPair.value = value;
    return stringPair;
  }

  @override
  Future<bbv2.Build> scheduleBuild(
    bbv2.ScheduleBuildRequest? request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async {
    if (scheduleBuildResponse != null) {
      return scheduleBuildResponse!;
    }

    final bbv2.Build build = bbv2.Build.create();
    build.id = Int64(123);
    build.builder = request!.builder;
    // The tags here should be empty.
    final List<bbv2.StringPair> existingTags = build.tags;
    existingTags.addAll(request.tags);
    return build;
  }

  @override
  Future<bbv2.SearchBuildsResponse> searchBuilds(
    bbv2.SearchBuildsRequest? request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async {
    if (searchBuildsResponse != null) {
      return searchBuildsResponse!;
    }

    final bbv2.Build build = bbv2.Build.create();
    build.id = Int64(123);
    final bbv2.BuilderID builderID = bbv2.BuilderID.create();
    builderID.builder = 'builder_abc';
    builderID.bucket = 'try';
    builderID.project = 'flutter';
    build.builder = builderID;

    final List<bbv2.StringPair> tags = [];
    tags.add(_createStringPair('buildset', 'pr/git/12345'));
    tags.add(_createStringPair('buildset', 'sha/git/259bcf77bd04e64ef2181caccc43eda57780cd21'));
    tags.add(_createStringPair('cipd_version', 'refs/heads/main'));
    tags.add(_createStringPair('github_link', 'https://github/flutter/flutter/pull/1'));

    final bbv2.Build_Input buildInput = bbv2.Build_Input.create();

    final Map<String, bbv2.Value> propertiesMap = buildInput.properties.fields;
    propertiesMap.addEntries(
      <String, bbv2.Value>{
        'bringup': bbv2.Value(boolValue: true),
      }.entries,
    );

    final bbv2.SearchBuildsResponse searchBuildsResponseRc = bbv2.SearchBuildsResponse.create();
    final List<bbv2.Build> buildsList = searchBuildsResponseRc.builds;
    buildsList.add(build);
    return searchBuildsResponseRc;
  }

  late List<bbv2.Build> searchBuildsResponseBuildList;

  set setSearchBuildsResponseBuildList(List<bbv2.Build> builds) => searchBuildsResponseBuildList = builds;

  @override
  Future<bbv2.BatchResponse> batch(
    bbv2.BatchRequest request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async {
    if (batchResponse != null) {
      return batchResponse!();
    }

    final bbv2.BatchResponse batchResponseRc = bbv2.BatchResponse.create();
    // a batch response has a response and the naming convention is terrible.
    final List<bbv2.BatchResponse_Response> batchResponseResponses = batchResponseRc.responses;

    for (bbv2.BatchRequest_Request request in request.requests) {
      if (request.hasCancelBuild()) {
        final bbv2.CancelBuildRequest cancelBuildRequest = request.cancelBuild;
        batchResponseResponses.add(
          bbv2.BatchResponse_Response(
            cancelBuild: bbv2.Build(
              id: cancelBuildRequest.id,
            ),
          ),
        );
      } else if (request.hasGetBuild()) {
        final bbv2.GetBuildRequest getBuildRequest = request.getBuild;
        batchResponseResponses.add(
          bbv2.BatchResponse_Response(
            getBuild: bbv2.Build(
              id: getBuildRequest.id,
              builder: getBuildRequest.builder,
              number: getBuildRequest.buildNumber,
            ),
          ),
        );
      } else if (request.hasScheduleBuild()) {
        final bbv2.ScheduleBuildRequest scheduleBuildRequest = request.scheduleBuild;
        batchResponseResponses.add(
          bbv2.BatchResponse_Response(
            scheduleBuild: bbv2.Build(
              builder: scheduleBuildRequest.builder,
            ),
          ),
        );
      } else if (request.hasSearchBuilds()) {
        // Note that you cannot get builds from the searchBuildResponse.
        batchResponseResponses.add(
          bbv2.BatchResponse_Response(
            searchBuilds: bbv2.SearchBuildsResponse(builds: searchBuildsResponseBuildList),
          ),
        );
      }
    }

    return batchResponseRc;
  }

  @override
  Future<bbv2.Build> cancelBuild(
    bbv2.CancelBuildRequest? request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async {
    if (cancelBuildResponse != null) {
      return cancelBuildResponse!;
    }

    final bbv2.Build build = bbv2.Build.create();
    build.id = request!.id;
    final bbv2.BuilderID builderID = bbv2.BuilderID(
      bucket: 'try',
      project: 'flutter',
      builder: 'builder_abc',
    );
    build.builder = builderID;
    build.summaryMarkdown = request.summaryMarkdown;

    return build;
  }

  @override
  Future<bbv2.Build> getBuild(
    bbv2.GetBuildRequest? request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async {
    if (getBuildResponse != null) {
      return getBuildResponse!;
    }

    final bbv2.Build build = bbv2.Build.create();
    build.id = request!.id;
    build.builder = request.builder;
    build.number = request.buildNumber;
    return build;
  }

  @override
  Future<bbv2.ListBuildersResponse> listBuilders(
    bbv2.ListBuildersRequest? request, {
    String buildBucketUri = 'https://localhost/builders',
  }) async {
    if (listBuildersResponse != null) {
      return listBuildersResponse!;
    }

    return bbv2.ListBuildersResponse(
      builders: <bbv2.BuilderItem>[
        bbv2.BuilderItem(
          id: bbv2.BuilderID(
            bucket: 'prod',
            project: 'flutter',
            builder: 'Linux_android A',
          ),
        ),
        bbv2.BuilderItem(
          id: bbv2.BuilderID(
            bucket: 'prod',
            project: 'flutter',
            builder: 'Linux_android B',
          ),
        ),
      ],
    );
  }
}
