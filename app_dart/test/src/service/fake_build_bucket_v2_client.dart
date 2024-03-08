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
    build.id = 123 as Int64;
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
    build.id = 123 as Int64;
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

  @override
  Future<bbv2.BatchResponse> batch(
    bbv2.BatchRequest request, {
    String buildBucketUri = 'https://localhost/builds',
  }) async {
    if (batchResponse != null) {
      return batchResponse!();
    }

    // final List<bbv2.BatchRequest_Request> batchRequests = request.requests;

    // final bbv2.BatchResponse batchResponses = bbv2.BatchResponse.create();
    // final List<bbv2.BatchResponse_Response> responses = batchResponses.responses;

    // for (bbv2.BatchRequest_Request request in request.requests) {
    //   if (request.cancelBuild.isInitialized()) {
    //     final bbv2.CancelBuildRequest cancelBuildRequest = request.cancelBuild;
    //     cancelBuild
        
    //     responses.add(bbv2.BatchResponse_Response(cancelBuild: ));
    //     // responses.add();
    //   }
    // }
    
    // for (bbv2.BatchRequest_Request request in request.requests) {
    //   if (request.cancelBuild.isInitialized()) {
    //     responses.add(bbv2.BatchResponse(cancelBuild: await cancelBuild(request.cancelBuild)));
    //   } else if (request.getBuild.isInitialized()) {
    //     responses.add(bbv2.BatchResponse(getBuild: await getBuild(request.getBuild)));
    //   } else if (request.scheduleBuild.isInitialized()) {
    //     responses.add(bbv2.BatchResponse(scheduleBuild: await scheduleBuild(request.scheduleBuild)));
    //   } else if (request.searchBuilds.isInitialized()) {
    //     responses.add(bbv2.BatchResponse(searchBuilds: await searchBuilds(request.searchBuilds)));
    //   }
    // }

    // return bbv2.BatchResponse(responses: batchResponses);
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

    final bbv2.ListBuildersResponse listBuildersResponseRc = bbv2.ListBuildersResponse(
      builders: <bbv2.BuilderItem>[
        bbv2.BuilderItem
      ],
    );
  }
      // (listBuildersResponse != null)
      //     ? await listBuildersResponse!
      //     : const bbv2.ListBuildersResponse(
      //         builders: <BuilderItem>[
      //           BuilderItem(
      //             id: BuilderId(
      //               bucket: 'prod',
      //               project: 'flutter',
      //               builder: 'Linux_android A',
      //             ),
      //           ),
      //           BuilderItem(
      //             id: BuilderId(
      //               bucket: 'prod',
      //               project: 'flutter',
      //               builder: 'Linux_android B',
      //             ),
      //           ),
      //         ],
      //       );
}
