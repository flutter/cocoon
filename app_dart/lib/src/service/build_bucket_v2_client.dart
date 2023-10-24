// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'access_token_provider.dart';

import '../service/logging.dart';

/// A client interface to LUCI BuildBucket
@immutable
class BuildBucketV2Client {
  /// Creates a new build bucket Client.
  ///
  /// The [buildBucketUri] parameter must not be null, and will be defaulted to
  /// [kDefaultBuildBucketUri] if not specified.
  ///
  /// The [httpClient] parameter will be defaulted to `HttpClient()` if not
  /// specified or null.
  BuildBucketV2Client({
    this.buildBucketBuilderUri = kDefaultBuildBucketBuilderUri,
    this.buildBucketBuildUri = kDefaultBuildBucketBuildUri,
    this.accessTokenService,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// Garbage to prevent browser/JSON parsing exploits.
  static const String kRpcResponseGarbage = ")]}'";

  /// The default endpoint for BuildBucket build requests.
  static const String kDefaultBuildBucketBuildUri = 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds';

  /// The default endpoint for BuildBucket builder requests.
  static const String kDefaultBuildBucketBuilderUri = 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builders';

  /// The base URI for build bucket requests.
  ///
  /// Defaults to [kDefaultBuildBucketBuildUri].
  final String buildBucketBuildUri;

  /// The base URI for build bucket requests.
  ///
  /// Defaults to [kDefaultBuildBucketBuilderUri].
  final String buildBucketBuilderUri;

  /// The token provider for OAuth2 requests.
  ///
  /// If this is non-null, an access token will be attached to any outbound
  /// HTTP requests issued by this client.
  final AccessTokenService? accessTokenService;

  /// The [http.Client] to use for requests.
  final http.Client httpClient;

  Future<T> _postRequest<S, T, R>(
    String path,
    S request,
    T Function(R rawResponse) responseFromJson, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) async {
    final Uri url = Uri.parse('$buildBucketUri$path');
    final AccessToken? token = await accessTokenService?.createAccessToken();

    log.fine('Making request with path: $url and body: ${json.encode(request)}');

    final http.Response response = await httpClient.post(
      url,
      body: json.encode(request),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
        if (token != null) HttpHeaders.authorizationHeader: '${token.type} ${token.data}',
      },
    );

    if (response.statusCode < 300) {
      return responseFromJson(
        json.decode(response.body.substring(kRpcResponseGarbage.length)) as R,
      );
    }
    throw BuildBucketException(response.statusCode, response.body);
  }

  /// The RPC request to schedule a build.
  Future<bbv2.Build> scheduleBuild(
    bbv2.ScheduleBuildRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) {
    return _postRequest<bbv2.ScheduleBuildRequest, bbv2.Build, String>(
      '/ScheduleBuild',
      request,
      bbv2.Build.fromJson,
      buildBucketUri: buildBucketUri,
    );
  }

  /// The RPC request to search for builds.
  Future<bbv2.SearchBuildsResponse> searchBuilds(
    bbv2.SearchBuildsRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) {
    return _postRequest<bbv2.SearchBuildsRequest, bbv2.SearchBuildsResponse, String>(
      '/SearchBuilds',
      request,
      bbv2.SearchBuildsResponse.fromJson,
      buildBucketUri: buildBucketUri,
    );
  }

  /// The RPC method to batch multiple RPC methods in a single HTTP request.
  ///
  /// The response is guaranteed to contain line-item responses for all
  /// line-item requests that were issued in [request]. If only a subset of
  /// responses were retrieved, a [BatchRequestException] will be thrown.
  Future<bbv2.BatchResponse> batch(
    bbv2.BatchRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) async {
    final bbv2.BatchResponse response = await _postRequest<bbv2.BatchRequest, bbv2.BatchResponse, String>(
      '/Batch',
      request,
      bbv2.BatchResponse.fromJson,
      buildBucketUri: buildBucketUri,
    );
    if (response.responses.length != request.requests.length) {
      throw BatchRequestException('Failed to execute all requests');
    }
    return response;
  }

  /// The RPC request to cancel a build.
  Future<bbv2.Build> cancelBuild(
    bbv2.CancelBuildRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) {
    return _postRequest<bbv2.CancelBuildRequest, bbv2.Build, String>(
      '/CancelBuild',
      request,
      bbv2.Build.fromJson,
      buildBucketUri: buildBucketUri,
    );
  }

  /// The RPC request to get details about a build.
  Future<bbv2.Build> getBuild(
    bbv2.GetBuildRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) {
    return _postRequest<bbv2.GetBuildRequest, bbv2.Build, String>(
      '/GetBuild',
      request,
      bbv2.Build.fromJson,
      buildBucketUri: buildBucketUri,
    );
  }

  /// The RPC request to get a list of builders.
  Future<bbv2.ListBuildersResponse> listBuilders(
    bbv2.ListBuildersRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuilderUri,
  }) {
    return _postRequest<bbv2.ListBuildersRequest, bbv2.ListBuildersResponse, String>(
      '/ListBuilders',
      request,
      bbv2.ListBuildersResponse.fromJson,
      buildBucketUri: buildBucketUri,
    );
  }

  /// Closes the underlying [HttpClient].
  ///
  /// If `force` is true, it will close immediately and cause outstanding
  /// requests to end with an error. Otherwise, it will wait for outstanding
  /// requests to finish before closing.
  ///
  /// Once this call completes, additional RPC requests will throw an exception.
  void close() {
    httpClient.close();
  }
}

class BuildBucketException implements Exception {
  const BuildBucketException(this.statusCode, this.message);

  /// The HTTP status code of the error.
  final int statusCode;

  /// The message from the server.
  final String message;

  @override
  String toString() => '$runtimeType: [$statusCode]: $message';
}

class BatchRequestException implements Exception {
  BatchRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
