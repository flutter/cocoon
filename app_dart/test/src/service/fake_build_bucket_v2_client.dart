// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/service/build_bucket_v2_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Fake [BuildBucketClient] for handling requests to BuildBucket.
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

  // @override
  // Future<bbv2.Build> scheduleBuild(
  //   bbv2.ScheduleBuildRequest? request, {
  //   String buildBucketUri = 'https://localhost/builds',
  // }) async {
  //   if (scheduleBuildResponse != null) {
  //     return scheduleBuildResponse!;
  //   }

  //   final String fakeBuildString = '''
  //   {
  //     "build":{
  //       "id":123,
  //       "builder":{
  //         "project":"${request!.builder.project}",
  //         "bucket":"${request.builder.bucket}",
  //         "builder":"${request.builder.builder}"
  //       },
  //       "number":123456,
  //       "status":"SUCCESS",
  //       "input":{
  //         "gitilesCommit":{
  //           "project":"flutter/flutter",
  //           "id":"HASH12345",
  //           "ref":"refs/heads/test-branch"
  //         }
  //       },
  //       "tags": ${request.tags}
  //     }
  //   }''';

    

  //   // bbv2.Build build = bbv2.Build.create();
  //   // build.id = Int64(123);
  //   // build.builder = request!.builder;
  //   // build. = request.tags;

  //   //   (scheduleBuildResponse != null)
  //   //       ? await scheduleBuildResponse!
  //   //       : bbv2.Build(
  //   //           id: '123',
  //   //           builderId: request!.builderId,
  //   //           tags: request.tags,
  //   //         );
  // }

  // @override
  // Future<bbv2.SearchBuildsResponse> searchBuilds(
  //   bbv2.SearchBuildsRequest? request, {
  //   String buildBucketUri = 'https://localhost/builds',
  // }) async =>
  //     (searchBuildsResponse != null)
  //         ? await searchBuildsResponse!
  //         : const bbv2.SearchBuildsResponse(
  //             builds: <bbv2.Build>[
  //               Build(
  //                 id: '123',
  //                 builderId: BuilderId(
  //                   builder: 'builder_abc',
  //                   bucket: 'try',
  //                   project: 'flutter',
  //                 ),
  //                 tags: <String, List<String>>{
  //                   'buildset': <String>['pr/git/12345', 'sha/git/259bcf77bd04e64ef2181caccc43eda57780cd21'],
  //                   'cipd_version': <String>['refs/heads/main'],
  //                   'github_link': <String>['https://github/flutter/flutter/pull/1'],
  //                 },
  //                 input: Input(
  //                   properties: <String, Object>{'bringup': 'true'},
  //                 ),
  //               ),
  //             ],
  //           );

  // @override
  // Future<bbv2.BatchResponse> batch(
  //   bbv2.BatchRequest request, {
  //   String buildBucketUri = 'https://localhost/builds',
  // }) async {
  //   if (batchResponse != null) {
  //     return batchResponse!();
  //   }
  //   final List<Response> responses = <Response>[];
  //   for (Request request in request.requests!) {
  //     if (request.cancelBuild != null) {
  //       responses.add(Response(cancelBuild: await cancelBuild(request.cancelBuild)));
  //     } else if (request.getBuild != null) {
  //       responses.add(Response(getBuild: await getBuild(request.getBuild)));
  //     } else if (request.scheduleBuild != null) {
  //       responses.add(Response(scheduleBuild: await scheduleBuild(request.scheduleBuild)));
  //     } else if (request.searchBuilds != null) {
  //       responses.add(Response(searchBuilds: await searchBuilds(request.searchBuilds)));
  //     }
  //   }
  //   return bbv2.BatchResponse(responses: responses);
  // }

  // @override
  // Future<bbv2.Build> cancelBuild(
  //   bbv2.CancelBuildRequest? request, {
  //   String buildBucketUri = 'https://localhost/builds',
  // }) async =>
  //     (cancelBuildResponse != null)
  //         ? await cancelBuildResponse!
  //         : bbv2.Build(
  //             id: request!.id,
  //             builderId: const BuilderId(
  //               bucket: 'try',
  //               project: 'flutter',
  //               builder: 'builder_abc',
  //             ),
  //             summaryMarkdown: request.summaryMarkdown,
  //           );

  // @override
  // Future<bbv2.Build> getBuild(
  //   bbv2.GetBuildRequest? request, {
  //   String buildBucketUri = 'https://localhost/builds',
  // }) async =>
  //     (getBuildResponse != null)
  //         ? await getBuildResponse!
  //         : bbv2.Build(
  //             id: request!.id!,
  //             builderId: request.builderId!,
  //             number: request.buildNumber,
  //           );

  // @override
  // Future<bbv2.ListBuildersResponse> listBuilders(
  //   bbv2.ListBuildersRequest? request, {
  //   String buildBucketUri = 'https://localhost/builders',
  // }) async =>
  //     (listBuildersResponse != null)
  //         ? await listBuildersResponse!
  //         : const bbv2.ListBuildersResponse(
  //             builders: <BuilderItem>[
  //               BuilderItem(
  //                 id: BuilderId(
  //                   bucket: 'prod',
  //                   project: 'flutter',
  //                   builder: 'Linux_android A',
  //                 ),
  //               ),
  //               BuilderItem(
  //                 id: BuilderId(
  //                   bucket: 'prod',
  //                   project: 'flutter',
  //                   builder: 'Linux_android B',
  //                 ),
  //               ),
  //             ],
  //           );
}
