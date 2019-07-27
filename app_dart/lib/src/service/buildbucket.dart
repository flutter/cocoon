// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../model/luci/buildbucket.dart';
import '../request_handling/api_response.dart';

/// A client interface to LUCI BuildBucket
@immutable
class BuildBucketClient {
  BuildBucketClient({
    this.buildBucketUri =
        'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds',
    HttpClient httpClient,
  }) : httpClient = httpClient ?? HttpClient();

  final String buildBucketUri;
  final HttpClient httpClient;

  Future<T> _postRequest<S extends ApiResponse, T>(
    String path,
    S request,
    T responseFromJson(Map<String, dynamic> rawResponse),
  ) async {
    final HttpClient client = httpClient;
    final Uri url = Uri.parse('$buildBucketUri$path');
    final HttpClientRequest httpRequest = await client.postUrl(url);
    httpRequest.headers.contentType = ContentType.json;

    httpRequest.write(json.encode(request.toJson()));
    await httpRequest.flush();
    final HttpClientResponse response = await httpRequest.close();

    final String rawResponse = await utf8.decodeStream(response);
    return responseFromJson(json.decode(rawResponse));
  }

  Future<Build> scheduleBuild(ScheduleBuildRequest request) {
    return _postRequest<ScheduleBuildRequest, Build>(
      '/ScheduleBuild',
      request,
      Build.fromJson,
    );
  }

  Future<SearchBuildsResponse> searchBuilds(SearchBuildsRequest request) {
    return _postRequest<SearchBuildsRequest, SearchBuildsResponse>(
      '/SearchBuilds',
      request,
      SearchBuildsResponse.fromJson,
    );
  }

  Future<BatchResponse> batch(BatchRequest request) {
    return _postRequest<BatchRequest, BatchResponse>(
      '/Batch',
      request,
      BatchResponse.fromJson,
    );
  }

  Future<Build> cancelBuild(CancelBuildRequest request) {
    return _postRequest<CancelBuildRequest, Build>(
      '/CancelBuild',
      request,
      Build.fromJson,
    );
  }

  Future<Build> getBuild(GetBuildRequest request) {
    return _postRequest<GetBuildRequest, Build>(
      '/GetBuild',
      request,
      Build.fromJson,
    );
  }
}
